import 'package:flutter/material.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';

class DiaryScreen extends StatelessWidget {
  final bool isEnglish;

  const DiaryScreen({super.key, this.isEnglish = false});

  // 綠系設計
  static const Color bg = Color(0xFFDDEBD7); // 背景淡綠
  static const Color deepGreen = Color(0xFF2E5F3A); // 文字/邊線深綠
  static const Color cardBg = Color(0xFFB7C8B1); // 卡片綠
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
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 版面比例：上方內容填滿、底部卡片固定高度貼底
              final double bottomCardHeight = 96;

              return Column(
                children: [
                  // ── 自訂 AppBar（左圓框返回 + 深綠標題） ──
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
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: deepGreen, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: deepGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: deepGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 中央內容：主標 + 兩個箭頭選項（深綠） ──
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: deepGreen,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _ArrowOption(
                              text: momentText,
                              color: deepGreen,
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
                              color: deepGreen,
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

                  // ── 底部卡片（貼底、圓角、右側方框 icon） ──
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
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 箭頭式選項（深綠）
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
          fontSize: 22,
          height: 1.3,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 底部提示卡片（綠底、深綠文字、右側方框外連 icon）
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
          // 左側文字
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
                    color: DiaryScreen.deepGreen, // 深綠
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    fontWeight: FontWeight.normal, // 一般
                    color: DiaryScreen.deepGreen, // 深綠
                  ),
                ),
              ],
            ),
          ),
          // 右側方框按鈕
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DiaryScreen.deepGreen, width: 1.4),
              ),
              child: const Icon(
                Icons.open_in_new,
                color: DiaryScreen.deepGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
