import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb

/// ✅ 根據執行平台自動設定 API base URL
String getBaseUrl() {
  // 👉 Web 平台：需使用實際電腦 IP
  if (kIsWeb) {
    return 'http://${_getLocalIp()}:5000';
  }

  // 👉 Android 模擬器（使用特殊 IP 取代 localhost）
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5000';
  }

  // 👉 iOS 模擬器 / macOS / Windows / Linux：可用 localhost
  if (Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux) {
    return 'http://localhost:5000';
  }

  // 👉 實體手機（非模擬器）：需使用實際 IP
  return 'http://${_getLocalIp()}:5000';
}

/// ✅ 設定你的本機 IP（⚠️ 改成你自己的）
/// 用來讓 Web 和實體手機可以連線到電腦上的 Flask
String _getLocalIp() {
  return '192.168.137.4'; // ← 這就是你剛剛給的 IP
}
