import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 等待 1 秒钟，确保 splash 页面展示够久
  await Future.delayed(Duration(seconds: 1));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String url = 'https://h5.fss88.net';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(url: url), // 启动页，跳转到 WebViewPage
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String url;

  SplashScreen({required this.url});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWebView();
  }

  // 启动页展示一秒后跳转到 WebView 页面
  _navigateToWebView() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebViewPage(url: widget.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash.png'), // 替换为你的图片路径
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile; rv:79.0) Gecko/79.0 Firefox/79.0')
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), // 设置高度为 0，隐藏 app bar
        child: AppBar(
          title: Text(''),
          centerTitle: true,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
