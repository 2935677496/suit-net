import 'package:flutter/material.dart';
import 'package:suit_net/file_io.dart';
import 'cas_login.dart';
import 'net_login.dart';
import 'functions.dart';
import 'dart:io';
// Define the authentication states
enum AuthStatus { failed, disconnected, connecting, connected }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthStatus _currentState = AuthStatus.failed;
  final deviceName = Platform.isAndroid ? 'chenc' : 'chenAnd';//决定下线的设备
  Future<void> _checkStatus() async {
    final status = await captiveCheck('int');
    setState(() {
      switch (status) {
        case 0:
          _currentState = AuthStatus.disconnected;
          break;
        case 1:
          _currentState = AuthStatus.connected;
          break;
        case 2:
          _currentState = AuthStatus.failed;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkStatus(); //初始化时检测网络
  }

  // Method to simulate state changes
  void _toggleAuthStatus() {
    setState(() {
      switch (_currentState) {
        case AuthStatus.disconnected:
          _currentState = AuthStatus.connecting;
          break;
        case AuthStatus.connecting:
          _currentState = AuthStatus.connected;
          break;
        case AuthStatus.connected:
          _currentState = AuthStatus.disconnected;
          break;
        case AuthStatus.failed:
          _currentState = AuthStatus.disconnected;
          break;
      }
    });
  }

  void _changeStatus() async {
    while (true) {
      switch (_currentState) {
        case AuthStatus.disconnected:
        _toggleAuthStatus();//转换状态为connecting
        if (! await checkJsonKey()) {

        await selfLogin();
        final bool result = await kickOut(deviceName);//根据设备变化
        if (result) {
          print('kick success');
          final bool netResult = await netLogin();
          if (netResult) {
            print('Login success');
            setState(() {
              _currentState = AuthStatus.connected;
            });
          } else {
            _checkStatus();
          }
        } 
        } else {
          print('Password not found in config');
          _showMyDialog('Error', '密码缺失, 请先获取配置再试', 'getconfig');
          setState(() {
              _currentState = AuthStatus.disconnected;
            });
        }
          break;

        case AuthStatus.connected:
          //First判断是不是校园网，获取sessionId，下线
          //http.casLogin('self');
          break;
        case AuthStatus.failed:
          setState(() {
            _currentState = AuthStatus.connecting;
          });
          _checkStatus(); //处理重试事件
          continue;
        default:
      }
      break; //To prevent bad loop
    }
  }
///Function 1 : 'getconfig', 2 : 'logout'
  Future<void> _showMyDialog(String title, String text1, String doWhat) async {
    return showDialog<void>(
      context: context,
      // 设置为 false 可以禁止点击弹窗外区域关闭，防止用户误操作[citation:4]
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text1),
                //Text('你可以在这里写很多内容，它会自动滚动。'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                // 点击后关闭弹窗并返回 'Cancel'
                Navigator.of(context).pop('Cancel');
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                // 点击后关闭弹窗并返回 'OK'
                Navigator.of(context).pop('OK');
               //function here
               switch (doWhat) {
                case 'getconfig':
                break;
                case 'logout':
                break;
               }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define properties based on the current state
    
    String statusText;
    IconData icon;
    Color stateColor;
    String buttonText;

    switch (_currentState) {
      case AuthStatus.failed:
        statusText = "无法连接服务器";
        icon = Icons.error;
        buttonText = "重试";
        stateColor = Color(0xFFFF1744);
        break;
      case AuthStatus.disconnected:
        statusText = "欢迎使用校园网";
        stateColor = Color(0xFFFF1744);
        icon = Icons.wifi;
        buttonText = "点击连接";

        break;
      case AuthStatus.connecting:
        statusText = "Connecting...";
        stateColor = Color(0xFF448AFF);
        buttonText = "请稍后";
        icon = Icons.sync;

        break;
      case AuthStatus.connected:
        statusText = "已连接";
        stateColor = Color(0xFF00E676);
        icon = Icons.verified_user;
        buttonText = "点击下线";

        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('校园网认证'),
        backgroundColor: Colors.white, // Keep app bar light
        // 右侧按钮放在 actions 里
          actions: [
            // 下拉菜单按钮
            PopupMenuButton<String>(
              // 菜单图标（默认三个点）
              icon: const Icon(Icons.more_vert),
              
              // 点击菜单项回调
              onSelected: (String value) {
                // 根据 value 处理点击事件
                switch (value) {
                  case 'getconfig':
                    print('点击了设置');
                    break;
                  default:
                }
              },
            // 定义下拉菜单项
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'getconfig', // 唯一标识
                  child: Text('获取配置文件'),
                ),
                
                
              ],
            ),
          ],
      ),
      backgroundColor: Colors.grey[50], // Light background for the body
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: stateColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: stateColor,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _currentState == AuthStatus.connecting ? null : _changeStatus,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.50),
                      blurRadius: 24,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.power_settings_new,
                      size: 78,
                      color: Colors.white,
                    ),
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
