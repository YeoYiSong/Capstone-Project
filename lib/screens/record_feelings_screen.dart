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
  // 色系（與你前面頁面一致）
  static const Color _bg = Color(0xFFDDEBD7);
  static const Color _title = Color(0xFF2E5F3A);
  static const Color _card = Color(0xFFB7C8B1);
  static const Color _line = Color(0xFF6C8A6F);
  static const Color _btnEnabled = Color(0xFF2E5F3A);
  static const Color _btnDisabled = Color(0xFFDDEBD7);
  static const Color _btnDisabledText = Color(0xFF9CB39F);

  late final TextEditingController _feelingsController;
  final FocusNode _feelingsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

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
    final titleText = widget.isEnglish ? 'Take-time Record' : '花點時間紀錄';
    final hintText = widget.isEnglish ? 'Write how you feel…' : '我覺得整個人都慢了下來';
    final benefitTitle = widget.isEnglish ? 'Benefits of recording:' : '記錄的好處：';
    final benefitBody =
        widget.isEnglish
            ? 'Daily short notes help build self-observation and inner dialogue.'
            : '每天簡單記錄，有助於建立自我觀察與內在對話的習慣。';
    final doneText = widget.isEnglish ? 'Done' : '完成';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            // 內容
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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

                  // 四條水平線輸入區（第一行放提示）
                  _LinedTextarea(
                    controller: _feelingsController,
                    focusNode: _feelingsFocusNode,
                    lineColor: _line,
                    hint: hintText,
                  ),

                  // 中間留白，與圖一致
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),

                  // 底部卡片：記錄的好處
                  _BenefitCard(
                    title: benefitTitle,
                    body: benefitBody,
                    onAddPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isEnglish ? 'Coming soon' : '之後會加入更多功能喔！',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 底部大按鈕
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
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
                        ),
                        child: Text(
                          doneText,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                          ),
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
    final double width =
        MediaQuery.of(context).size.width - 40; // 20+20 padding
    return SizedBox(
      width: width,
      child: CustomPaint(
        painter: _LinesPainter(lineColor),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 16,
              color: RecordFeelingsScreenState._title,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                color: RecordFeelingsScreenState._title,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Color color;
  _LinesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2;

    // 四條線，間距按圖比例
    final double left = 4;
    final double right = size.width - 4;
    // 第一條線稍靠上，留出提示字高度
    final double top = 32;
    final double gap = 44;

    for (int i = 0; i < 4; i++) {
      final y = top + i * gap;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// —— 底部「記錄的好處」卡片＋右側加號 ——
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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 加號按鈕（外有細方框、圓角大一點）
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
