import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

const int kPort = 5000;

/// 你的 Windows IPv4（同一個 Wi-Fi/熱點）
const String kPcIp = '10.107.38.191'; //10.107.38.191

/// Android：真機測試用區網；模擬器改 false 走 10.0.2.2
const bool kAndroidUseLan = true;

/// iOS：真機測試用區網；只有 iOS 模擬器才用 localhost
const bool kiOSUseLan = true;

String _http(String host) => 'http://$host:$kPort';

String getBaseUrl() {
  if (kIsWeb) return _http(kPcIp);

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return kAndroidUseLan ? _http(kPcIp) : _http('10.0.2.2');
    case TargetPlatform.iOS:
      return kiOSUseLan ? _http(kPcIp) : _http('localhost');
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return _http('localhost');
    default:
      return _http(kPcIp);
  }
}
