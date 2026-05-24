import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

Future<String> getCookiePath() async {
  Directory configDir = await getApplicationSupportDirectory();
  final path = '${configDir.path}/cookie';
  return path;
}


Future<bool> checkJsonKey() async {
  Directory configDir = await getApplicationSupportDirectory();
  final file = File('${configDir.path}/config.json');
  try {
    // 1. 读取文件内容（字符串）
    final jsonString = await file.readAsString();
    // 2. 反序列化：JSON字符串 → Dart Map/List
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final String? value = jsonData['password'];
    return value != null ? true : false;
  } catch (e) {
    print('读取/解析 JSON 失败: $e');
    return false;
  }
}
///Read as String
Future<String> readJson() async {
  Directory configDir = await getApplicationSupportDirectory();
  final file = File('${configDir.path}/config.json');
  try {
    // 1. 读取文件内容（字符串）
    final jsonString = await file.readAsString();
    return jsonString;
  } catch (e) {
    print('读取/解析 JSON 失败: $e');
    return 'Can not read: ${e.toString()}';
  }
}

Future<String> getSessionId() async {
  final jsonString = await readJson();
  try {
   
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return jsonData['sessionId'];
  } catch (e) {
    throw Exception('读取/解析 JSON 失败: $e');
    
  }
}
Future<String> getPswd() async {
  Directory configDir = await getApplicationSupportDirectory();
  final file = File('${configDir.path}/config.json');
  try {
    // 1. 读取文件内容（字符串）
    final jsonString = await file.readAsString();

    // 2. 反序列化：JSON字符串 → Dart Map/List
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return jsonData['password'];
  } catch (e) {
    print('读取/解析 JSON 失败: $e');
    throw Exception('Read pswd fail: $e');
    //return '';
  }
}

/// 将 Dart 对象写入 JSON 文件
Future<void> updateConfig(
  Map<String, dynamic> newData,
  List<String> updateList,
) async {
  Directory configDir = await getApplicationSupportDirectory();
  final file = File('${configDir.path}/config.json');
  final originalJson = await file.readAsString(); //原始数据字符串
  Map<String, dynamic> originalData = jsonDecode(originalJson); //原始（旧）配置
  try {
    //序列化：Dart 对象 → 格式化的 JSON 字符串（美观输出）
    final newJsonString = JsonEncoder.withIndent('  ').convert(newData);
    Map<String, dynamic> toWriteData = jsonDecode(newJsonString);
    for (int i = 0; i < updateList.length; i++) {
      originalData[updateList[i]] = toWriteData[updateList[i]]; //对原有数据进行修改
    }
    //序列化：Dart 对象 → 格式化的 JSON 字符串（美观输出）
    final jsonString = JsonEncoder.withIndent('  ').convert(originalData);
    //写入文件（覆盖原有内容）
    await file.writeAsString(jsonString);
    print('\n===== 写入 JSON 成功 =====');
  } catch (e) {
    print('写入 JSON 失败: $e');
  }
}
Future<void> saveSessionId(String sessionId) async {
  Directory configDir = await getApplicationSupportDirectory();
  final file = File('${configDir.path}/config.json');
  final originalJson = await file.readAsString(); //原始数据字符串
  Map<String, dynamic> originalData = jsonDecode(originalJson); //原始（旧）配置
  try {
  originalData['sessionId'] = sessionId;
  await updateConfig(originalData, ['sessionId']);

  } catch (e) {
    print('\nCan not save sessionId: $e');
  }
}
/// 纯Dart Dio下载（自动支持重定向）
Future<bool> downloadConfig() async {
  final dio = Dio();
  Directory configDir = await getApplicationSupportDirectory();
  final filePath = '${configDir.path}/config.json';
  try {
    print("开始下载...");

    await dio.download(
      'https://gitee.com/qshee/config/releases/download/config/config.json',
      filePath,
      // 下载进度
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          print("下载进度：$progress%");
        }
      },
      // 开启重定向（默认就是true，可省略）
      options: Options(followRedirects: true, maxRedirects: 5),
    );

    print("✅ 下载完成");
    return true;
  } catch (e) {
    print("❌ 下载失败：$e");
    return false;
  }
}
