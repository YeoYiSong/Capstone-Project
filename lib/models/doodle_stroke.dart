import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmotionHexRing extends StatelessWidget {
  final double size;
  final List<String> labels;
  final String centerSvgAsset;
  final Color lineColor;
  final double strokeWidth;
  final TextStyle? labelStyle;

  const EmotionHexRing({
    super.key,
    this.size = 260,
    this.labels = const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
    this.centerSvgAsset = 'assets/icons/interface_loading_circle.svg',
    this.lineColor = Colors.black,
    this.strokeWidth = 1.5,
    this.labelStyle,
  }) : assert(labels.length == 6, 'labels 必須剛好 6 個');

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontFamily: 'PixelFont',
      fontSize: size * 0.09, // 依尺寸自動縮放
      color: lineColor,
      height: 1.0,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 畫短線（跟圖上的造型）
          CustomPaint(
            painter: _EmotionHexPainter(
              lineColor: lineColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // 中央 SVG（你剛剛加入的 interface_loading_circle.svg）
          Center(
            child: SvgPicture.asset(
              centerSvgAsset,
              width: size * 0.28,
              height: size * 0.28,
              fit: BoxFit.contain,
            ),
          ),
          // 六個文字
          ...List.generate(6, (i) {
            // 從正上方開始，順時針每 60 度
            final angle = -math.pi / 2 + i * (2 * math.pi / 6);
            return _polarLabel(
              angle: angle,
              radius: size * 0.40, // 文字離中心的距離，對齊你圖的視覺
              availableSize: size,
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: labelStyle ?? defaultStyle,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 把 child 放到極座標位置（以元件中心為圓心）
  Widget _polarLabel({
    required double angle,
    required double radius,
    required double availableSize,
    required Widget child,
  }) {
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(dx, dy),
        // 給定寬度，讓文字置中，不會撞線
        child: SizedBox(
          width: availableSize * 0.30,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _EmotionHexPainter extends CustomPainter {
  final Color lineColor;
  final double strokeWidth;

  _EmotionHexPainter({required this.lineColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.square;

    final center = Offset(size.width / 2, size.height / 2);
    final n = 6;

    // 參數可微調來貼近你的圖
    final outerR = size.shortestSide * 0.42; // 外側短線中心半徑
    final innerR = size.shortestSide * 0.18; // 內側短線中心半徑
    final outerLen = 16.0; // 外側短線長度
    final innerLen = 16.0; // 內側短線長度
    final outerBack = 12.0; // 外側短線往內回縮
    final innerForward = 8.0; // 內側短線往外推

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / n);
      final ca = math.cos(angle);
      final sa = math.sin(angle);

      // 外側短線（靠近文字的一段）
      final o1 = Offset(
        center.dx + (outerR - outerBack) * ca,
        center.dy + (outerR - outerBack) * sa,
      );
      final o2 = Offset(
        center.dx + (outerR - outerBack + outerLen) * ca,
        center.dy + (outerR - outerBack + outerLen) * sa,
      );
      canvas.drawLine(o1, o2, paint);

      // 內側短線（靠近中心的一段）
      final i1 = Offset(
        center.dx + (innerR + innerForward) * ca,
        center.dy + (innerR + innerForward) * sa,
      );
      final i2 = Offset(
        center.dx + (innerR + innerForward + innerLen) * ca,
        center.dy + (innerR + innerForward + innerLen) * sa,
      );
      canvas.drawLine(i1, i2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionHexPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
// ========= 互動版：從中心拖拉設定強度 =========

class EmotionHexSelector extends StatefulWidget {
  final double size;
  final List<String> labels; // 6 個情緒名，順序：上方開始順時針
  final String centerSvgAsset;
  final Color lineColor;
  final double strokeWidth;

  /// 目前已選（持久）: [{'emotion': '喜悅', 'intensity': 72}, ...]
  final List<Map<String, dynamic>> selections;

  /// 拖曳過程中的即時回傳（單一情緒）
  /// e.g. [{'emotion': '喜悅', 'intensity': 72}]
  final void Function(List<Map<String, dynamic>> tempSelection)? onChanged;

  /// 放開手指（提交一次選擇）；你可以把這筆加入清單
  final void Function(Map<String, dynamic> committed)? onCommit;

  const EmotionHexSelector({
    super.key,
    this.size = 260,
    this.labels = const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
    this.centerSvgAsset = 'assets/icons/interface_loading_circle.svg',
    this.lineColor = Colors.black,
    this.strokeWidth = 1.5,
    this.onChanged,
    this.onCommit,
    this.selections = const [], // 👈 新增：持久線資料
  }) : assert(labels.length == 6, 'labels 必須剛好 6 個');

  @override
  State<EmotionHexSelector> createState() => _EmotionHexSelectorState();
}

class _EmotionHexSelectorState extends State<EmotionHexSelector> {
  // 目前拖拉對準到哪一軸（0~5），以及強度(0~1)
  int? _activeAxis;
  double _activeStrength = 0.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: LayoutBuilder(
        builder: (_, __) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _updateFromDrag(d.localPosition),
            onPanUpdate: (d) => _updateFromDrag(d.localPosition),
            onPanEnd: (_) {
              if (_activeAxis != null && _activeStrength > 0.05) {
                final committed = {
                  'emotion': widget.labels[_activeAxis!],
                  'intensity': (_activeStrength * 100).clamp(0, 100).round(),
                };
                widget.onCommit?.call(committed);
              }
              setState(() {
                _activeAxis = null;
                _activeStrength = 0.0;
              });
              widget.onChanged?.call(const []);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 底層樣式（跟 EmotionHexRing 一樣）
                EmotionHexRing(
                  size: widget.size,
                  labels: widget.labels,
                  centerSvgAsset: widget.centerSvgAsset,
                  lineColor: widget.lineColor,
                  strokeWidth: widget.strokeWidth,
                  labelStyle: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: widget.size * 0.09,
                    color: const Color(0xFF98A89A),
                    height: 1.0,
                  ),
                ),

                // ① 先畫【持久】選擇（全部）
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _PersistLinesPainter(
                    labels: widget.labels,
                    selections: widget.selections,
                    lineColor: widget.lineColor,
                  ),
                ),

                // ② 再畫【拖拉中】的暫時線，疊在上面
                if (_activeAxis != null && _activeStrength > 0)
                  CustomPaint(
                    painter: _DragIndicatorPainter(
                      axisIndex: _activeAxis!,
                      strength: _activeStrength,
                      lineColor: widget.lineColor,
                    ),
                    size: Size(widget.size, widget.size),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateFromDrag(Offset localPos) {
    final sz = widget.size;
    final center = Offset(sz / 2, sz / 2);
    final v = localPos - center;

    final dist = v.distance;
    final angle = math.atan2(v.dy, v.dx); // -pi..pi，0 在右方

    // 把角度轉成以正上方為 0 度，順時針遞增
    var a = angle + math.pi / 2; // 以上方為 0
    if (a < 0) a += 2 * math.pi;

    // 每 60 度一軸，算最接近的軸
    const per = 2 * math.pi / 6;
    int axis = (a / per).round() % 6;

    // 半徑參數要與 EmotionHexRing 相近，這裡用相同比率
    final innerR = sz * 0.18;
    final maxR = sz * 0.42; // 外短線附近
    final usable = (dist - innerR);
    final range = (maxR - innerR).clamp(1, double.infinity);
    final s = (usable / range).clamp(0.0, 1.0);

    setState(() {
      _activeAxis = axis;
      _activeStrength = s;
    });

    if (widget.onChanged != null) {
      widget.onChanged!([
        {'emotion': widget.labels[axis], 'intensity': (s * 100).round()},
      ]);
    }
  }
}

/// 互動拖拉時顯示的彩色延伸指示（單一軸）
class _DragIndicatorPainter extends CustomPainter {
  final int axisIndex;
  final double strength; // 0..1
  final Color lineColor;

  _DragIndicatorPainter({
    required this.axisIndex,
    required this.strength,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final n = 6;
    final angle = -math.pi / 2 + axisIndex * (2 * math.pi / n);
    final ca = math.cos(angle);
    final sa = math.sin(angle);

    final innerR = size.shortestSide * 0.18;
    final maxR = size.shortestSide * 0.42;
    final start = innerR + 8.0; // 與內短線相銜接
    final end = innerR + (maxR - innerR) * strength;

    final p1 = Offset(center.dx + start * ca, center.dy + start * sa);
    final p2 = Offset(center.dx + end * ca, center.dy + end * sa);

    final stroke =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square;

    final fill =
        Paint()
          ..color = lineColor.withValues(alpha: 0.25)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1, p2, fill);
    canvas.drawLine(p1, p2, stroke);

    final dot =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(p2, 3, dot);
  }

  @override
  bool shouldRepaint(covariant _DragIndicatorPainter oldDelegate) {
    return oldDelegate.axisIndex != axisIndex ||
        oldDelegate.strength != strength ||
        oldDelegate.lineColor != lineColor;
  }
}

/// 畫「持久存在」的多條延伸線
class _PersistLinesPainter extends CustomPainter {
  final List<String> labels;
  final List<Map<String, dynamic>> selections;
  final Color lineColor;

  _PersistLinesPainter({
    required this.labels,
    required this.selections,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final n = 6;
    final innerR = size.shortestSide * 0.18;
    final maxR = size.shortestSide * 0.42;

    final stroke =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square;

    final fill =
        Paint()
          ..color = lineColor.withValues(alpha: 0.25)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final dot =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

    for (final sel in selections) {
      final emotion = sel['emotion'] as String;
      final intensity = (sel['intensity'] as num?)?.toDouble() ?? 0.0;
      final idx = labels.indexOf(emotion);
      if (idx < 0 || intensity <= 0) continue;

      final strength = (intensity / 100.0).clamp(0.0, 1.0);
      final angle = -math.pi / 2 + idx * (2 * math.pi / n);
      final ca = math.cos(angle);
      final sa = math.sin(angle);

      final start = innerR + 8.0;
      final end = innerR + (maxR - innerR) * strength;

      final p1 = Offset(center.dx + start * ca, center.dy + start * sa);
      final p2 = Offset(center.dx + end * ca, center.dy + end * sa);

      canvas.drawLine(p1, p2, fill);
      canvas.drawLine(p1, p2, stroke);
      canvas.drawCircle(p2, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _PersistLinesPainter old) {
    return old.selections != selections || old.lineColor != lineColor;
  }
}
