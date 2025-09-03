import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/doodle_stroke.dart'; // 這裡拿 EmotionHexRing
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import 'diary_saved_screen.dart';

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
  // 色票（貼近示意圖）
  static const Color _bg = Color(0xFFDDEBD7); // 背景淡綠
  static const Color _title = Color(0xFF2E5F3A); // 深綠標題
  static const Color _card = Color(0xFFB7C8B1); // 卡片綠
  static const Color _lineWhite = Color(0xFFFFFFFF); // 卡片內橫線（白，會用透明度）
  static const Color _btnEnabled = Color(0xFF2E5F3A); // 完成按鈕啟用（深綠）
  static const Color _btnDisabled = Color(0xFFDDEBD7); // 完成按鈕停用（淡綠）

  String moodText = '';
  late final TextEditingController _moodController;
  late final TextEditingController _detailsController;
  final FocusNode _moodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isSaving = false;

  // 先保留你的情緒選取資料結構（目前畫面不做互動選取，只展示六邊形樣式）
  List<Map<String, dynamic>> _selectedEmotions = [];

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

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEnglish ? 'Current Feeling' : '現在的感受';
    final questionText = widget.isEnglish ? 'How do you feel now?' : '現在感覺如何呢？';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 圓形返回鈕（貼近示意圖）
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
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          // 六邊形圈尺寸（依螢幕寬度，貼近示意圖比例）
          final double ringSize = w * 0.52; // 手機寬約 360~430 時視覺會接近參考圖
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // 六邊形情緒環（文字灰、線黑、中心用你的 interface_loading_circle.svg）
                EmotionHexSelector(
                  size: ringSize,
                  labels: const ['喜悅', '積極', '焦慮', '悲傷', '疲憊', '憤怒'],
                  selections: _selectedEmotions, // 👈 這行讓線條「持久顯示」
                  onChanged: (temp) {
                    // 需要即時預覽混色可在這裡算
                  },
                  onCommit: (one) {
                    final i = _selectedEmotions.indexWhere(
                      (e) => e['emotion'] == one['emotion'],
                    );
                    if (i >= 0) {
                      _selectedEmotions[i] = one; // 覆蓋強度
                    } else {
                      _selectedEmotions.add(one);
                    }
                    setState(() {}); // 觸發重畫，線就會留下來
                  },
                ),

                const SizedBox(height: 18),
                // 文字輸入卡片（圓角、陰影、內部有淺白橫線）
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
                          onChanged: (text) {
                            moodText = text;
                          },
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          enabled: !widget.isReadOnly && !_isSaving,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 你原本的「更多細節」欄位：藏在次要區，保持功能但外觀統一
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
                // 右下角的完成按鈕（膠囊狀）
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed:
                        (!_canSubmit || _isSaving)
                            ? null
                            : () async {
                              setState(() => _isSaving = true);

                              void navigateToSavedScreen() {
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DiarySavedScreen(
                                          isEnglish: widget.isEnglish,
                                          selectedEmotions: _selectedEmotions,
                                          mixedColor: mixColorsWithAlpha(
                                            _selectedEmotions,
                                          ),
                                        ),
                                  ),
                                );
                              }

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
                                  mixedColor:
                                      null, // Moment 不使用 mixedColor（沿用你原本註解）
                                  moodText: moodText,
                                  details: _detailsController.text,
                                  isEnglish: widget.isEnglish,
                                );
                                navigateToSavedScreen();
                              } catch (e) {
                                if (kDebugMode) {
                                  // ignore: avoid_print
                                  print('Error saving moment entry: $e');
                                }
                                showErrorSnackBar(e);
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit ? _btnEnabled : _btnDisabled,
                      foregroundColor:
                          _canSubmit ? Colors.white : const Color(0xFF9CB39F),
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

    // 畫 3~4 條等距的水平線（貼近示意圖）
    const int lines = 4;
    final double top = 44; // 留給標題或第一行文字
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
