import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// ✅ 真手機(Android)是否走區網 IP
const bool kAndroidUseLan = true; // 真機測試 true；模擬器改 false

/// ✅ 你的電腦在同一個 Wi-Fi 的 IPv4
const String kPcIp = '10.104.35.230';

String getBaseUrl() {
  if (kIsWeb) {
    // Web 必須用區網 IP
    return 'http://$kPcIp:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android：真機用區網；模擬器用 10.0.2.2
    return kAndroidUseLan ? 'http://$kPcIp:5000' : 'http://10.0.2.2:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS 模擬器用 localhost；若是真機請改成區網 IP
    return 'http://localhost:5000';
  }

  if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return 'http://localhost:5000';
  }

  // 預設 → 區網
  return 'http://$kPcIp:5000';
}
