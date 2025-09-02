import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// 根據執行平台自動設定 API base URL
String getBaseUrl() {
  if (kIsWeb) {
    // Web 必須用區網 IP
    return 'http://${_getLocalIp()}:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android 模擬器
    return 'http://10.0.2.2:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS 模擬器 vs 真機要區分
    // 這裡先給 localhost，如果發現真機跑不通就改成 _getLocalIp()
    return 'http://localhost:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return 'http://localhost:5000';
  }

  // 預設 → 實體裝置走區網
  return 'http://${_getLocalIp()}:5000';
}

/// ✅ 設定你的本機 IP（⚠️ 改成你自己的）
/// 用來讓 Web 和實體手機可以連線到電腦上的 Flask
String _getLocalIp() {
  return '163.22.32.24'; // ← 這就是你剛剛給的 IP
}
