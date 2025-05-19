package com.example.flutter_web;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "flutter/save_to_gallery";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("saveImageToGallery")) {
                                String path = call.argument("path");
                                if (path == null) {
                                    result.error("NO_PATH", "Path is null", null);
                                    return;
                                }
                                boolean saved = saveImageToGallery(this, path);
                                if (saved) {
                                    result.success(true);
                                } else {
                                    result.success(false);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private boolean saveImageToGallery(Context context, String filePath) {
        try {
            File file = new File(filePath);
            if (!file.exists()) {
                Log.e("SaveImage", "文件不存在: " + filePath);
                return false;
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { // Android 10+
                ContentValues values = new ContentValues();
                values.put(MediaStore.Images.Media.DISPLAY_NAME, file.getName());
                values.put(MediaStore.Images.Media.MIME_TYPE, getMimeType(file.getName()));
                values.put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/MyApp");
                values.put(MediaStore.Images.Media.IS_PENDING, 1);

                Uri uri = context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
                if (uri == null) {
                    Log.e("SaveImage", "无法创建 MediaStore 记录");
                    return false;
                }

                try (OutputStream out = context.getContentResolver().openOutputStream(uri);
                     FileInputStream inputStream = new FileInputStream(file)) {
                    byte[] buffer = new byte[4096];
                    int bytesRead;
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        out.write(buffer, 0, bytesRead);
                    }
                }

                values.clear();
                values.put(MediaStore.Images.Media.IS_PENDING, 0);
                context.getContentResolver().update(uri, values, null, null);

                return true;
            } else {
                // Android 10 以下版本，直接复制文件到公共目录
                File picturesDir = context.getExternalFilesDir("Pictures");
                if (picturesDir == null) {
                    Log.e("SaveImage", "无法获取 Pictures 目录");
                    return false;
                }
                File destFile = new File(picturesDir, file.getName());
                // 复制文件
                try (FileInputStream inputStream = new FileInputStream(file);
                     OutputStream out = new java.io.FileOutputStream(destFile)) {
                    byte[] buffer = new byte[4096];
                    int bytesRead;
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        out.write(buffer, 0, bytesRead);
                    }
                }

                // 通知媒体库扫描更新
                Intent intent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                intent.setData(Uri.fromFile(destFile));
                context.sendBroadcast(intent);

                return true;
            }
        } catch (Exception e) {
            Log.e("SaveImage", "保存图片失败: ", e);
            return false;
        }
    }

    private String getMimeType(String filename) {
        String lower = filename.toLowerCase();
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return "image/jpeg";
        } else if (lower.endsWith(".png")) {
            return "image/png";
        } else if (lower.endsWith(".gif")) {
            return "image/gif";
        }
        return "image/*";
    }
}
