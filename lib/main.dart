import 'package:flutter/material.dart';
import 'package:suit_net/home.dart';
import 'package:path_provider/path_provider.dart';

class AppConfig {
  static String cookiePath = '';
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // 启动时一次性获取好
  final dir1 = await getApplicationSupportDirectory();
  AppConfig.cookiePath = "${dir1.path}/cookies";
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '校园网认证',
      theme: ThemeData(
        // General theme for a clean desktop app
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0),
        ),
        // Custom button style for the main theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.grey[50], // Light app bar background
          foregroundColor: Colors.grey[800], // Dark text on app bar
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      home: HomePage(),
    );
    
  }
}







/* --------- */
class Sandbox extends StatefulWidget {
  const Sandbox({super.key});

  @override
  State<Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<Sandbox> {
  int count = 0;
  void increase() {
    setState(() {
      count++;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(color: Colors.red[200],width: 200,child: 
            Text('$count')
          ),
          Container(color: Colors.red[200],width: 200,child: 
            TextButton(onPressed: increase, child: Text('+'))
          ),
        ],
       ),
      ),
    );
  }
}

