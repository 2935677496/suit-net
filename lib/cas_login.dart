import 'reg_exp.dart';
import 'aes_crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

void casLogin() async {
  Map<String, dynamic> headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language':
        'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Priority': 'u=0, i',
  };
  // 1. 创建 Dio 实例
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.10.16.58/',
      connectTimeout: const Duration(seconds: 5),
      headers: {"User-Agent": "Mozilla/5.0"},
      followRedirects: false,
      validateStatus: (status) => status! < 500,
    ),
  );

  // 2. ✅ 关键：添加 Cookie 管理器（自动存、自动带Cookie）
  final cookieJar = PersistCookieJar(
    ignoreExpires: true,
    storage: FileStorage('cookies'), //文件夹名称
  );
  dio.interceptors.add(CookieManager(cookieJar));

  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) async {
        final statusCode = response.statusCode;
        final location = response.headers.value('location');

        if ((statusCode == 301 || statusCode == 302) && location != null) {
          // Resolve the redirect URL (handles both relative and absolute paths)
          Uri nextUri = response.requestOptions.uri.resolve(location);

          print("Redirecting to: $nextUri");

          // Trigger a new request. CookieManager will now have the cookies
          // from the previous response because its onResponse ran first.
          try {
            final nextResponse = await dio.getUri(
              nextUri,
              options: Options(headers: headers),
            );
            return handler.resolve(nextResponse);
          } on DioException catch (e) {
            return handler.reject(e);
          }
        }
        return handler.next(response);
      },
    ),
  );

  try {
    // ✅ 自动：发送POST → 收到302 → 自动GET跳转Location → 自动带上Cookie
    final response = await dio.get(
      '/self/index',
      options: Options(headers: headers),
    );

    // 最终拿到的是跳转后的页面响应（200）
    print("redirect最终状态码: ${response.statusCode}");
    final finalUri = response.requestOptions.uri;
    final String casResponse = response.data.toString();
    if (casResponse.isEmpty) {
      
      throw Exception('CAS response is empty');
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
      final password = loginEncrypt(r'fuckU#6462', croypto);
      Map<String, String> bodyParams = {
        'username': '2508210211',
        'type': 'UsernamePassword',
        '_eventId': 'submit',
        'execution': execution,
        'captcha_code': '',
        'croypto': croypto,
        'password': password,
      };
      headers.addAll({'Content-Type': 'application/x-www-form-urlencoded'});

      print('\n begin login \n');
      final result = await dio.postUri(
        finalUri,
        options: Options(headers: headers),
        data: bodyParams,
      );
      print('final login status code ${result.statusCode}');
      print(response.requestOptions.headers);
      
    } //casResponse.isNotEmpty
  } catch (e) {
    throw Exception("登录异常：$e");
  }
}
