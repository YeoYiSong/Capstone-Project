import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';
import 'home_screen.dart';

class RecordFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final int duration;
  final String userId;
  final int min;

  const RecordFeelingsScreen({
    super.key,
    required this.isEnglish,
    required this.date,
    required this.duration,
    required this.userId,
    required this.min,
  });

  @override
  RecordFeelingsScreenState createState() => RecordFeelingsScreenState();
}

class RecordFeelingsScreenState extends State<RecordFeelingsScreen> {
  // 色系（與整體風格一致）
  static const Color _bg = Color(0xFFDDEBD7);
  static const Color _title = Color(0xFF2E5F3A);
  static const Color _card = Color(0xFFB7C8B1);
  static const Color _line = Color(0xFF6C8A6F);
  static const Color _btnEnabled = Color(0xFF2E5F3A);
  static const Color _btnDisabled = Color(0xFFDDEBD7);
  static const Color _btnDisabledText = Color(0xFF9CB39F);

  // 葉子插畫
  static const String _leafAsset = 'assets/picture/fullleaf.png';

  late final TextEditingController _feelingsController;
  final FocusNode _feelingsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

  // —— 呼吸引導提示（中英對齊）——
  final List<String> _tipsZh = const [
    '呼吸練習是一種不需外力、隨時可以進行的自我照顧方式。',
    '將注意力放在呼吸，是一種簡單有效的身心調節練習。',
    '透過專注呼吸，可以提升對身體與情緒的覺察。',
    '練習慢下來的呼吸，有助於身體進入較為平靜的狀態。',
    '🌬️ 鼻子吸、鼻子吐～呼吸才會真正有魔法！小秘密：用鼻子呼吸，能保護身體、加強氣流，身體最喜歡這種節奏啦！',
    '🦷 嘴巴呼吸不只讓喉嚨乾巴巴，還會偷偷製造蛀牙危機！保持鼻呼吸，才能讓你的口腔和呼吸道都過得舒舒服服的～',
    '🍃 專心在呼吸上，雜念就會悄悄溜走～不需要硬把念頭趕走，只要靜靜觀察呼吸，它們就會像泡泡一樣自己飄遠囉～',
    '🧘‍♀️ 呼～慢慢來，副交感神經正在幫你開啟放鬆模式！一呼一吸之間，你的身體開始安靜下來，心跳也跟著說：「我放輕鬆了～」',
    '💗 深深吸氣，輕輕吐氣～現在的你，正在照顧自己。每一次慢呼吸，都是對自己的溫柔擁抱！',
    '🎈 只要呼吸對了，整個人都對了！從呼吸開始，身心也會慢慢變得輕盈起來✨',
    '🌬️ 空氣不是只「吸」進去的，更是身體的大餐喔！你知道嗎？每天我們都在吃空氣～吸得好，才會吃得營養、活得健康！',
    '🚨 現代人太會呼吸了（？）但不是好事喔～過度呼吸會讓身體亂了節奏！放慢一點點，才是關鍵✨',
  ];

  final List<String> _tipsEn = const [
    'Breathing practice is self-care you can do anytime, without any external tools.',
    'Placing attention on the breath is a simple and effective way to regulate body and mind.',
    'By focusing on your breathing, you enhance awareness of your body and emotions.',
    'Practicing slower breaths helps your body settle into a calmer state.',
    '🌬️ Inhale through your nose, exhale through your nose—that’s where the magic is! Secret: nasal breathing protects your airways and smooths airflow—your body loves that rhythm.',
    '🦷 Mouth breathing can dry your throat and even raise the risk of cavities. Keep breathing through your nose to keep your mouth and airways comfy.',
    '🍃 When you stay with the breath, stray thoughts quietly slip away. No need to push them out—just watch your breathing and let them drift like bubbles.',
    '🧘‍♀️ Easy does it—your parasympathetic system is switching on relax mode. With each inhale and exhale your body settles, and your heartbeat says, “I’m easing up.”',
    '💗 Deep inhale, gentle exhale—you’re caring for yourself right now. Every slow breath is a soft hug to you.',
    '🎈 Get the breath right, and everything follows. Start with breathing, and your body and mind will grow lighter.',
    '🌬️ Air isn’t just inhaled—it’s a feast for the body. We “eat” air every day; breathe well to nourish and live well!',
    '🚨 Many of us over-breathe—not a good thing. Over-breathing disrupts your rhythm; slowing down a little is the key.',
  ];

  // —— 切換提示索引（＋號按鈕用）——
  int _tipIndex = 0;
  List<String> get _tips => widget.isEnglish ? _tipsEn : _tipsZh;
  void _nextTip() {
    setState(() {
      _tipIndex = (_tipIndex + 1) % _tips.length;
    });
  }

  bool get _canSubmit =>
      !_isLoading && _feelingsController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _feelingsController = TextEditingController();
    _feelingsController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _saveBreathRecord() async {
    if (_feelingsController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Please enter your feelings' : '請輸入你的感受',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiClient.saveBreathRecord(
        userId: widget.userId,
        duration: widget.duration,
        min: widget.min,
        feeling: _feelingsController.text.trim(),
        type: '引導',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish ? 'Breath record saved successfully!' : '呼吸記錄已儲存！',
          ),
        ),
      );
      // 儲存成功後直接回首頁
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HomeScreen(username: 'User', isEnglish: widget.isEnglish),
        ),
        (route) => false,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error saving breath record: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to save breath record: $e'
                  : '儲存呼吸記錄失敗：$e',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    _feelingsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 第二標題英文：自然好懂，鼓勵動手記下
    final titleText =
        widget.isEnglish ? 'Take a moment to write it down' : '花點時間紀錄';

    final hintText =
        widget.isEnglish
            ? 'e.g.: It feels like the world has slowed with me.'
            : 'e.g.: 我覺得整個人都慢了下來';

    // 把提示塞到「記錄的好處」卡片：顯示單一提示（無進度）
    final String benefitTitle = widget.isEnglish ? 'Breath tips:' : '呼吸小提醒：';
    final String benefitBody = '• ${_tips[_tipIndex]}';

    final doneText = widget.isEnglish ? 'Done' : '完成';

    return Scaffold(
      backgroundColor: _bg,
      // AppBar：帶返回鍵（與你的其他頁一致）
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          widget.isEnglish ? 'Record Feelings' : '記錄呼吸感受',
          style: const TextStyle(color: _title, fontWeight: FontWeight.w800),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: widget.isEnglish ? 'Back' : '返回',
            onPressed: () => Navigator.maybePop(context),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _title, width: 1.4),
              ),
              child: const Icon(Icons.arrow_back, color: _title, size: 18),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 內容可上下滑動
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 28,
                      color: _title,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4 條線輸入區（文字永遠在「線上面」）
                  _LinedTextarea(
                    controller: _feelingsController,
                    focusNode: _feelingsFocusNode,
                    lineColor: _line.withValues(alpha: 0.85),
                    hint: hintText,
                  ),

                  const SizedBox(height: 24),

                  // 底部卡片：呼吸小提醒（原「記錄的好處」位置）
                  _BenefitCard(
                    title: benefitTitle,
                    body: benefitBody,
                    onAddPressed: _nextTip, // ＋號按鈕：切換下一則
                  ),

                  const SizedBox(height: 16),

                  // 滿版葉子插畫（fitWidth）
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      _leafAsset,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),

            // 底部單一按鈕「完成」（儲存並回首頁）
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _saveBreathRecord : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _canSubmit ? _btnEnabled : _btnDisabled,
                            foregroundColor:
                                _canSubmit ? Colors.white : _btnDisabledText,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            shape: const StadiumBorder(),
                            elevation: _canSubmit ? 2 : 0,
                            textStyle: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                            ),
                          ),
                          child: Text(doneText),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// —— 有 4 條線的輸入框，第一行顯示提示 ——
/// 用 TextPainter 量測行高，讓每條線畫在「文字下一點」，不會穿過字。
class _LinedTextarea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color lineColor;
  final String hint;

  const _LinedTextarea({
    required this.controller,
    required this.focusNode,
    required this.lineColor,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    // 字體加大、加深
    const inputStyle = TextStyle(
      fontFamily: 'PixelFont',
      fontSize: 19,
      height: 1.35,
      color: RecordFeelingsScreenState._title,
      fontWeight: FontWeight.w700,
    );

    // 用來量測單行高度
    final tp = TextPainter(
      text: const TextSpan(text: 'A', style: inputStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineHeight = tp.preferredLineHeight;

    // 線的位置與間距：跟著字高自動推
    const topPad = 8.0; // TextField 內距上
    final firstLineTop = topPad + lineHeight + 8;
    final gap = lineHeight + 16; // 間距拉鬆
    final totalHeight = firstLineTop + (3 * gap) + 8;

    return SizedBox(
      height: totalHeight,
      width: MediaQuery.of(context).size.width - 40, // 外側 20+20
      child: Stack(
        children: [
          // 底層：四條線
          Positioned.fill(
            child: CustomPaint(
              painter: _LinesPainter(
                color: lineColor.withValues(alpha: 0.85),
                firstLineTop: firstLineTop,
                gap: gap,
                count: 4,
                horizontalPadding: 4,
              ),
            ),
          ),
          // 上層：文字輸入（永遠在「線的上面」）
          Padding(
            padding: const EdgeInsets.fromLTRB(4, topPad, 4, 8),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: inputStyle.copyWith(
                  color: RecordFeelingsScreenState._title.withValues(
                    alpha: 0.6,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 4, // 正好對齊 4 條線
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Color color;
  final double firstLineTop;
  final double gap;
  final int count;
  final double horizontalPadding;

  _LinesPainter({
    required this.color,
    required this.firstLineTop,
    required this.gap,
    required this.count,
    required this.horizontalPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2;

    final double left = horizontalPadding;
    final double right = size.width - horizontalPadding;

    for (int i = 0; i < count; i++) {
      final y = firstLineTop + i * gap;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) {
    return old.color != color ||
        old.firstLineTop != firstLineTop ||
        old.gap != gap ||
        old.count != count ||
        old.horizontalPadding != horizontalPadding;
  }
}

/// —— 底部「記錄的好處」卡片＋右側加號（＋＝切換下一則） ——
class _BenefitCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onAddPressed;

  const _BenefitCard({
    required this.title,
    required this.body,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: RecordFeelingsScreenState._card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文案
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右側＋號：切下一則
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.4,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
