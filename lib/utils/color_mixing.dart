import 'dart:math';

/// 對應每種情緒的 Hue 色相角度（HSL）
final Map<String, double> emotionHueMap = {
  '喜悅': 50, // 黃色
  '憤怒': 0, // 紅色
  '積極': 30, // 橘色
  '疲憊': 0, // 灰色（會在下方特判為 S = 0）
  '悲傷': 240, // 藍色
  '焦慮': 270, // 紫色
};

/// 將強度轉換為亮度（L）
/// 數值越高越深 → L 越低
double getLightness(double intensity) {
  // 強度從 1~100 映射到 Lightness：80%（淺）~30%（深）
  return 80 - (intensity / 100) * 50;
}

/// HSL 轉 RGB（輸出 [R, G, B] 範圍為 0~255）
List<int> hslToRgb(double h, double s, double l) {
  s /= 100;
  l /= 100;
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;

  double r = 0, g = 0, b = 0;

  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return [
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  ];
}

/// RGB 轉 Hex 色碼（不透明）
String rgbToHex(List<int> rgb) {
  final r = rgb[0].toRadixString(16).padLeft(2, '0');
  final g = rgb[1].toRadixString(16).padLeft(2, '0');
  final b = rgb[2].toRadixString(16).padLeft(2, '0');
  return '#FF${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
}

/// 混合顏色（根據情緒強度與 HSL 平均）
String mixColorsWithAlpha(List<Map<String, dynamic>> emotions) {
  if (emotions.isEmpty) return '#FF000000';

  double totalX = 0;
  double totalY = 0;
  double totalL = 0;
  double totalWeight = 0;

  for (var emotion in emotions) {
    final name = emotion['emotion'];
    final intensity = (emotion['intensity'] ?? 0).toDouble();
    final hue = emotionHueMap[name];

    if (hue == null || intensity <= 0) continue;

    // 將每種情緒強度（1~100）轉為飽和度、亮度、權重
    final s = (name == '疲憊') ? 0.0 : 100.0;
    final l = getLightness(intensity);
    final weight = intensity / 100;

    final rad = hue * pi / 180;
    final x = s * cos(rad);
    final y = s * sin(rad);

    totalX += x * weight;
    totalY += y * weight;
    totalL += l * weight;
    totalWeight += weight;
  }

  if (totalWeight == 0) return '#FF000000';

  final avgX = totalX / totalWeight;
  final avgY = totalY / totalWeight;
  final avgL = totalL / totalWeight;

  final h = (atan2(avgY, avgX) * 180 / pi + 360) % 360;
  final s = sqrt(avgX * avgX + avgY * avgY);
  final rgb = hslToRgb(h, s, avgL);

  return rgbToHex(rgb);
}
