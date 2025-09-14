import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/doodle_stroke.dart';
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import '../utils/recommendation_manager.dart';
// ✅ 新增：讓背景任務不阻塞 UI
import 'dart:async' show unawaited;

class DayFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final bool isReadOnly;
  final List<Map<String, dynamic>>? emotions;
  final String? mixedColor;
  final String? moodText;
  final String? details;

  const DayFeelingsScreen({
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
  DayFeelingsScreenState createState() => DayFeelingsScreenState();
}

class DayFeelingsScreenState extends State<DayFeelingsScreen> {
  // 固定用色（卡片/標題/線條/按鈕）
  static const Color _title = Color(0xFF2E5F3A);
  static const Color _card = Color(0xFFB7C8B1);
  static const Color _lineWhite = Color(0xFFFFFFFF);
  static const Color _btnEnabled = Color(0xFF2E5F3A);

  String moodText = '';
  late final TextEditingController _moodController;
  late final TextEditingController _detailsController;
  final FocusNode _moodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isSaving = false;

  final List<String> _prompts = [];
  final List<String> _chinesePrompts = [
    '今天有什麼讓你感到開心的事？',
    '有沒有什麼讓你感到壓力的事件？',
    '今天你學到了什麼新東西？',
    '你今天和誰有過特別的互動？',
    '有什麼讓你感到意外的事情嗎？',
    '今天的某個時刻讓你感到放鬆嗎？',
    '你今天有沒有完成什麼重要的任務？',
    '有什麼讓你感到挫折的瞬間？',
    '今天的天氣如何影響你的心情？',
    '你今天有沒有什麼特別的靈感或想法？',
  ];
  final List<String> _englishPrompts = [
    'What made you happy today?',
    'Was there anything stressful today?',
    'What new thing did you learn today?',
    'Who did you have a special interaction with today?',
    'Was there anything surprising today?',
    'Did you have a relaxing moment today?',
    'Did you complete any important tasks today?',
    'Was there a moment that frustrated you?',
    'How did the weather affect your mood today?',
    'Did you have any special inspirations or ideas today?',
  ];
  int _currentPromptIndex = 0;

  // 已選情緒（持久）
  List<Map<String, dynamic>> _selectedEmotions = [];
  // 拖拉中的暫時選擇（用於即時背景預覽）
  List<Map<String, dynamic>> _hoverTemp = const [];

  @override
  void initState() {
    super.initState();
    _prompts.addAll(widget.isEnglish ? _englishPrompts : _chinesePrompts);
    _currentPromptIndex = Random().nextInt(_prompts.length);
    _moodController = TextEditingController(text: widget.moodText ?? '');
    _detailsController = TextEditingController(text: widget.details ?? '');
    moodText = widget.moodText ?? '';
    if (widget.emotions != null) {
      _selectedEmotions = widget.emotions!;
    }
    _moodController.addListener(_onAnyChanged);
    _detailsController.addListener(_onAnyChanged);
  }

  void _onAnyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _moodController.removeListener(_onAnyChanged);
    _detailsController.removeListener(_onAnyChanged);
    _moodController.dispose();
    _detailsController.dispose();
    _moodFocusNode.dispose();
    _detailsFocusNode.dispose();
    super.dispose();
  }

  void _switchPrompt() {
    if (!widget.isReadOnly) {
      setState(() {
        _currentPromptIndex = Random().nextInt(_prompts.length);
      });
    }
  }

  bool get _canSubmit {
    if (widget.isReadOnly) return false;
    final hasText =
        _moodController.text.trim().isNotEmpty ||
        _detailsController.text.trim().isNotEmpty;
    final hasEmotions = _selectedEmotions.isNotEmpty;
    return hasText || hasEmotions;
  }

  // —— 背景色計算：預設白色；合併目前選擇＋拖拉預覽，丟給混色工具 —— //
  Color _computeBgColor() {
    try {
      final combined = <Map<String, dynamic>>[];
      combined.addAll(
        _selectedEmotions.map((e) => Map<String, dynamic>.from(e)),
      );
      if (_hoverTemp.isNotEmpty) {
        final temp = _hoverTemp.first;
        final idx = combined.indexWhere((e) => e['emotion'] == temp['emotion']);
        if (idx >= 0) {
          combined[idx] = temp;
        } else {
          combined.add(temp);
        }
      }
      if (combined.isEmpty) return Colors.white;

      final String hex = mixColorsWithAlpha(combined);
      if (hex.trim().isEmpty) return Colors.white;
      return _hexToColor(hex);
    } catch (_) {
      return Colors.white;
    }
  }

  /// 若有 DB 帶入的 mixedColor，優先用它；否則才用即時計算
  Color _resolveBgColor() {
    final s = widget.mixedColor?.trim() ?? '';
    if (s.isNotEmpty) return _hexToColor(s);
    return _computeBgColor();
  }

  // 解析 '#RRGGBB' / '#AARRGGBB' / '0xAARRGGBB'
  Color _hexToColor(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s'; // 無 alpha 就補 FF
    final val = int.parse(s, radix: 16);
    return Color(val);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _resolveBgColor(); // 先用 mixedColor（唯讀模式也能顯示正確顏色）

    final titleText = widget.isEnglish ? 'Day Feelings' : '整天的感受';
    final promptTitle = widget.isEnglish ? 'Reflect on Today' : '回顧一下今天吧';
    final whyText =
        widget.isEnglish ? 'Why do you feel this way?' : '為什麼有這種情緒？';
    final moreText = widget.isEnglish ? 'More details (optional)' : '更多細節（可選）';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        color: bg, // 背景色
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final double ringSize = w * 0.52;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // AppBar
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

                    const SizedBox(height: 12),

                    // 六邊形（互動）
                    IgnorePointer(
                      ignoring: widget.isReadOnly,
                      child: EmotionHexSelector(
                        size: ringSize,
                        labels: const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
                        selections: _selectedEmotions,
                        onChanged: (temp) {
                          setState(() {
                            _hoverTemp = temp;
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
                            _hoverTemp = const [];
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 提示語卡片
                    _RoundedLinedCard(
                      background: _card,
                      lineColor: _lineWhite.withValues(alpha: 0.45),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      minHeight: 84,
                      maxHeight: 120,
                      child: InkWell(
                        onTap: widget.isReadOnly ? null : _switchPrompt,
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promptTitle,
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (child, anim) => FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  ),
                              child: Text(
                                _prompts[_currentPromptIndex],
                                key: ValueKey(_currentPromptIndex),
                                style: const TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 主要敘述卡片
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
                            whyText,
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

                    // 次要細節卡片
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
                          hintText: moreText,
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

                    if (!widget.isReadOnly)
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to save day entry: $e',
                                          ),
                                        ),
                                      );
                                    }

                                    try {
                                      final mixedColorWithAlpha =
                                          mixColorsWithAlpha(_selectedEmotions);

                                      final Map<String, double> emotionMap = {
                                        'joy': 0,
                                        'sadness': 0,
                                        'anger': 0,
                                        'positive': 0,
                                        'anxiety': 0,
                                        'exhaust': 0,
                                      };

                                      for (final emotion in _selectedEmotions) {
                                        final key =
                                            (emotion['emotion'] as String)
                                                .toLowerCase();
                                        final v = (double.tryParse(
                                                  '${emotion['intensity']}',
                                                ) ??
                                                0)
                                            .clamp(0, 100);
                                        if (emotionMap.containsKey(key)) {
                                          emotionMap[key] = v.toDouble();
                                        }
                                      }

                                      await _apiClient.saveDiaryEntry(
                                        date: widget.date,
                                        type: 'Day',
                                        emotions: _selectedEmotions,
                                        mixedColor: mixedColorWithAlpha,
                                        moodText: moodText,
                                        details: _detailsController.text,
                                        isEnglish: widget.isEnglish,
                                        joy: emotionMap['joy']!,
                                        sadness: emotionMap['sadness']!,
                                        anger: emotionMap['anger']!,
                                        positive: emotionMap['positive']!,
                                        anxiety: emotionMap['anxiety']!,
                                        exhaust: emotionMap['exhaust']!,
                                      );

                                      // ✅ 存檔成功後：在背景觸發/重觸發推薦，不阻塞跳頁
                                      unawaited(
                                        RecommendationManager.instance
                                            .maybeRefreshAfterDaySaved(
                                              widget.date,
                                            ),
                                      );

                                      if (!context.mounted) return;
                                      Navigator.of(context).pushNamed(
                                        '/diary_review',
                                        arguments: {
                                          'animate': true,
                                          'date': widget.date,
                                          'color': mixedColorWithAlpha,
                                        },
                                      );
                                    } catch (e) {
                                      if (kDebugMode) {
                                        // ignore: avoid_print
                                        print('Error saving day entry: $e');
                                      }
                                      showErrorSnackBar(e);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isSaving = false);
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit ? _btnEnabled : bg,
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

/// 圓角陰影卡片 + 內部水平線
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
