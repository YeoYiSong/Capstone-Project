import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/emotion_hex_selector.dart';
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import '../utils/recommendation_manager.dart';
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
  static const Color _bgTop = Color(0xFFEAF6E9);
  static const Color _bgBottom = Color(0xFFD7EBDD);

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

  // 本頁專用的 ScaffoldMessenger，避免提示跨頁殘留
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _alreadyRecorded = false;
  bool _checkDone = false;
  bool _bannerShown = false;

  final List<String> _prompts = [];
  final List<String> _chinesePrompts = const [
    '今天有什麼讓你感到開心的事？',
    '有沒有什麼讓你感到壓力的事件？',
    '今天你學到了什麼新東西？',
    '你今天和誰有過特別的互動？',
    '有沒有什麼讓你感到意外的事情？',
    '今天的某個時刻讓你感到放鬆嗎？',
    '你今天有沒有完成什麼重要的任務？',
    '有什麼讓你感到挫折的瞬間？',
    '今天的天氣如何影響你的心情？',
    '你今天有沒有什麼特別的靈感或想法？',
  ];
  final List<String> _englishPrompts = const [
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

  List<Map<String, dynamic>> _selectedEmotions = [];
  List<Map<String, dynamic>> _hoverTemp = const [];

  bool get _isLocked => widget.isReadOnly || _alreadyRecorded;

  static const Map<String, String> _aliasToKeyLower = {
    '喜悅': 'joy',
    '積極': 'positive',
    '焦慮': 'anxious',
    '悲傷': 'sad',
    '疲憊': 'tired',
    '憤怒': 'angry',
    'joy': 'joy',
    'positive': 'positive',
    'anxious': 'anxious',
    'anxiety': 'anxious',
    'sad': 'sad',
    'sadness': 'sad',
    'tired': 'tired',
    'exhaust': 'tired',
    'angry': 'angry',
    'anger': 'angry',
  };

  static const Map<String, String> _keyToChinese = {
    'joy': '喜悅',
    'positive': '積極',
    'anxious': '焦慮',
    'sad': '悲傷',
    'tired': '疲憊',
    'angry': '憤怒',
  };

  String _toKey(String label) {
    final raw = (label).toString().trim();
    final key = _aliasToKeyLower[raw.toLowerCase()];
    return key ?? raw.toLowerCase();
  }

  List<Map<String, dynamic>> _normalizeForMix(List<Map<String, dynamic>> list) {
    return list.map((e) {
      final raw = (e['emotion'] ?? '').toString();
      final key = _toKey(raw);
      final cn = _keyToChinese[key] ?? raw;
      return {...e, 'emotion': cn};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _rebuildPrompts(fromEnglish: widget.isEnglish);
    _currentPromptIndex = Random().nextInt(_prompts.length);
    _moodController = TextEditingController(text: widget.moodText ?? '');
    _detailsController = TextEditingController(text: widget.details ?? '');
    moodText = widget.moodText ?? '';
    if (widget.emotions != null) {
      _selectedEmotions = widget.emotions!;
    }
    _moodController.addListener(_onAnyChanged);
    _detailsController.addListener(_onAnyChanged);

    if (!widget.isReadOnly) {
      unawaited(_checkAlreadyRecorded());
    } else {
      _checkDone = true;
    }
  }

  @override
  void dispose() {
    _moodController.removeListener(_onAnyChanged);
    _detailsController.removeListener(_onAnyChanged);
    _moodController.dispose();
    _detailsController.dispose();
    _moodFocusNode.dispose();
    _detailsFocusNode.dispose();

    _scaffoldMessengerKey.currentState?.clearMaterialBanners();
    ScaffoldMessenger.maybeOf(context)?.clearMaterialBanners();

    super.dispose();
  }

  Future<void> _checkAlreadyRecorded() async {
    try {
      final DateTime d = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      );
      final bool has = await _apiClient.hasDiaryForDate(date: d, type: 'Day');

      if (!mounted) return;
      setState(() {
        _alreadyRecorded = has;
        _checkDone = true;
      });

      if (has) {
        _clearBanners();
        await _showAlreadyDialogAndPop();
      } else {
        _showOneTimeBanner();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alreadyRecorded = false;
        _checkDone = true;
      });
      if (kDebugMode) {
        // ignore: avoid_print
        print('checkAlreadyRecorded error: $e');
      }
      _showOneTimeBanner();
    }
  }

  void _showOneTimeBanner() {
    if (_bannerShown || !mounted) return;
    _bannerShown = true;

    final text = widget.isEnglish
        ? 'You can only write today’s all-day feelings once.'
        : '提醒：整日的感受一天只能寫一次喔。';

    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: _bgBottom,
        content: Text(
          text,
          style: const TextStyle(fontFamily: 'PixelFont', color: _title),
        ),
        actions: [
          TextButton(
            onPressed: _clearBanners,
            child: Text(widget.isEnglish ? 'OK' : '知道了'),
          ),
        ],
      ),
    );
    // 不自動關閉，停在本頁可等待點擊才消失；切到別頁時此 messenger 一併銷毀。
  }

  void _clearBanners() {
    final messenger =
        _scaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentMaterialBanner();
    messenger?.clearMaterialBanners();
  }

  Future<void> _showAlreadyDialogAndPop() async {
    if (!mounted) return;
    final title = widget.isEnglish ? 'Already Recorded' : '已完成今日記錄';
    final msg = widget.isEnglish
        ? 'You have already recorded today’s all-day feelings. Come back tomorrow!'
        : '今日已經記錄了哦~~ 明天再來吧！';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isEnglish ? 'OK' : '好'),
          ),
        ],
      ),
    );

    _clearBanners();
    if (mounted) Navigator.maybePop(context);
  }

  @override
  void didUpdateWidget(covariant DayFeelingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      _rebuildPrompts(fromEnglish: widget.isEnglish);
      _currentPromptIndex = Random().nextInt(_prompts.length);
      setState(() {});
    }
  }

  void _rebuildPrompts({required bool fromEnglish}) {
    _prompts
      ..clear()
      ..addAll(fromEnglish ? _englishPrompts : _chinesePrompts);
  }

  void _onAnyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _switchPrompt() {
    if (!_isLocked) {
      setState(() {
        _currentPromptIndex = Random().nextInt(_prompts.length);
      });
    }
  }

  bool get _canSubmit {
    if (_isLocked) return false;
    final hasText =
        _moodController.text.trim().isNotEmpty ||
        _detailsController.text.trim().isNotEmpty;
    final hasEmotions = _selectedEmotions.isNotEmpty;
    return hasText || hasEmotions;
  }

  Color _computeCenterColor() {
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
      if (combined.isEmpty) return Colors.transparent;

      final normalized = _normalizeForMix(combined);
      final String hex = mixColorsWithAlpha(normalized);
      if (hex.trim().isEmpty) return Colors.transparent;
      return _hexToColor(hex);
    } catch (_) {
      return Colors.transparent;
    }
  }

  Color _hexToColor(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final val = int.parse(s, radix: 16);
    return Color(val);
  }

  @override
  Widget build(BuildContext context) {
    final Color centerColor = (() {
      final s = widget.mixedColor?.trim() ?? '';
      if (s.isNotEmpty) return _hexToColor(s);
      return _computeCenterColor();
    })();

    final titleText = widget.isEnglish ? 'Day Feelings' : '整天的感受';
    final promptTitle = widget.isEnglish ? 'Reflect on Today' : '回顧一下今天吧';
    final whyText = widget.isEnglish ? 'Why do you feel this day?' : '整天感覺如何呢？';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    final ringLabels = widget.isEnglish
        ? const ['Joy', 'Positive', 'Anxious', 'Sad', 'Tired', 'Angry']
        : const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'];

    if (!_checkDone) {
      return ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgBottom],
              ),
            ),
            child: const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final double ringSize = w * 0.52;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
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
                          const Spacer(),
                          if (_alreadyRecorded)
                            const Icon(Icons.lock, color: _title, size: 20),
                        ],
                      ),

                      const SizedBox(height: 12),

                      IgnorePointer(
                        ignoring: _isLocked,
                        child: Opacity(
                          opacity: _isLocked ? 0.5 : 1.0,
                          child: EmotionHexSelector(
                            size: ringSize,
                            labels: ringLabels,
                            selections: _selectedEmotions,
                            centerFillColor: centerColor,
                            onChanged: (temp) {
                              setState(() => _hoverTemp = temp);
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
                              setState(() => _hoverTemp = const []);
                            },
                          ),
                        ),
                      ),

                      if (!_isLocked) ...[
                        SizedBox(height: constraints.maxHeight < 700 ? 20 : 36),
                        Align(
                          alignment: Alignment.center,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedEmotions = [];
                                _hoverTemp = const [];
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _title,
                              side: const BorderSide(color: _title, width: 1.2),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
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
                        SizedBox(height: constraints.maxHeight < 700 ? 16 : 24),
                      ],

                      Center(
                        child: InkWell(
                          onTap: _isLocked ? null : _switchPrompt,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  promptTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 20,
                                    color: _title,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: Text(
                                    _prompts[_currentPromptIndex],
                                    key: ValueKey(_currentPromptIndex),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 18,
                                      color: _title,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

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
                                  color: _title,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: _isLocked
                                      ? (widget.isEnglish
                                            ? 'Already recorded today.'
                                            : '今天已經填寫過囉。')
                                      : '',
                                ),
                                onChanged: (text) => moodText = text,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                enabled: !_isLocked && !_isSaving,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (!_isLocked)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: (!_canSubmit || _isSaving)
                                ? null
                                : () async {
                                    setState(() => _isSaving = true);

                                    try {
                                      final normalizedForSave =
                                          _normalizeForMix(_selectedEmotions);
                                      final mixedColorWithAlpha =
                                          mixColorsWithAlpha(normalizedForSave);

                                      final Map<String, double> emotionMap = {
                                        'joy': 0,
                                        'sad': 0,
                                        'angry': 0,
                                        'positive': 0,
                                        'anxious': 0,
                                        'tired': 0,
                                      };

                                      for (final emotion in _selectedEmotions) {
                                        final raw = (emotion['emotion'] ?? '')
                                            .toString();
                                        final key = _toKey(raw);
                                        final v =
                                            (double.tryParse(
                                                      '${emotion['intensity']}',
                                                    ) ??
                                                    0)
                                                .clamp(0, 100)
                                                .toDouble();
                                        if (emotionMap.containsKey(key)) {
                                          emotionMap[key] = v;
                                        }
                                      }

                                      await _apiClient.saveDiaryEntry(
                                        date: widget.date,
                                        type: 'Day',
                                        emotions: normalizedForSave,
                                        mixedColor: mixedColorWithAlpha,
                                        moodText: moodText,
                                        details: _detailsController.text,
                                        isEnglish: widget.isEnglish,
                                        joy: emotionMap['joy'] ?? 0,
                                        sadness: emotionMap['sad'] ?? 0,
                                        anger: emotionMap['angry'] ?? 0,
                                        positive: emotionMap['positive'] ?? 0,
                                        anxiety: emotionMap['anxious'] ?? 0,
                                        exhaust: emotionMap['tired'] ?? 0,
                                      );

                                      RecommendationManager.instance
                                          .refreshAfterEntrySaved(
                                            savedDate: widget.date,
                                            isDay: true,
                                          );

                                      if (!context.mounted) return;
                                      setState(() => _alreadyRecorded = true);

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
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            widget.isEnglish
                                                ? 'You have already recorded today.'
                                                : '今日已經記錄了哦~~',
                                          ),
                                        ),
                                      );
                                      setState(() => _alreadyRecorded = true);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canSubmit
                                  ? _btnEnabled
                                  : _bgBottom,
                              foregroundColor: _canSubmit
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
    final paint = Paint()
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
