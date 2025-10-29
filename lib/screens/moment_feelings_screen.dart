import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_hex_selector.dart';
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import '../utils/recommendation_manager.dart';

class MomentFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final bool isReadOnly;
  final List<Map<String, dynamic>>? emotions;
  final String? mixedColor;
  final String? moodText;
  final String? details;

  const MomentFeelingsScreen({
    super.key,
    this.isEnglish = false,
    required this.date,
    this.isReadOnly = false,
    this.emotions,
    this.mixedColor,
    this.moodText,
    this.details,
  });

  @override
  State<MomentFeelingsScreen> createState() => MomentFeelingsScreenState();
}

class MomentFeelingsScreenState extends State<MomentFeelingsScreen> {
  static const Color _bgTop = Color(0xFFEAF6E9);
  static const Color _bgBottom = Color(0xFFD7EBDD);
  static const Color _title = Color(0xFF2E5F3A);
  static const Color _card = Color(0xFFC8E2B9);
  static const Color _btnEnabled = Color(0xFF2E5F3A);
  static const Color _btnDisabled = Color(0xFFDDEBD7);
  static const Color _ink = Color(0xFF395727);

  String moodText = '';
  late final TextEditingController _moodController;
  final FocusNode _moodFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isSaving = false;

  List<Map<String, dynamic>> _selectedEmotions = [];
  List<Map<String, dynamic>> _hoverTemp = const [];

  static const Map<String, String> _aliasToKey = {
    '喜悅': 'joy',
    '積極': 'positive',
    '焦慮': 'anxious',
    '悲傷': 'sad',
    '疲憊': 'tired',
    '憤怒': 'angry',
    'Joy': 'joy',
    'Positive': 'positive',
    'Anxious': 'anxious',
    'Sad': 'sad',
    'Tired': 'tired',
    'Angry': 'angry',
  };
  static const Map<String, String> _keyToChinese = {
    'joy': '喜悅',
    'positive': '積極',
    'anxious': '焦慮',
    'sad': '悲傷',
    'tired': '疲憊',
    'angry': '憤怒',
  };

  List<Map<String, dynamic>> _normalizeForMix(List<Map<String, dynamic>> list) {
    return list.map((e) {
      final raw = (e['emotion'] ?? '').toString();
      final key = _aliasToKey[raw] ?? raw;
      final cn = _keyToChinese[key] ?? raw;
      return {...e, 'emotion': cn};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _moodController = TextEditingController(text: widget.moodText ?? '');
    moodText = widget.moodText ?? '';
    if (widget.emotions != null) _selectedEmotions = widget.emotions!;
    _moodController.addListener(_onAnyTextChanged);
  }

  @override
  void didUpdateWidget(covariant MomentFeelingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {});
    }
  }

  void _onAnyTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _moodController.removeListener(_onAnyTextChanged);
    _moodController.dispose();
    _moodFocusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (widget.isReadOnly) return false;
    final hasText = _moodController.text.trim().isNotEmpty;
    final hasEmotions = _selectedEmotions.isNotEmpty;
    return hasText || hasEmotions;
  }

  Color _computeCenterColor() {
    final fromDb = widget.mixedColor?.trim() ?? '';
    if (fromDb.isNotEmpty) return _hexToColor(fromDb);

    final combined = <Map<String, dynamic>>[
      ..._selectedEmotions.map((e) => Map<String, dynamic>.from(e)),
    ];
    if (_hoverTemp.isNotEmpty) {
      final t = _hoverTemp.first;
      final i = combined.indexWhere((e) => e['emotion'] == t['emotion']);
      if (i >= 0) {
        combined[i] = t;
      } else {
        combined.add(t);
      }
    }
    if (combined.isEmpty) return Colors.transparent;

    final normalized = _normalizeForMix(combined);
    final hex = mixColorsWithAlpha(normalized);
    if (hex.trim().isEmpty) return Colors.transparent;
    return _hexToColor(hex);
  }

  Color _hexToColor(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  void _clearEmotions() {
    if (!mounted) return;
    setState(() {
      _selectedEmotions = [];
      _hoverTemp = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final centerColor = _computeCenterColor();

    final titleText = widget.isEnglish ? 'Moment Feeling' : '當下的感受';
    final questionText = widget.isEnglish ? 'How do you feel now?' : '現在感覺如何呢？';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    final ringLabels =
        widget.isEnglish
            ? const ['Joy', 'Positive', 'Anxious', 'Sad', 'Tired', 'Angry']
            : const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final compact = h < 640;

              final double ringTopOffset = compact ? 24 : h * 0.08;
              final double gapHexToClear = compact ? 18 : h * 0.045;
              final double gapClearToCard = compact ? 26 : h * 0.06;
              final double cardHeight = compact ? 170 : h * 0.28;
              final double gapCardToBtn = compact ? 14 : h * 0.035;

              const pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);
              final ringSize = [
                w * 0.56,
                h * 0.34,
                360.0,
              ].reduce((a, b) => a < b ? a : b);

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _title, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: _title,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 26,
                          color: _title,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ringTopOffset),

                  // 六邊形
                  Center(
                    child: IgnorePointer(
                      ignoring: widget.isReadOnly,
                      child: EmotionHexSelector(
                        size: ringSize,
                        labels: ringLabels,
                        selections: _selectedEmotions,
                        centerFillColor: centerColor,
                        labelStyle: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: ringSize * 0.09,
                          color: _title,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (temp) => setState(() => _hoverTemp = temp),
                        onCommit: (one) {
                          final i = _selectedEmotions.indexWhere(
                            (e) => e['emotion'] == one['emotion'],
                          );
                          if (i >= 0) {
                            _selectedEmotions[i] = one;
                          } else {
                            _selectedEmotions.add(one);
                          }
                          setState(() => _hoverTemp = const []);
                        },
                      ),
                    ),
                  ),

                  // 六邊形 → 清除按鈕距離
                  SizedBox(height: gapHexToClear),

                  // 清除按鈕
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: widget.isReadOnly ? null : _clearEmotions,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _title, width: 1.5),
                          shape: const StadiumBorder(),
                          foregroundColor: _title,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          widget.isEnglish ? 'Clear' : '清除',
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 清除按鈕 → 卡片距離
                  SizedBox(height: gapClearToCard),

                  _RoundedLinedCard(
                    background: _card,
                    lineColor: Colors.white.withValues(alpha: 0.45),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    minHeight: cardHeight,
                    maxHeight: cardHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionText,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _moodController,
                            focusNode: _moodFocusNode,
                            cursorColor: _ink,
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                              color: _ink,
                            ),
                            decoration: const InputDecoration(
                              isCollapsed: false,
                              border: InputBorder.none,
                              hintText: '',
                            ),
                            onChanged: (text) => moodText = text,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            enabled: !widget.isReadOnly && !_isSaving,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gapCardToBtn),

                  // 完成按鈕
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed:
                            (!_canSubmit || _isSaving)
                                ? null
                                : () async {
                                  setState(() => _isSaving = true);
                                  void showErrorSnackBar(Object e) {
                                    if (!mounted) return;
                                    final msg =
                                        widget.isEnglish
                                            ? 'Failed to save moment entry: $e'
                                            : '儲存瞬間記錄失敗：$e';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }

                                  try {
                                    final normalizedForSave = _normalizeForMix(
                                      _selectedEmotions,
                                    );

                                    await _apiClient.saveDiaryEntry(
                                      date: widget.date,
                                      type: 'Moment',
                                      emotions: normalizedForSave,
                                      mixedColor: null,
                                      moodText: moodText,
                                      details: '',
                                      isEnglish: widget.isEnglish,
                                    );

                                    RecommendationManager.instance
                                        .refreshAfterEntrySaved(
                                          savedDate: widget.date,
                                          isDay: false,
                                        );

                                    if (!context.mounted) return;
                                    Navigator.of(context).pushNamed(
                                      '/diary_review',
                                      arguments: const {'animate': false},
                                    );
                                  } catch (e) {
                                    if (kDebugMode) print(e);
                                    showErrorSnackBar(e);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canSubmit ? _btnEnabled : _btnDisabled,
                          foregroundColor:
                              _canSubmit
                                  ? Colors.white
                                  : const Color(0xFF9CB39F),
                          elevation: _canSubmit ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          doneText,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );

              return compact
                  ? SingleChildScrollView(padding: pagePadding, child: content)
                  : Padding(padding: pagePadding, child: content);
            },
          ),
        ),
      ),
    );
  }
}

class _RoundedLinedCard extends StatelessWidget {
  final Color background;
  final Color lineColor;
  final EdgeInsets padding;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _RoundedLinedCard({
    required this.background,
    required this.lineColor,
    required this.padding,
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _LinedBackgroundPainter(lineColor: lineColor),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _LinedBackgroundPainter extends CustomPainter {
  final Color lineColor;
  _LinedBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.2;
    const int lines = 4;
    const double top = 44;
    final double gap = (size.height - top) / (lines + 1);
    for (int i = 1; i <= lines; i++) {
      final y = top + gap * i;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedBackgroundPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
