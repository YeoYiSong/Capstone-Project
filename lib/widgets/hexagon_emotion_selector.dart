import 'package:flutter/material.dart';
import 'dart:math';

class HexagonEmotionSelector extends StatefulWidget {
  final bool isEnglish;
  final Function(List<Map<String, dynamic>>) onEmotionSelected;

  const HexagonEmotionSelector({
    super.key,
    required this.isEnglish,
    required this.onEmotionSelected,
  });

  @override
  State<HexagonEmotionSelector> createState() => _HexagonEmotionSelectorState();
}

class _HexagonEmotionSelectorState extends State<HexagonEmotionSelector> {
  List<Map<String, dynamic>> _selectedEmotions = [];
  Offset? _dragPosition;
  Offset? _finalPosition;
  List<double> _lastIntensities = List.filled(7, 0.0); // 每個扇區獨立強度

  final Map<String, Color> _emotionColors = {
    '喜悅': Colors.yellow,
    '積極': Colors.cyan,
    '焦慮': Colors.purple,
    '悲傷': Colors.blue,
    '疲憊': Colors.grey,
    '憤怒': Colors.red,
    '平靜': Colors.white,
  };

  final Map<String, String> _emotionTranslations = {
    '喜悅': 'Joy',
    '積極': 'Active',
    '焦慮': 'Anxiety',
    '悲傷': 'Sadness',
    '疲憊': 'Fatigue',
    '憤怒': 'Anger',
    '平靜': 'Calmness',
  };

  @override
  void initState() {
    super.initState();
    // 初始化 7 個扇區 （6 情緒 + 平靜）
    _selectedEmotions = [
      {'emotion': '喜悅', 'intensity': 0.0, 'position': null},
      {'emotion': '積極', 'intensity': 0.0, 'position': null},
      {'emotion': '焦慮', 'intensity': 0.0, 'position': null},
      {'emotion': '悲傷', 'intensity': 0.0, 'position': null},
      {'emotion': '疲憊', 'intensity': 0.0, 'position': null},
      {'emotion': '憤怒', 'intensity': 0.0, 'position': null},
      {'emotion': '平靜', 'intensity': 0.0, 'position': null},
    ];
  }

  void _clearEmotions() {
    setState(() {
      _selectedEmotions =
          _selectedEmotions
              .map(
                (emotion) => {
                  'emotion': emotion['emotion'],
                  'intensity': 0.0,
                  'position': null,
                },
              )
              .toList();
      _dragPosition = null;
      _finalPosition = null;
      _lastIntensities = List.filled(7, 0.0);
    });
    widget.onEmotionSelected(_selectedEmotions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: GestureDetector(
            onPanStart: (details) => _handleDrag(details.localPosition),
            onPanUpdate: (details) => _handleDrag(details.localPosition),
            onPanEnd: (details) {
              setState(() {
                _finalPosition = _dragPosition;
                _dragPosition = null;
                widget.onEmotionSelected(_selectedEmotions);
              });
            },
            child: CustomPaint(
              painter: HexagonPainter(
                selectedEmotions: _selectedEmotions,
                dragPosition: _dragPosition,
                finalPosition: _finalPosition,
                emotionColors: _emotionColors,
                emotionTranslations: _emotionTranslations,
                isEnglish: widget.isEnglish,
              ),
              child: Container(),
            ),
          ),
        ),
        // 顯示所有非 0 強度的情緒
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children:
                _selectedEmotions
                    .asMap()
                    .entries
                    .where((entry) => entry.value['intensity'] > 0)
                    .map(
                      (entry) => Text(
                        widget.isEnglish
                            ? '${_emotionTranslations[entry.value['emotion']]}: ${entry.value['intensity'].toStringAsFixed(1)}%'
                            : '${entry.value['emotion']}: ${entry.value['intensity'].toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                widget.onEmotionSelected(_selectedEmotions);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isEnglish ? 'Emotions confirmed' : '情緒已確認',
                    ),
                  ),
                );
              },
              child: Text(widget.isEnglish ? 'Confirm' : '確認'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _clearEmotions,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: Text(widget.isEnglish ? 'Clear' : '清除'),
            ),
          ],
        ),
      ],
    );
  }

  void _handleDrag(Offset position) {
    const double centerX = 100;
    const double centerY = 100;
    const double radius = 80;
    const double centerRadius = 20;

    final double distanceFromCenter = sqrt(
      pow(position.dx - centerX, 2) + pow(position.dy - centerY, 2),
    );

    if (distanceFromCenter <= centerRadius) {
      // 處理平靜（索引 6）
      setState(() {
        _selectedEmotions[6] = {
          'emotion': '平靜',
          'intensity': 0.0,
          'position': position,
        };
        _dragPosition = position;
      });
      widget.onEmotionSelected(_selectedEmotions);
      return;
    }

    if (distanceFromCenter <= radius) {
      final double angle = atan2(position.dy - centerY, position.dx - centerX);
      final double normalizedAngle = (angle + 2 * pi) % (2 * pi);
      final int sectionIndex = (normalizedAngle / (pi / 3)).floor() % 6;

      final double rawIntensity = ((distanceFromCenter - centerRadius) /
              (radius - centerRadius) *
              100)
          .clamp(0, 100);
      final double smoothedIntensity =
          _lastIntensities[sectionIndex] +
          (rawIntensity - _lastIntensities[sectionIndex]) * 0.2;
      _lastIntensities[sectionIndex] = smoothedIntensity;

      setState(() {
        _selectedEmotions[sectionIndex] = {
          'emotion': _selectedEmotions[sectionIndex]['emotion'],
          'intensity': smoothedIntensity,
          'position': position,
        };
        _dragPosition = position;
      });
      widget.onEmotionSelected(_selectedEmotions);
    } else {
      setState(() {
        _dragPosition = null;
      });
    }
  }
}

class HexagonPainter extends CustomPainter {
  final List<Map<String, dynamic>> selectedEmotions;
  final Offset? dragPosition;
  final Offset? finalPosition;
  final Map<String, Color> emotionColors;
  final Map<String, String> emotionTranslations;
  final bool isEnglish;

  HexagonPainter({
    required this.selectedEmotions,
    this.dragPosition,
    this.finalPosition,
    required this.emotionColors,
    required this.emotionTranslations,
    required this.isEnglish,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    const double radius = 80;
    const double centerRadius = 20;

    final Paint borderPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final Paint dividerPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    // 繪製六邊形
    Path hexagonPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * pi / 3) + (pi / 6);
      final double x = centerX + radius * cos(angle);
      final double y = centerY + radius * sin(angle);
      if (i == 0) {
        hexagonPath.moveTo(x, y);
      } else {
        hexagonPath.lineTo(x, y);
      }
    }
    hexagonPath.close();
    canvas.drawPath(hexagonPath, borderPaint);

    // 繪製扇區分割線
    for (int i = 0; i < 6; i++) {
      final double angle = (i * pi / 3) + (pi / 6);
      final double x = centerX + radius * cos(angle);
      final double y = centerY + radius * sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), dividerPaint);
    }

    // 繪製每個情緒頂點和標籤
    final List<String> emotions = ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'];
    for (int i = 0; i < 6; i++) {
      final double angle = (i * pi / 3) + (pi / 6);
      final double labelAngle = (i * pi / 3) + (pi / 6);
      final double x = centerX + radius * cos(angle);
      final double y = centerY + radius * sin(angle);
      final double labelX = centerX + (radius + 30) * cos(labelAngle);
      final double labelY = centerY + (radius + 30) * sin(labelAngle);

      // 繪製頂點圓點
      final Paint vertexPaint =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 10, vertexPaint);

      // 繪製情緒標籤
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: isEnglish ? emotionTranslations[emotions[i]] : emotions[i],
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );

      // 繪製已選擇的扇形填充
      final emotionData = selectedEmotions[i];
      if (emotionData['intensity'] > 0) {
        final Offset position = emotionData['position'];
        final double intensity = emotionData['intensity'];
        final double distanceToVertex = sqrt(
          pow(position.dx - x, 2) + pow(position.dy - y, 2),
        );
        final double maxDistance = sqrt(
          pow(centerX - x, 2) + pow(centerY - y, 2),
        );
        final double t = (maxDistance - distanceToVertex) / maxDistance;

        Path fanPath = Path();
        fanPath.moveTo(centerX, centerY);
        final double startAngle = (i * pi / 3);
        final double endAngle = ((i + 1) * pi / 3);

        final double fanRadius = radius * t;
        final double startX = centerX + fanRadius * cos(startAngle);
        final double startY = centerY + fanRadius * sin(startAngle);
        final double endX = centerX + fanRadius * cos(endAngle);
        final double endY = centerY + fanRadius * sin(endAngle);

        fanPath.lineTo(startX, startY);
        fanPath.arcToPoint(
          Offset(endX, endY),
          radius: Radius.circular(fanRadius),
          clockwise: true,
        );
        fanPath.lineTo(centerX, centerY);
        fanPath.close();

        final Paint fanPaint =
            Paint()
              ..style = PaintingStyle.fill
              ..color = emotionColors[emotions[i]]!.withValues(
                alpha: intensity / 100,
              );
        canvas.drawPath(fanPath, fanPaint);
      }
    }

    // 高亮當前拖曳的情緒區域
    if (dragPosition != null) {
      final double angle = atan2(
        dragPosition!.dy - centerY,
        dragPosition!.dx - centerX,
      );
      final double normalizedAngle = (angle + 2 * pi) % (2 * pi);
      final int sectionIndex = (normalizedAngle / (pi / 3)).floor() % 6;

      Path highlightPath = Path();
      highlightPath.moveTo(centerX, centerY);
      final double startAngle = sectionIndex * pi / 3;
      final double endAngle = (sectionIndex + 1) * pi / 3;
      final double highlightRadius = radius;
      final double startX = centerX + highlightRadius * cos(startAngle);
      final double startY = centerY + highlightRadius * sin(startAngle);
      final double endX = centerX + highlightRadius * cos(endAngle);
      final double endY = centerY + highlightRadius * sin(endAngle);

      highlightPath.lineTo(startX, startY);
      highlightPath.arcToPoint(
        Offset(endX, endY),
        radius: Radius.circular(highlightRadius),
        clockwise: true,
      );
      highlightPath.lineTo(centerX, centerY);
      highlightPath.close();

      final Paint highlightPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = emotionColors[emotions[sectionIndex]]!.withValues(
              alpha: 0.3,
            );
      canvas.drawPath(highlightPath, highlightPaint);
    }

    // 繪製中心點（平靜）
    final Paint centerPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, centerY), centerRadius, centerPaint);

    if (selectedEmotions[6]['intensity'] == 0.0 &&
        selectedEmotions[6]['position'] != null) {
      final Paint calmPaint =
          Paint()
            ..color = Colors.grey.withValues(alpha: 0.5)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), centerRadius, calmPaint);
    }

    final TextPainter centerTextPainter = TextPainter(
      text: TextSpan(
        text: isEnglish ? 'Calmness' : '平靜',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    centerTextPainter.layout();
    centerTextPainter.paint(
      canvas,
      Offset(
        centerX - centerTextPainter.width / 2,
        centerY - centerTextPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.selectedEmotions != selectedEmotions ||
        oldDelegate.dragPosition != dragPosition ||
        oldDelegate.finalPosition != finalPosition;
  }
}
