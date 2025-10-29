import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color kInk = Color(0xFF2E5F3A);

class EmotionHexSelector extends StatefulWidget {
  final double size;
  final List<String> labels;
  final Color lineColor;
  final double strokeWidth;

  final double centerCircleRFactor;

  /// 設為 0 表示不畫描邊；預設 0。
  final double? centerCircleStrokeWidth;

  /// 若不提供，會使用元件內部的 _centerColor。
  final Color? centerFillColor;

  final List<Map<String, dynamic>> selections;
  final void Function(List<Map<String, dynamic>> tempSelection)? onChanged;
  final void Function(Map<String, dynamic> committed)? onCommit;
  final TextStyle? labelStyle;

  const EmotionHexSelector({
    super.key,
    this.size = 260,
    this.labels = const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
    this.lineColor = Colors.black,
    this.strokeWidth = 1.5,
    this.centerCircleRFactor = 0.12,
    this.centerCircleStrokeWidth = 0, // 預設不描邊
    this.centerFillColor,
    this.selections = const [],
    this.onChanged,
    this.onCommit,
    this.labelStyle,
  }) : assert(labels.length == 6, 'labels 必須剛好 6 個');

  @override
  State<EmotionHexSelector> createState() => _EmotionHexSelectorState();
}

class _EmotionHexSelectorState extends State<EmotionHexSelector> {
  int? _activeAxis;
  double _activeStrength = 0.0;

  /// 中心圓顏色（可依拖曳強度變色）
  Color _centerColor = const Color(0xFFEFE3A8);

  @override
  Widget build(BuildContext context) {
    final effectiveCenterFill =
        widget.centerFillColor ?? _centerColor; // 允許外部覆蓋，沒給就用內部狀態

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _updateFromDrag(d.localPosition),
        onPanUpdate: (d) => _updateFromDrag(d.localPosition),
        onPanEnd: (_) {
          if (_activeAxis != null && _activeStrength > 0.05) {
            widget.onCommit?.call({
              'emotion': widget.labels[_activeAxis!],
              'intensity': (_activeStrength * 100).clamp(0, 100).round(),
            });
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
            EmotionHexRing(
              size: widget.size,
              labels: widget.labels,
              lineColor: widget.lineColor,
              strokeWidth: widget.strokeWidth,
              centerCircleRFactor: widget.centerCircleRFactor,
              // 固定不畫描邊
              centerCircleStrokeWidth: 0,
              // 使用內部/外部計算出的填色
              centerFillColor: effectiveCenterFill,
              labelStyle:
                  widget.labelStyle ??
                  TextStyle(
                    fontSize: widget.size * 0.09,
                    color: kInk,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PersistLinesPainter(
                labels: widget.labels,
                selections: widget.selections,
                lineColor: widget.lineColor,
                centerCircleRFactor: widget.centerCircleRFactor,
              ),
            ),
            if (_activeAxis != null && _activeStrength > 0)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DragIndicatorPainter(
                  axisIndex: _activeAxis!,
                  strength: _activeStrength,
                  lineColor: widget.lineColor,
                  centerCircleRFactor: widget.centerCircleRFactor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateFromDrag(Offset localPos) {
    final sz = widget.size;
    final center = Offset(sz / 2, sz / 2);
    final v = localPos - center;

    final dist = v.distance;
    final angle = math.atan2(v.dy, v.dx);

    var a = angle + math.pi / 2;
    if (a < 0) a += 2 * math.pi;

    const per = 2 * math.pi / 6;
    int axis = (a / per).round() % 6;

    final centerR = sz * widget.centerCircleRFactor;
    final maxR = sz * 0.42;

    final start = centerR + 2.0;
    final usable = (dist - start);
    final range = (maxR - start).clamp(1, double.infinity);
    final s = (usable / range).clamp(0.0, 1.0);

    setState(() {
      _activeAxis = axis;
      _activeStrength = s;

      // 以 HSL 亮度控制做示範：強度越高，中心色越深
      final base = widget.centerFillColor ?? const Color(0xFFEFE3A8);
      final hsl = HSLColor.fromColor(base);
      final newLightness = 0.7 - 0.35 * s; // 0.35 ~ 0.7
      _centerColor = hsl.withLightness(newLightness.clamp(0.0, 1.0)).toColor();
    });

    widget.onChanged?.call([
      {'emotion': widget.labels[axis], 'intensity': (s * 100).round()},
    ]);
  }
}

class EmotionHexRing extends StatelessWidget {
  final double size;
  final List<String> labels;
  final Color lineColor;
  final double strokeWidth;

  final double centerCircleRFactor;
  final double centerCircleStrokeWidth;
  final Color? centerFillColor;

  final TextStyle? labelStyle;
  final double labelRadialGap;
  final List<double> labelExtraByIndex;

  const EmotionHexRing({
    super.key,
    this.size = 260,
    this.labels = const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
    this.lineColor = Colors.black,
    this.strokeWidth = 1.5,
    this.centerCircleRFactor = 0.12,
    this.centerCircleStrokeWidth = 0,
    this.centerFillColor,
    this.labelStyle,
    this.labelRadialGap = 10.0,
    this.labelExtraByIndex = const [0, 12, 10, 0, 10, 12],
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: size * 0.09,
      color: kInk,
      height: 1.0,
      fontWeight: FontWeight.w500,
    );

    final outerR = size * 0.42;
    const outerBack = 12.0;
    const outerLen = 16.0;
    final outerEdgeR = outerR - outerBack + outerLen;

    final baseLabelRadius = outerEdgeR + labelRadialGap;
    final double labelBoxWidth = size * 0.44;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _EmotionHexPainter(
              lineColor: lineColor,
              strokeWidth: strokeWidth,
              centerCircleRFactor: centerCircleRFactor,
              centerCircleStrokeWidth: centerCircleStrokeWidth,
              centerFillColor: centerFillColor,
            ),
          ),
          ...List.generate(6, (i) {
            final angle = -math.pi / 2 + i * (2 * math.pi / 6);
            double r = baseLabelRadius;
            final bool isVertical = (i % 3 == 0);
            if (isVertical) r += 4.0;
            if (i >= 0 && i < labelExtraByIndex.length) {
              r += labelExtraByIndex[i];
            }
            return Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(r * math.cos(angle), r * math.sin(angle)),
                child: SizedBox(
                  width: labelBoxWidth,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        softWrap: false,
                        style: labelStyle ?? defaultStyle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmotionHexPainter extends CustomPainter {
  final Color lineColor;
  final double strokeWidth;
  final double centerCircleRFactor;
  final double centerCircleStrokeWidth; // 0 = 不描邊
  final Color? centerFillColor;

  _EmotionHexPainter({
    required this.lineColor,
    required this.strokeWidth,
    required this.centerCircleRFactor,
    required this.centerCircleStrokeWidth,
    required this.centerFillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.square;

    final center = Offset(size.width / 2, size.height / 2);
    const n = 6;

    final centerR = size.shortestSide * centerCircleRFactor;
    final outerR = size.shortestSide * 0.42;

    // === 2) 外圈：六邊形實線，但在六個頂點（情緒詞對應方向）留白 ===
    const double outerHexInset = 4.0; // 六邊形整體往內縮一點，避免貼到標籤
    const double gapPx = 14.0; // 每個頂點要留白的長度（可調）
    final double R = outerR - outerHexInset;

    // 先算出六個頂點座標
    final List<Offset> verts = List.generate(n, (i) {
      final theta = -math.pi / 2 + i * (2 * math.pi / n);
      return Offset(
        center.dx + R * math.cos(theta),
        center.dy + R * math.sin(theta),
      );
    });

    // 逐邊畫線，但每邊兩端各縮掉 gapPx
    for (int i = 0; i < n; i++) {
      final Offset a = verts[i];
      final Offset b = verts[(i + 1) % n];

      final Offset ab = b - a;
      final double len = ab.distance;
      if (len <= gapPx * 2) continue;

      final Offset dir = ab / len; // 邊方向單位向量
      final Offset start = a + dir * gapPx; // 從 a 往 b 方向縮掉 gap
      final Offset end = b - dir * gapPx; // 從 b 往 a 方向縮掉 gap

      canvas.drawLine(start, end, stroke);
    }

    // === 3) 往外的分段虛線（與六方向一致） ===
    const dashCount = 4;
    const dashLen = 6.0;
    const dashGap = 10.0;
    final startR = centerR + 6.0;

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / n);
      final ca = math.cos(angle);
      final sa = math.sin(angle);

      for (int k = 0; k < dashCount; k++) {
        final r1 = startR + k * (dashLen + dashGap);
        final r2 = (r1 + dashLen).clamp(0.0, outerR);
        final p1 = Offset(center.dx + r1 * ca, center.dy + r1 * sa);
        final p2 = Offset(center.dx + r2 * ca, center.dy + r2 * sa);
        canvas.drawLine(p1, p2, stroke);
      }
    }

    // === 1) 中心圓（最後畫：只填色、可選描邊） ===
    if (centerFillColor != null) {
      final fill =
          Paint()
            ..color = centerFillColor!
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, centerR, fill);
    }
    if (centerCircleStrokeWidth > 0.01) {
      final circleStroke =
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = centerCircleStrokeWidth
            ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, centerR, circleStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionHexPainter old) {
    return old.lineColor != lineColor ||
        old.strokeWidth != strokeWidth ||
        old.centerCircleRFactor != centerCircleRFactor ||
        old.centerCircleStrokeWidth != centerCircleStrokeWidth ||
        old.centerFillColor != centerFillColor;
  }
}

class _DragIndicatorPainter extends CustomPainter {
  final int axisIndex;
  final double strength;
  final Color lineColor;
  final double centerCircleRFactor;

  _DragIndicatorPainter({
    required this.axisIndex,
    required this.strength,
    required this.lineColor,
    required this.centerCircleRFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const n = 6;
    final angle = -math.pi / 2 + axisIndex * (2 * math.pi / n);
    final ca = math.cos(angle);
    final sa = math.sin(angle);

    final centerR = size.shortestSide * centerCircleRFactor;
    final maxR = size.shortestSide * 0.42;

    final start = centerR + 2.0;
    final end = start + (maxR - start) * strength;

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
    canvas.drawCircle(p2, 3, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _DragIndicatorPainter old) {
    return old.axisIndex != axisIndex ||
        old.strength != strength ||
        old.lineColor != lineColor ||
        old.centerCircleRFactor != centerCircleRFactor;
  }
}

class _PersistLinesPainter extends CustomPainter {
  final List<String> labels;
  final List<Map<String, dynamic>> selections;
  final Color lineColor;
  final double centerCircleRFactor;

  _PersistLinesPainter({
    required this.labels,
    required this.selections,
    required this.lineColor,
    required this.centerCircleRFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const n = 6;
    final maxR = size.shortestSide * 0.42;
    final centerR = size.shortestSide * centerCircleRFactor;

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

    for (final sel in selections) {
      final emotion = sel['emotion'] as String;
      final intensity = (sel['intensity'] as num?)?.toDouble() ?? 0.0;
      final idx = labels.indexOf(emotion);
      if (idx < 0 || intensity <= 0) continue;

      final strength = (intensity / 100.0).clamp(0.0, 1.0);
      final angle = -math.pi / 2 + idx * (2 * math.pi / n);
      final ca = math.cos(angle);
      final sa = math.sin(angle);

      final start = centerR + 2.0;
      final end = start + (maxR - start) * strength;

      final p1 = Offset(center.dx + start * ca, center.dy + start * sa);
      final p2 = Offset(center.dx + end * ca, center.dy + end * sa);

      canvas.drawLine(p1, p2, fill);
      canvas.drawLine(p1, p2, stroke);
      canvas.drawCircle(p2, 3, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _PersistLinesPainter old) {
    return old.selections != selections ||
        old.lineColor != lineColor ||
        old.centerCircleRFactor != centerCircleRFactor;
  }
}
