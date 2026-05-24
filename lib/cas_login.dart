import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'aes_crypto.dart';
import 'file_io.dart';
import 'reg_exp.dart';
import 'dart:io';

String dir4Every() {
  String? username = Platform.environment['USERNAME'];
  final String winDir = username != null ? 'C:\\Users\\$username\\AppData\\Roaming\\suit\\cookie' : 'cookie';
  return Platform.isAndroid ? '/data/user/0/com.example.suie_net/files/cookie' : winDir;
}

class CasSession {
  CasSession({
    required this.baseUrl,
    required this.cookiePath,
    Duration connectTimeout = const Duration(seconds: 5),
    Map<String, dynamic>? baseHeaders,
  })  : _defaultHeaders = {
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language':
              'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Priority': 'u=0, i',
          'User-Agent': 'Mozilla/5.0',
          ...?baseHeaders,
        },
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
          ),
        ),
        _cookieJar = PersistCookieJar(
          ignoreExpires: true,
          storage: FileStorage(cookiePath),
        ) {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  final String baseUrl;
  final String cookiePath;
  final Dio _dio;
  final PersistCookieJar _cookieJar;
  final Map<String, dynamic> _defaultHeaders;
  

  Options _buildOptions(
    String method, {
    Map<String, dynamic>? headers,
  }) {
    return Options(
      method: method,
      headers: {
        ..._defaultHeaders,
        ...?headers,
      },
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? headers,
  }) {
    return _dio.get(
      path,
      options: _buildOptions('GET', headers: headers),
    );
  }

  Future<Response<dynamic>> getUri(
    Uri uri, {
    Map<String, dynamic>? headers,
  }) {
    return _dio.getUri(
      uri,
      options: _buildOptions('GET', headers: headers),
    );
  }

  Future<Response<dynamic>> postUri(
    Uri uri, {
    Object? data,
    Map<String, dynamic>? headers,
  }) {
    return _dio.postUri(
      uri,
      data: data,
      options: _buildOptions('POST', headers: headers),
    );
  }

  Future<Response<dynamic>> followRedirects(
    Response<dynamic> response, {
    Map<String, dynamic>? headers,
    int maxRedirects = 10,
  }) async {
    var currentResponse = response;
    var redirectCount = 0;

    while (_isRedirect(currentResponse) && redirectCount < maxRedirects) {
      final location = currentResponse.headers.value('location');
      if (location == null || location.isEmpty) {
        break;
      }

      final nextUri = currentResponse.requestOptions.uri.resolve(location);
      print('Redirecting to: $nextUri');

      currentResponse = await _dio.getUri(
        nextUri,
        options: _buildOptions('GET', headers: headers),
      );
      redirectCount++;
    }

    if (_isRedirect(currentResponse) && redirectCount >= maxRedirects) {
      throw Exception('Too many redirects: $maxRedirects');
    }

    return currentResponse;
  }

  Future<Response<dynamic>> getFollowingRedirects(
    String path, {
    Map<String, dynamic>? headers,
    int maxRedirects = 10,
  }) async {
    final response = await get(path, headers: headers);
    return followRedirects(
      response,
      headers: headers,
      maxRedirects: maxRedirects,
    );
  }

  Future<void> clearCookies() {
    return _cookieJar.deleteAll();
  }

  Future<List<Cookie>> loadCookies(String path) {
    return _cookieJar.loadForRequest(Uri.parse(baseUrl).resolve(path));
  }

  bool _isRedirect(Response<dynamic> response) {
    final statusCode = response.statusCode;
    return (statusCode == 301 || statusCode == 302) &&
        response.headers.value('location') != null;
  }
}
String onceCookie = '';

Future<bool> selfLogin() async {
  final cookieDir = await getCookiePath();
  final session = CasSession(baseUrl: 'http://10.10.16.58/', cookiePath: cookieDir);
  await session.clearCookies();

  try {
    final response = await session.getFollowingRedirects('/self/index');

    print('redirect最终状态码: ${response.statusCode}');
    final finalUri = response.requestOptions.uri;
    final String casResponse = response.data.toString();

    if (casResponse.isEmpty) {
      print('CAS response is empty');
      return false;
    }

    final String execution = matchBetween(
      casResponse,
      r'id="login-page-flowkey">',
      r'</p>',
    );
    if (execution.isEmpty) throw Exception('Cannot get execution');

    final String croypto = matchBetween(
      casResponse,
      r'id="login-croypto">',
      r'</p>',
    );
    if (croypto.isEmpty) throw Exception('Cannot get croypto');
    final secret = await getPswd();
    final deSecret = xorDecrypt(secret);
    final password = loginEncrypt(deSecret, croypto);
    final bodyParams = <String, String>{
      'username': '2508210211',
      'type': 'UsernamePassword',
      '_eventId': 'submit',
      'execution': execution,
      'captcha_code': '',
      'croypto': croypto,
      'password': password,
    };

    print('\n begin login \n');
    final loginResponse = await session.postUri(
      finalUri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      data: bodyParams,
    );
    final result = await session.followRedirects(loginResponse);

    print('final login status code ${result.statusCode}');
    final cookies = await session.loadCookies('/self/index');
    print('cookies: ${cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')}');
    print('cookiesType: ${cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ').runtimeType}');
    onceCookie = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    print('once cookie: $onceCookie');
    return true;
  } catch (e) {
    print('登录异常：$e');

    return false;
  }
}
Future<bool> kickOut(String deviceName) async {
  final cookieDir = await getCookiePath();
  final session = CasSession(baseUrl: 'http://10.10.16.58/', cookiePath: cookieDir);
  try {
  Uri deviceUri = Uri.parse('http://10.10.16.58/sam/api/userself/devices');
  Uri kickDeviceUri = Uri.parse('http://10.10.16.58/sam/api/userself/devices/kick-offline/batch');
  Response deviceData = await session.postUri(
    deviceUri,
    headers: {
      'Content-Type': 'application/json',
      'encrypted': 'false',
      'clientType': 'self',
    },
    data: {},
    );
    print(deviceData.data);
    
    if (deviceData.statusCode != 200) {
      print('retrying get devices list');
      deviceData = await session.postUri(
    deviceUri,
    headers: {
      'Content-Type': 'application/json',
      'encrypted': 'false',
      'clientType': 'self',
      'cookie': onceCookie, //为防止cookie冲突手动处理cookie
    },
    data: {},
    );
    }

    List<dynamic> onlineDevices = deviceData.data['data']['onlineDevices'];
    int listLength =onlineDevices.length;
    String uuid = '';
    for (int i=0; i <= (listLength - 1); i++) {
      if (onlineDevices[i]['deviceName'] == deviceName) {
uuid = onlineDevices[i]['onlineUserUuid'];
break;
      }
    }
    if (uuid.isEmpty) {
      return true;
    } else {
final kickResult = await session.postUri(
  kickDeviceUri,
    headers: {
      'Content-Type': 'application/json',
      'encrypted': 'false',
      'clientType': 'self',
      'cookie': onceCookie, //为防止cookie冲突手动处理cookie
    },
    data: {'onlineUserUuids': [uuid]},
);
if (kickResult.statusCode == 200) print('Successfully kick $deviceName');
return kickResult.statusCode == 302 ? false : true;
    }
    
  } catch (e) {
    print(e);
    return false;
  }
}
String? findKeyByValue(String targetValue, Map<String, String> map) {
  for (var entry in map.entries) {
    if (entry.value == targetValue) {
      return entry.value;
    }
  }
  return null;
}