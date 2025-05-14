import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.storage,
        Permission.photos,
        Permission.camera,
      ];

      final status = await permissions.request();

      // 检查是否有权限永久拒绝
      for (final perm in permissions) {
        if (await perm.isPermanentlyDenied) {
          // 引导用户去设置页面
          await openAppSettings();
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(title: Text('')),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useHybridComposition: true,
          useWideViewPort: true,
          loadWithOverviewMode: true,
          textZoom: 100, // 防止字体模糊
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        shouldOverrideUrlLoading: (controller, action) async {
          final url = action.request.url.toString();
          if (url.endsWith(".pdf") ||
              url.endsWith(".doc") ||
              url.endsWith(".apk") ||
              url.endsWith(".png") ||
              url.endsWith(".jpg") ||
              url.endsWith(".jpeg") ||
              url.endsWith(".zip")) {
            _launchExternal(url);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        onDownloadStartRequest: (controller, request) async {
          final url = request.url.toString();
          print("Start downloading: $url");

          // 使用外部浏览器下载（你也可以选择自定义下载）
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            print("Cannot launch download URL");
          }
        },
      ),
    );
  }

  void _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
