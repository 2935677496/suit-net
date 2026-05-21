import 'reg_exp.dart';
import 'aes_crypto.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'file_io.dart';
import 'dart:convert';


Future<bool> netLogin() async {
  Map<String, dynamic> headers = {
      
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Priority': 'u=4',
    };
  final dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 8),
      headers: {
        "User-Agent": "Mozilla/5.0",
      },
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
      
      )
  );
  
  try {
  Response response;
  // 1. 建立纯 TCP 连接
  final socket = await Socket.connect('captive.apple.com', 80);
  
  // 2. 手动发送最简陋的 HTTP 请求
  socket.write('GET / HTTP/1.1\r\nHost: captive.apple.com\r\nConnection: close\r\n\r\n');
  await socket.flush();

  // 3. 盲读所有返回的字节，完全不管它 HTTP 规不规范
  final String socketResult = await utf8.decoder.bind(socket).join();
  
  
  socket.close();
  // Uri appleUri = Uri.parse('http://captive.apple.com/');
  // response = await dio.getUri(appleUri);
    if (socketResult.contains('location.href')) {
      
      String redirUrl = matchBetween(socketResult, 'href=\'', '\'</script>');
      response = await dio.get(redirUrl);
      final String portalUrl = response.headers.value('location') ?? '';
      String jSessionId = response.headers.value('set-cookie') ?? '';
      jSessionId = matchBetween(jSessionId, 'JSESSIONID=', r';');
      print('redirect url: $portalUrl');
      print('JSESSIONID=$jSessionId');
      final String sessionId = matchBetween(portalUrl, 'sessionId=', '&');
      Uri uri = Uri.parse(portalUrl);
      Map<String, String> params = uri.queryParameters;
      String queryParams = 'userIp=${params['userIp']}&userMac=${params['userMac']}&nasIp=${params['nasIp']}&customPageId=${params['customPageId']}';
      String loginUrl = 'http://10.10.16.58/cas-sso/login?flowSessionId=$sessionId&$queryParams';
      response = await dio.get(loginUrl);
      String session = response.headers.value('set-cookie') ?? '';
      session = matchBetween(session, 'SESSION=', r';');
      final String casResponse = response.data.toString();
      if (casResponse.isEmpty) {
        print('CAS response is empty');
        return false;
      } else {
        final String execution = matchBetween(
          casResponse,
          r'id="login-page-flowkey">',
          r'</p>',
        );
        if (execution.isEmpty) throw Exception('Cannot get execution');
        // 3.获取login-croypto（加密密钥）
        final String croypto = matchBetween(
          casResponse,
          r'id="login-croypto">',
          r'</p>',
        );
        if (croypto.isEmpty) throw Exception('Cannot get croypto');
        final secret = await getPswd();
    final deSecret = xorDecrypt(secret);
    final password = loginEncrypt(deSecret, croypto);
        Map<String, String> bodyParams = {
          'username': '2508210211',
          'type': 'UsernamePassword',
          '_eventId': 'submit',
          'execution': execution,
          'captcha_code': '',
          'croypto': croypto,
          'password': password,
        };
        //headers.addAll({'Content-Type': 'application/x-www-form-urlencoded'});
headers.addAll({'cookie': 'SESSION=$session'});//add cookie
        print('\n begin login \n');
        response = await dio.post(
          loginUrl,
          options: Options(
            headers: headers,
            contentType: Headers.formUrlEncodedContentType,
          ),
          data: bodyParams,
        );
    redirUrl = response.headers.value('location') ?? '';
    print('login redirUrl: $redirUrl');
    response = await dio.get(redirUrl);
    print(response.statusCode);
    response = await dio.post(
      'http://10.10.16.58/eportal/network/serviceLogin',
      options: Options(
        headers: {'cookie': 'JSESSIONID=$jSessionId'},
      ),
      data: {"sessionId": sessionId, "service":"电信宽带"},
    );
    print(response.data);
    //return response.data;
    return response.statusCode == 200 ? true : false;
      }//cas is not empty
    } else {
      print('can not redirect');
      return false;
    }
  } catch (e) {
    throw Exception(e.toString());
  }
}