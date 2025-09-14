import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/doodle_stroke.dart'; // EmotionHexSelector
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';

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
  MomentFeelingsScreenState createState() => MomentFeelingsScreenState();
}

class MomentFeelingsScreenState extends State<MomentFeelingsScreen> {
  // 視覺常數
  static const Color _title = Color(0xFF2E5F3A);
  static const Color _card = Color(0xFFB7C8B1);
  static const Color _lineWhite = Color(0xFFFFFFFF);
  static const Color _btnEnabled = Color(0xFF2E5F3A);
  static const Color _btnDisabled = Color(0xFFDDEBD7);

  String moodText = '';
  late final TextEditingController _moodController;
  late final TextEditingController _detailsController;
  final FocusNode _moodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isSaving = false;

  // 選擇（持久）+ 拖拉暫存（即時預覽）
  List<Map<String, dynamic>> _selectedEmotions = [];
  List<Map<String, dynamic>> _hoverTemp = const [];

  @override
  void initState() {
    super.initState();
    _moodController = TextEditingController(text: widget.moodText ?? '');
    _detailsController = TextEditingController(text: widget.details ?? '');
    moodText = widget.moodText ?? '';
    if (widget.emotions != null) {
      _selectedEmotions = widget.emotions!;
    }
    _moodController.addListener(_onAnyTextChanged);
    _detailsController.addListener(_onAnyTextChanged);
  }

  void _onAnyTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _moodController.removeListener(_onAnyTextChanged);
    _detailsController.removeListener(_onAnyTextChanged);
    _moodController.dispose();
    _detailsController.dispose();
    _moodFocusNode.dispose();
    _detailsFocusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (widget.isReadOnly) return false;
    final hasText =
        _moodController.text.trim().isNotEmpty ||
        _detailsController.text.trim().isNotEmpty;
    final hasEmotions = _selectedEmotions.isNotEmpty;
    return hasText || hasEmotions;
  }

  // ===== 背景色：若有 mixedColor 先用；否則用(選擇 + hover) 混色 =====
  Color _resolveBgColor() {
    final fromDb = widget.mixedColor?.trim() ?? '';
    if (fromDb.isNotEmpty) return _hexToColor(fromDb);

    // 沒有帶入就即時計算
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
    if (combined.isEmpty) return Colors.white;

    final hex = mixColorsWithAlpha(combined);
    if (hex.trim().isEmpty) return Colors.white;
    return _hexToColor(hex);
  }

  // 解析 '#RRGGBB' / '#AARRGGBB' / '0xAARRGGBB'
  Color _hexToColor(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bg = _resolveBgColor();

    final titleText = widget.isEnglish ? 'Current Feeling' : '現在的感受';
    final questionText = widget.isEnglish ? 'How do you feel now?' : '現在感覺如何呢？';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        color: bg, // ★ 這裡用動態背景
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final double ringSize = w * 0.52;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 自訂 AppBar
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

                    const SizedBox(height: 4),

                    // 六邊形選擇（支援拖拉即時預覽）
                    IgnorePointer(
                      ignoring: widget.isReadOnly,
                      child: EmotionHexSelector(
                        size: ringSize,
                        labels: const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
                        selections: _selectedEmotions,
                        onChanged: (temp) {
                          setState(() {
                            _hoverTemp = temp; // ★ 拖拉時讓背景跟著變
                          });
                        },
                        onCommit: (one) {
                          final i = _selectedEmotions.indexWhere(
                            (e) => e['emotion'] == one['emotion'],
                          );
                          if (i >= 0) {
                            _selectedEmotions[i] = one;
                          } else {
                            _selectedEmotions.add(one);
                          }
                          setState(() {
                            _hoverTemp = const []; // 放開後清除暫存
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 文字輸入卡片
                    _RoundedLinedCard(
                      background: _card,
                      lineColor: _lineWhite.withValues(alpha: 0.45),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      minHeight: 190,
                      maxHeight: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            questionText,
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: TextField(
                              controller: _moodController,
                              focusNode: _moodFocusNode,
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 18,
                                color: Colors.white,
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

                    const SizedBox(height: 16),

                    // 更多細節
                    _RoundedLinedCard(
                      background: _card.withValues(alpha: 0.92),
                      lineColor: _lineWhite.withValues(alpha: 0.35),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      minHeight: 120,
                      maxHeight: 160,
                      child: TextField(
                        controller: _detailsController,
                        focusNode: _detailsFocusNode,
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              widget.isEnglish
                                  ? 'More details (optional)'
                                  : '更多細節（可選）',
                          hintStyle: const TextStyle(
                            fontFamily: 'PixelFont',
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        enabled: !widget.isReadOnly && !_isSaving,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 完成
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed:
                            (!_canSubmit || _isSaving)
                                ? null
                                : () async {
                                  setState(() => _isSaving = true);

                                  void showErrorSnackBar(Object e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to save moment entry: $e',
                                        ),
                                      ),
                                    );
                                  }

                                  try {
                                    await _apiClient.saveDiaryEntry(
                                      date: widget.date,
                                      type: 'Moment',
                                      emotions: _selectedEmotions,
                                      mixedColor: null, // Moment 不存 mixedColor
                                      moodText: moodText,
                                      details: _detailsController.text,
                                      isEnglish: widget.isEnglish,
                                    );

                                    // ✅ 存檔成功後直接回到回顧頁（不觸發動畫）
                                    if (!context.mounted) return;
                                    Navigator.of(context).pushNamed(
                                      '/diary_review',
                                      arguments: const {'animate': false},
                                    );
                                  } catch (e) {
                                    if (kDebugMode) {
                                      // ignore: avoid_print
                                      print('Error saving moment entry: $e');
                                    }
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 有圓角 + 陰影 + 內部畫等距水平細線的卡片容器
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
    final double top = 44;
    final double gap = (size.height - top) / (lines + 1);

    for (int i = 1; i <= lines; i++) {
      final y = top + gap * i;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedBackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
