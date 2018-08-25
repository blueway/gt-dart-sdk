import "package:geesdk/geesdk.dart";
import 'dart:io';
import 'dart:async';
import 'dart:convert';

Future main() async {
    var pcGeetest = Geetest(
            'b46d1900d0a894591916ea94ea91bd2c',
            '36fc3fe98530eea08dfc6ce76e3d24c4'
            );
    await pcGeetest.register((err,data){
        print(data);
    });

    var ret = getMd5("test");
    var ret2 = randint(1,20);
    print('md5:$ret, radnint:$ret2');
}
