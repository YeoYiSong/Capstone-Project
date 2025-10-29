import 'dart:math';

/// =====================
/// 美感色調配置（依情緒微調過的「最好看色域」）
/// =====================
class EmotionTone {
  final double h; // Hue 固定中心（度數）
  final double sMin; // 飽和度下限
  final double sMax; // 飽和度上限
  final double lMin; // 亮度下限
  final double lMax; // 亮度上限
  final double satGamma; // S 映射曲線（<1 = 中高段長得更快）
  final double lightGamma; // L 映射曲線（<1 = 亮度較快變亮）
  const EmotionTone({
    required this.h,
    required this.sMin,
    required this.sMax,
    required this.lMin,
    required this.lMax,
    required this.satGamma,
    required this.lightGamma,
  });
}

final Map<String, EmotionTone> emotionToneMap = {
  // 喜悅：金黃偏亮，飽和度高但不發白
  '喜悅': EmotionTone(
    h: 52,
    sMin: 65,
    sMax: 95,
    lMin: 72,
    lMax: 86,
    satGamma: 0.8,
    lightGamma: 0.6,
  ),
  // 憤怒：橘紅（8°）更耐看，明亮但保留能量
  '憤怒': EmotionTone(
    h: 8,
    sMin: 75,
    sMax: 100,
    lMin: 66,
    lMax: 82,
    satGamma: 0.7,
    lightGamma: 0.55,
  ),
  // 積極：琥珀橙，活力、亮且不刺眼
  '積極': EmotionTone(
    h: 34,
    sMin: 68,
    sMax: 96,
    lMin: 68,
    lMax: 85,
    satGamma: 0.75,
    lightGamma: 0.6,
  ),
  // 悲傷：偏 215° 的藍更清爽，避免 240° 太紫藍
  '悲傷': EmotionTone(
    h: 215,
    sMin: 60,
    sMax: 90,
    lMin: 66,
    lMax: 84,
    satGamma: 0.85,
    lightGamma: 0.65,
  ),
  // 焦慮：清透紫（280°）避免太黯，亮度偏高但不白
  '焦慮': EmotionTone(
    h: 280,
    sMin: 58,
    sMax: 88,
    lMin: 66,
    lMax: 84,
    satGamma: 0.85,
    lightGamma: 0.65,
  ),
  // 疲憊：帶一點冷灰藍，避免全灰太死（僅少量彩度）
  '疲憊': EmotionTone(
    h: 220,
    sMin: 6,
    sMax: 18,
    lMin: 72,
    lMax: 84,
    satGamma: 0.9,
    lightGamma: 0.7,
  ),
};

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

/// Hermite smoothstep：在 edge0~edge1 之間平滑從 0→1
double _smoothstep(double edge0, double edge1, double x) {
  final t = _clamp01((x - edge0) / (edge1 - edge0));
  return t * t * (3 - 2 * t);
}

/// 泛用映射：t∈[0,1] → [a,b]，加上 gamma 曲線（<1 = ease-out）
double _map01(double t, double a, double b, double gamma) {
  final g = pow(_clamp01(t), gamma).toDouble();
  return a + (b - a) * g;
}

/// --- 亮度與透明度對強度的映射 ---

/// 根據情緒 tone 與強度，取「最好看」的亮度（越大越亮，但不上白）
double getLightness(String name, double intensity) {
  final tone = emotionToneMap[name];
  final t = (intensity.clamp(0, 100)) / 100.0;
  if (tone == null) return 80; // fallback
  return _map01(t, tone.lMin, tone.lMax, tone.lightGamma).clamp(0.0, 100.0);
}

/// 根據情緒 tone 與強度，提升飽和度（避免亮度上去卻發白）
double getSaturation(String name, double intensity) {
  final tone = emotionToneMap[name];
  final t = (intensity.clamp(0, 100)) / 100.0;
  if (tone == null) return 90; // fallback
  return _map01(t, tone.sMin, tone.sMax, tone.satGamma).clamp(0.0, 100.0);
}

/// 透明度：低強度幾乎透明，中段開始加速顯色，高強度接近不透明
double getAlpha01(double intensity) {
  final t = (intensity.clamp(0, 100)) / 100.0;
  // 可微調：起點 0.08、終點 0.80，讓中段就有存在感
  return _smoothstep(0.08, 0.80, t);
}

/// Hue：直接使用 tone 的中心角度（已挑過耐看的色調）
double getHue(String name) {
  final tone = emotionToneMap[name];
  return (tone?.h ?? 0) % 360;
}

/// --- HSL / RGB 轉換 ---

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

String rgbaToHex(List<int> rgb, int alpha) {
  final a = alpha.clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
  final r = rgb[0].toRadixString(16).padLeft(2, '0').toUpperCase();
  final g = rgb[1].toRadixString(16).padLeft(2, '0').toUpperCase();
  final b = rgb[2].toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#$a$r$g$b';
}

/// --- 混色主函式 ---

String mixColorsWithAlpha(List<Map<String, dynamic>> emotions) {
  if (emotions.isEmpty) return '#00000000'; // 全透明

  double totalX = 0.0; // Hue 向量 X（半徑 = S）
  double totalY = 0.0; // Hue 向量 Y
  double totalL = 0.0; // 亮度加權
  double totalWeight = 0.0; // 權重（用 alpha）
  double alphaKeep = 1.0; // A_total = 1 - Π(1 - a_i)

  for (final e in emotions) {
    final String name = (e['emotion'] ?? '').toString();
    final double intensity = (e['intensity'] ?? 0).toDouble();
    if (intensity <= 0) continue;

    final h = getHue(name);
    final s = getSaturation(name, intensity);
    final l = getLightness(name, intensity);
    final a = getAlpha01(intensity);

    final w = a; // 更符合「看起來越濃越主導」
    final rad = h * pi / 180.0;
    final x = s * cos(rad);
    final y = s * sin(rad);

    totalX += x * w;
    totalY += y * w;
    totalL += l * w;
    totalWeight += w;

    alphaKeep *= (1.0 - a);
  }

  if (totalWeight <= 1e-6) return '#00000000';

  final avgX = totalX / totalWeight;
  final avgY = totalY / totalWeight;
  double h = atan2(avgY, avgX) * 180.0 / pi;
  if (h < 0) h += 360.0;

  double s = sqrt(avgX * avgX + avgY * avgY).clamp(0.0, 100.0);
  final l = (totalL / totalWeight).clamp(0.0, 100.0);

  final alpha01 = 1.0 - alphaKeep;
  final alpha = (alpha01 * 255.0).round().clamp(0, 255);

  final rgb = hslToRgb(h, s, l);
  return rgbaToHex(rgb, alpha);
}
