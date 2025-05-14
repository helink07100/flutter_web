import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'webview_page.dart'; // 单独分离出去，方便管理

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request(); // 请求权限（推荐）
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // final String url = 'http://10.0.2.2:9999'; // 你的 Web 地址
  final String url = 'https://h5.fss88.net';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(url: url),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String url;

  const SplashScreen({super.key, required this.url});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWebView();
  }

  _navigateToWebView() async {
    await Future.delayed(Duration(seconds: 5));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebViewPage(url: widget.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash.png'), // 启动画面图片
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
