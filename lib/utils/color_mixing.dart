import 'dart:math';

// 定義情緒與對應的HSL顏色（固定）
final Map<String, List<double>> emotionColors = {
  '喜悅': [50, 100, 50], // HSL(50, 100%, 50%)
  '憤怒': [0, 100, 50], // HSL(0, 100%, 50%)
  '積極': [30, 100, 50], // HSL(30, 100%, 50%)
  '疲憊': [0, 0, 50], // HSL(0, 0%, 50%)
  '悲傷': [240, 100, 50], // HSL(240, 100%, 50%)
  '焦慮': [270, 100, 50], // HSL(270, 100%, 50%)
};

// 根據強度計算透明度（Alpha）
double getAlpha(double intensity) {
  if (intensity <= 30) return 0.3;
  if (intensity <= 70) return 0.6;
  return 1.0;
}

// HSL轉RGB（返回[0-255]範圍的RGB值）
List<int> hslToRgb(double h, double s, double l) {
  s /= 100;
  l /= 100;
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  List<double> rgb;

  if (h < 60) {
    rgb = [c, x, 0];
  } else if (h < 120) {
    rgb = [x, c, 0];
  } else if (h < 180) {
    rgb = [0, c, x];
  } else if (h < 240) {
    rgb = [0, x, c];
  } else if (h < 300) {
    rgb = [x, 0, c];
  } else {
    rgb = [c, 0, x];
  }

  return [
    ((rgb[0] + m) * 255).round(),
    ((rgb[1] + m) * 255).round(),
    ((rgb[2] + m) * 255).round(),
  ];
}

// RGB轉HEX（包含Alpha）
String rgbToHex(List<int> rgb, double alpha) {
  final a = (alpha * 255).round().toRadixString(16).padLeft(2, '0');
  final r = rgb[0].toRadixString(16).padLeft(2, '0');
  final g = rgb[1].toRadixString(16).padLeft(2, '0');
  final b = rgb[2].toRadixString(16).padLeft(2, '0');
  return '#$a$r$g$b'.toUpperCase();
}

// 混合顏色（考慮透明度）
String mixColorsWithAlpha(List<Map<String, dynamic>> emotions) {
  double totalX = 0, totalY = 0, totalL = 0, totalWeight = 0;

  for (var emotion in emotions) {
    final name = emotion['emotion'] as String;
    final intensity = (emotion['intensity'] as num).toDouble();
    if (!emotionColors.containsKey(name)) continue;

    final hsl = emotionColors[name]!;
    final h = hsl[0], s = hsl[1], l = hsl[2];
    final alpha = getAlpha(intensity);
    final weight = intensity / 100 * alpha;

    // HSL轉平面座標（x, y, l）
    final rad = h * pi / 180;
    final x = s * cos(rad);
    final y = s * sin(rad);

    totalX += x * weight;
    totalY += y * weight;
    totalL += l * weight;
    totalWeight += weight;
  }

  if (totalWeight == 0) return '#FF000000'; // 默認透明黑色

  // 計算平均值
  final avgX = totalX / totalWeight;
  final avgY = totalY / totalWeight;
  final avgL = totalL / totalWeight;

  // 轉回HSL
  final s = sqrt(avgX * avgX + avgY * avgY);
  final h = (atan2(avgY, avgX) * 180 / pi + 360) % 360;
  final l = avgL;

  // HSL轉RGB
  final rgb = hslToRgb(h, s, l);
  return rgbToHex(rgb, totalWeight > 1 ? 1 : totalWeight);
}

// 混合顏色（不考慮透明度）
String mixColorsWithoutAlpha(List<Map<String, dynamic>> emotions) {
  double totalX = 0, totalY = 0, totalL = 0, totalWeight = 0;

  for (var emotion in emotions) {
    final name = emotion['emotion'] as String;
    final intensity = (emotion['intensity'] as num).toDouble();
    if (!emotionColors.containsKey(name)) continue;

    final hsl = emotionColors[name]!;
    final h = hsl[0], s = hsl[1], l = hsl[2];
    final weight = intensity / 100;

    // HSL轉平面座標（x, y, l）
    final rad = h * pi / 180;
    final x = s * cos(rad);
    final y = s * sin(rad);

    totalX += x * weight;
    totalY += y * weight;
    totalL += l * weight;
    totalWeight += weight;
  }

  if (totalWeight == 0) return '#FF000000'; // 默認透明黑色

  // 計算平均值
  final avgX = totalX / totalWeight;
  final avgY = totalY / totalWeight;
  final avgL = totalL / totalWeight;

  // 轉回HSL
  final s = sqrt(avgX * avgX + avgY * avgY);
  final h = (atan2(avgY, avgX) * 180 / pi + 360) % 360;
  final l = avgL;

  // HSL轉RGB
  final rgb = hslToRgb(h, s, l);
  return rgbToHex(rgb, 1.0); // Alpha固定為1
}
