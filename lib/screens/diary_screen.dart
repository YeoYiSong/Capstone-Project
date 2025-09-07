import 'package:flutter/material.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';

class DiaryScreen extends StatelessWidget {
  final bool isEnglish;

  const DiaryScreen({super.key, this.isEnglish = false});

  // 純色（無透明，避免「蒙」）
  static const Color arrowText = Colors.black87; // 箭頭選項
  static const Color cardBg = Color(0xFFE7EBE6); // 底部卡片實色灰
  static const Color cardTextSub = Colors.black54;
  static const double horizPad = 20;

  @override
  Widget build(BuildContext context) {
    final titleText = isEnglish ? 'My Day' : '我的一天';
    final headingText = isEnglish ? 'I want to record' : '我想記錄';
    final momentText = isEnglish ? '-> Moment Feelings' : '-> 當下的感受';
    final dayText = isEnglish ? '-> Day Feelings' : '-> 整天的感受';
    final benefitTitle = isEnglish ? 'Benefits of recording:' : '記錄的好處：';
    final benefitBody =
        isEnglish
            ? 'Daily short notes help build self-observation and inner dialogue.'
            : '每天簡單記錄，有助於建立自我觀察與內在對話的習慣。';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 以螢幕高做比例：上區塊 : 下卡片 ≈ 82:18
              final bottomCardHeight = constraints.maxHeight * 0.18;

              return Column(
                children: [
                  // ── 自訂 AppBar ──
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 28,
                            fontWeight: FontWeight.bold, // 加粗
                            color: Colors.black, // 加深
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 中央內容 ──
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              headingText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 40,
                                fontWeight: FontWeight.bold, // 加粗
                                color: Colors.black, // 加深
                              ),
                            ),
                            const SizedBox(height: 28),
                            _ArrowOption(
                              text: momentText,
                              color: arrowText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MomentFeelingsScreen(
                                          isEnglish: isEnglish,
                                          date: DateTime.now(),
                                        ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _ArrowOption(
                              text: dayText,
                              color: arrowText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DayFeelingsScreen(
                                          isEnglish: isEnglish,
                                          date: DateTime.now(),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 底部卡片 ──
                  SizedBox(
                    height: bottomCardHeight,
                    width: double.infinity,
                    child: _BenefitCard(
                      title: benefitTitle,
                      body: benefitBody,
                      onAddPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEnglish ? 'Coming soon' : '更多功能即將推出！',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 箭頭式選項
class _ArrowOption extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ArrowOption({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'PixelFont',
          fontSize: 36,
          height: 1.2,
          color: color,
        ),
      ),
    );
  }
}

/// 底部提示卡片
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
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: DiaryScreen.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 6),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold, // 加粗
                    color: Colors.black, // 加深
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: DiaryScreen.cardTextSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右側方框 icon
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black87, width: 1.2),
              ),
              child: const Icon(Icons.add, color: Colors.black87, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
