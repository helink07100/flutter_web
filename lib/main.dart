import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'webview_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();

  final selectedUrl = await getAvailableDomain();
  runApp(MyApp(url: selectedUrl));
}

Future<String> getAvailableDomain() async {
  const fallbackUrl = 'https://www.fss88.net';
  const configUrl =
      'https://phptestct.s3.ap-southeast-1.amazonaws.com/url/url.json';

  try {
    final res = await http
        .get(Uri.parse(configUrl))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List<dynamic> domains = data['url'];

      // 并发检测所有域名
      final futures =
          domains.map((domain) async {
            final fullUrl = 'https://$domain';
            try {
              final response = await http
                  .get(Uri.parse(fullUrl))
                  .timeout(const Duration(seconds: 3));
              if (response.statusCode == 200) {
                print('✅ 可用域名：$fullUrl');
                return fullUrl;
              }
            } catch (e) {
              print('❌ 不可用：$fullUrl');
            }
            return null;
          }).toList();

      // 等待所有检测结果，返回第一个非 null 的
      final results = await Future.wait(futures);
      final firstValid = results.firstWhere(
        (url) => url != null,
        orElse: () => fallbackUrl,
      );
      return firstValid!;
    }
  } catch (e) {
    print("加载域名配置失败: $e");
  }

  return fallbackUrl;
}

class MyApp extends StatelessWidget {
  final String url;
  const MyApp({super.key, required this.url});

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
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebViewPage(url: widget.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash.png'),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
