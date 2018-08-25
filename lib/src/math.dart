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
    const NEW_CAPTCHA =  true;
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
    
    Future validate(bool fallback ,result, callback) async{
        var challenge = result["challenge"]?? result['geetest_challenge'];
        var validate = result["validate"]?? result['geetest_validate'];
        var seccode = result["seccode"]?? result['geetest_seccode'];
        if (fallback) {
            if (getMd5(challenge) == validate) {
                callback(null, true);
            } else {
                callback(null, false);
            }
      
        } else {

            var hash = this.geetest_key + 'geetest' + challenge;
            if (validate == getMd5(hash)) {
                var url = this.PROTOCOL + this.API_SERVER + this.VALIDATE_PATH;
                http.post(url, body:{
                    'gt': this.geetest_id,
                    'seccode': seccode 
                }).then((res) {
                    callback(null, res.body == getMd5(seccode));
                });
            } else {
                callback(null, false);
            }
        }
    }

    Future register (callback) async {
        final version = '0.1.1';
        final url = this.PROTOCOL + this.API_SERVER + this.REGISTER_PATH
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
                        'gt': that.geetest_id,
                        'new_captcha': that.NEW_CAPTCHA
                    });
                } else 
                    callback(null, {
                        'success': 1,
                        'challenge': getMd5(challenge + that.geetest_key),
                        'gt': that.geetest_id,
                        'new_captcha': that.NEW_CAPTCHA
                    });
            });       
    }

}
