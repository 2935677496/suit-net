import 'dart:io';
import 'dart:convert';

String winDir = '', androDir = '';
String? userHome = Platform.environment['USERPROFILE'];
Directory winAppDir = Directory('$userHome\\AppData\\Roaming\\suit');
File appJson = File('$userHome\\AppData\\Roaming\\suit\\config.json');

Future<String> checkSysType() async {
  final dir = Directory('C:\\Windows');
  bool exists = await dir.exists();
  if (exists) {
    return 'Windows';
  } else {
    return 'Android';
  }
}

Future<bool> checkFile() async {
  try {
    if (await appJson.exists()) {
      return true;
    } else {
      await appJson.create(recursive: true);
      await appJson.writeAsString(r'{}');
      return false;
    }
  } on FileSystemException catch (e) {
    throw Exception('文件检查失败: ${e.message}${e.path != null ? ' (路径: ${e.path})' : ''}');
  } catch (e) {
    throw Exception('文件检查失败: $e');
  }
}

Future<String> storeData(Map<String, dynamic> data) async {
  try {
    if (!await appJson.exists()) {
      await appJson.create(recursive: true);
      await appJson.writeAsString(r'{}');
    }

    final jsonString = await appJson.readAsString();
    final Map<String, dynamic> jsonMap = jsonString.trim().isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(jsonString));

    jsonMap.addAll(data);

    final updatedJson = const JsonEncoder.withIndent('  ').convert(jsonMap);
    await appJson.writeAsString(updatedJson);
    return updatedJson;
  } on FileSystemException catch (e) {
    throw Exception('写入配置文件失败: ${e.message}${e.path != null ? ' (路径: ${e.path})' : ''}');
  } on FormatException catch (e) {
    throw Exception('配置文件 JSON 格式错误: ${e.message}');
  } catch (e) {
    throw Exception('保存数据失败: $e');
  }
}

Future<String> readJson(String parameter) async {
  try {
    if (!await appJson.exists()) {
      throw Exception('配置文件不存在: ${appJson.path}');
    }

    final jsonString = await appJson.readAsString();
    final Map<String, dynamic> jsonMap = jsonString.trim().isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(jsonString));

    if (!jsonMap.containsKey(parameter)) {
      throw Exception('配置项不存在: $parameter');
    }

    final value = jsonMap[parameter];
    return value?.toString() ?? '';
  } on FileSystemException catch (e) {
    throw Exception('读取配置文件失败: ${e.message}${e.path != null ? ' (路径: ${e.path})' : ''}');
  } on FormatException catch (e) {
    throw Exception('配置文件 JSON 格式错误: ${e.message}');
  } catch (e) {
    throw Exception('读取配置项失败: $e');
  }
}
