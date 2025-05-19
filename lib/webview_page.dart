import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;
  bool _isDownloading = false;
  int? _sdkInt;

  // 定义与安卓交互的MethodChannel
  static const MethodChannel _channel =
      MethodChannel('flutter/save_to_gallery');

  @override
  void initState() {
    super.initState();
    _initSdkVersionAndPermissions();
  }

  Future<void> _initSdkVersionAndPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _sdkInt = androidInfo.version.sdkInt;
      print("Android SDK Version: $_sdkInt");

      await _requestStoragePermission();
    }
  }

  Future<void> _requestStoragePermission() async {
    if (_sdkInt == null) return;

    if (_sdkInt! >= 33) {
      // Android 13+ 请求 photos 权限
      await Permission.photos.request();
    } else {
      // 低版本请求 storage 权限
      await Permission.storage.request();
    }
  }

  // 调用安卓原生保存图片到图库
  Future<bool> _saveImageToGallery(String filePath) async {
    try {
      final bool result =
          await _channel.invokeMethod('saveImageToGallery', {'path': filePath});
      return result;
    } catch (e) {
      print('调用保存图片到图库失败：$e');
      return false;
    }
  }

  Future<void> _downloadFile(String url) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      PermissionStatus status;
      if (_sdkInt != null && _sdkInt! >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请允许存储权限以下载文件')),
        );
        setState(() => _isDownloading = false);
        return;
      }

      final dir = await getExternalStorageDirectory();
      final filename = url.split('/').last.split('?').first;
      final savePath = '${dir!.path}/$filename';

      final dio = Dio();
      await dio.download(url, savePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print('下载进度: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      });

      // 下载完成后调用原生方法保存到图库
      final saved = await _saveImageToGallery(savePath);
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载完成，图片已保存到相册')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载完成，但保存到相册失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败：$e')),
      );
    }

    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(title: Text('')),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
              useWideViewPort: true,
              loadWithOverviewMode: true,
              textZoom: 100,
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
                _downloadFile(url);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onDownloadStartRequest: (controller, request) async {
              final url = request.url.toString();
              print("开始下载: $url");
              _downloadFile(url);
            },
          ),
          if (_isDownloading)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 12),
                      Text('下载中...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
