import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest_sink.dart';
import 'package:http/http.dart' as http;


String getMd5(String inp){
    var bytes = utf8.encode(inp); 
    return md5.convert(bytes).toString();
}

int randint(int min, int max){
    final _random = Random();
    return min + _random.nextInt(max - min);
}

class Geetest{
    final Map<String,String> config;
    var PROTOCOL =  'http://';
    var API_SERVER =  'api.geetest.com';
    var VALIDATE_PATH =  '/validate.php';
    var REGISTER_PATH =  '/register.php';
    String geetest_id;
    String geetest_key;
    Geetest(this.geetest_id,this.geetest_key);
    String _make_challenge () {
        var rnd1 = randint(0, 90);
        var rnd2 = randint(0, 90);
        var md5_str1 = getMd5(rnd1.toString());
        var md5_str2 = getMd5(rnd2.toString());
        return md5_str1 + md5_str2.substring(0, 2);
    }
    int _decode_rand_base (String challenge) {
        var str_base = challenge.substring(32);
        var i, len, temp_array = [];
        for (var temp_ascii in str_base.runes){
            var result = temp_ascii > 57 ? temp_ascii - 87 : temp_ascii - 48;
            temp_array.add(result);
        }
        var decode_res = temp_array[0] * 36 + temp_array[1];
        return decode_res;
    }
    int _decode_response (challenge, userresponse) {
        if (userresponse.length > 100) {
            return 0;
        }
        var shuzi = [1, 2, 5, 10, 50];
        var chongfu = [];
        var key = {};
        var count = 0, i, len;
        for (var c in challenge){
            if (chongfu.indexOf(c) == -1) {
                chongfu.add(c);
                key[c] = shuzi[count % 5];
                count += 1;
            }
        }
        var res = 0;
        for (var u in userresponse) {
            res += key[u] ?? 0;
        }
        res = res - this._decode_rand_base(challenge);
        return res;
    }
    int _validate_fail_image (ans, full_bg_index, img_grp_index) {

        var thread = 3;
        var full_bg_name = getMd5(full_bg_index).substring(0, 10);
        var bg_name = getMd5(img_grp_index).substring(10, 20);
        var answer_decode = '';
        var i;
        for (i = 0; i < 9; i = i + 1) {
            if (i % 2 == 0) {
                answer_decode += full_bg_name[i];
            } else {
                answer_decode += bg_name[i];
            }
        }
        var x_decode = answer_decode.substring(4);
        var x_int = int.parse(x_decode);
        var result = x_int % 200;
        if (result < 40) {
            result = 40;
        }
        if ((ans - result).abs() < thread) {
            return 1;
        } else {
            return 0;
        }
    }

    Future validate(result, callback) async{
        var challenge = result["challenge"];
        var validate = result["validate"];
        if (validate.split('_').length == 3) {

            var validate_strs = validate.split('_');
            var encode_ans = validate_strs[0];
            var encode_fbii = validate_strs[1];
            var encode_igi = validate_strs[2];

            var decode_ans = this._decode_response(challenge, encode_ans);
            var decode_fbii = this._decode_response(challenge, encode_fbii);
            var decode_igi = this._decode_response(challenge, encode_igi);

            var validate_result = this._validate_fail_image(decode_ans, decode_fbii, decode_igi);

            if (validate_result == 1) {
                callback(null, true);
            } else {
                callback(null, false);
            }
        } else {

            var hash = this.geetest_key + 'geetest' + challenge;
            if (validate == getMd5(hash)) {
                var url = this.PROTOCOL + this.API_SERVER + this.VALIDATE_PATH;
                http.post(url, body:{
                    'seccode': result['seccode']
                }).then((res) {
                    callback(null, res.body == getMd5(result['seccode']));
                });
            } else {
                callback(null, false);
            }
        }
    }

    Future register (callback) async {
        var version = '0.1.1';
        var url = this.PROTOCOL + this.API_SERVER + this.REGISTER_PATH
            + '?gt=' + this.geetest_id + '&sdk=Dart_' + version;

        var that = this;
        http.get(url)
            .then((res) {
                var challenge = res.body;
                print(res.body);
                if(challenge.length != 32) {
                    callback(null, {
                        'success': 0,
                        'challenge': that._make_challenge(),
                        'gt': that.geetest_id
                    });
                } else 
                    callback(null, {
                        'success': 1,
                        'challenge': getMd5(challenge + that.geetest_key),
                        'gt': that.geetest_id
                    });
            });       
    }

}
