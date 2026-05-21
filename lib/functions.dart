import 'dart:io';
import 'dart:convert';
import 'reg_exp.dart';

// 退出 APP
// SystemNavigator.pop();


Future<dynamic> captiveCheck(String type) async {
 try {
  int status;
  String redirUrl;
// 1. 建立纯 TCP 连接
  final socket = await Socket.connect('captive.apple.com', 80);
  // 2. 手动发送最简陋的 HTTP 请求
  socket.write('GET / HTTP/1.1\r\nHost: captive.apple.com\r\nConnection: close\r\n\r\n');
  await socket.flush();
  // 3. 盲读所有返回的字节，完全不管它 HTTP 规不规范
  final String socketResult = await utf8.decoder.bind(socket).join();
  socket.close();

if (socketResult.length > 600) {
  //校园网且未认证
      redirUrl = matchBetween(socketResult, 'href=\'', '\'</script>');
      status = 0;
      return switch (type) {'String' => redirUrl, 'int' => status, _ => ''};
} else {
  
  return 1;
}
 } catch (e) {
  //throw Exception(e.toString());
  print(e.toString());
  return 2;
 }
  
}
