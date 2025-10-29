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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 底部卡片高度範圍（避免溢出，內容超過改在卡片內捲動）
              final double maxBottomCardH = (constraints.maxHeight * 0.28)
                  .clamp(120.0, 240.0);
              const double minBottomCardH = 100;

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
                            fontSize: 38, // ⬆ 放大
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
                                fontSize: 32, // ⬆ 放大
                                fontWeight: FontWeight.bold,
                                color: deepGreen,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _ArrowOption(
                              text: momentText,
                              color: deepGreen,
                              fontSize: 32, // ⬆ 放大
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
                              fontSize: 32, // ⬆ 放大
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

                  // ── 底部卡片（貼底、內容長時在卡片內捲動） ──
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minBottomCardH,
                      maxHeight: maxBottomCardH,
                    ),
                    child: _RotatingBenefitCard(
                      title: benefitTitle,
                      isEnglish: isEnglish,
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
  final double fontSize;
  final VoidCallback onTap;

  const _ArrowOption({
    required this.text,
    required this.color,
    required this.onTap,
    this.fontSize = 22,
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
          fontSize: fontSize,
          height: 1.3,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 可點擊切換「記錄的好處」內容（在同一張卡片內輪播）
class _RotatingBenefitCard extends StatefulWidget {
  final String title;
  final bool isEnglish;

  const _RotatingBenefitCard({required this.title, required this.isEnglish});

  @override
  State<_RotatingBenefitCard> createState() => _RotatingBenefitCardState();
}

class _RotatingBenefitCardState extends State<_RotatingBenefitCard> {
  int _index = 0;

  // 中文（無任何中括號）
  static const List<String> _zh = [
    '記錄心情有助於更清楚得覺察情緒與變化，建立對自己的理解與認識。',
    '透過日記整理當下的想法與感受，有助於釐清思緒與減輕心理壓力。',
    '穩定的書寫習慣能促進情緒調節，並支持長期的心理健康。',
    '日記是情緒的記錄，也是生活的痕跡，幫助你看見自己的變化與成長。',
    '每天簡單記錄，有助於建立自我觀察與內在對話的習慣。',
    '記錄本身就是一種照顧，一種停下來的練習。',
    '🌟寫下來，心情就不那麼重了！\n記錄情緒，就像幫心事找到出口。今天的不開心，寫一寫，明天就變輕了！',
    '🌈你的心情，是彩虹調色盤！\n每天寫日記，就是幫自己配色。開心是黃色、悲傷是藍色，通通都能畫進你的一天裡！',
    '🍃把煩惱放進日記瓶裡封存起來吧！\n寫日記像是收納情緒的盒子，心亂時寫一寫，心就不再打結了！',
    '🐾情緒小腳印，每天一點點！\n一點一滴地記下心情，就像在地圖上標記生活的足跡，讓你不迷路～',
    '📖日記是屬於你的小宇宙\n想笑、想哭、想發呆，都可以寫進去！這裡沒有對錯，只有你最真實的樣子💕',
    '🍭今天的心情是什麼味道呢？\n甜甜的？酸酸的？還是有點苦？寫進日記裡，讓你每天都更認識自己一點點🍬',
    '🧸不說出口的話，可以悄悄寫下來喔～\n日記永遠不會打斷你，靜靜地陪你說完每一句 💭',
    '🌕有時候，情緒只是想被看見\n寫下你的心情，就像替情緒開了一扇窗，讓它呼吸一下✨',
    '🌱心情也需要澆水、曬太陽\n日記就像陽光一樣，讓你的情緒慢慢長成堅強又溫柔的小樹🌳',
    '📦今天的感受，放進記憶寶盒裡吧！\n每一篇日記，都是屬於你的小故事，有一天回看會覺得很珍貴！',
    '🎈心情也會變天氣喔～\n晴天、陰天、打雷天氣都沒關係，記下來，就是陪自己一起撐傘的小勇氣 ☔️',
  ];

  // 英文等義版（自然口吻，不逐字）
  static const List<String> _en = [
    'Journaling helps you notice emotions and shifts—and understand yourself better.',
    'Putting thoughts and feelings into words clears the mind and eases pressure.',
    'A steady writing habit supports emotion regulation and long-term mental health.',
    'A diary holds your feelings and life moments, letting you see change and growth.',
    'Just a few lines a day builds self-observation and an inner dialogue.',
    'Writing is care—a gentle pause you give yourself.',
    '🌟 Write it down and feel lighter.\nGiving your feelings an outlet makes today’s heaviness easier to carry tomorrow.',
    '🌈 Your mood is a color palette.\nDaily notes let you paint your day—yellow for joy, blue for sadness, all welcome.',
    '🍃 Seal worries in a little diary jar.\nWhen thoughts feel tangled, writing helps them loosen and rest.',
    '🐾 Tiny mood footprints, day by day.\nEach note marks where you’ve been so you don’t lose your way.',
    '📖 Your diary is a small universe.\nLaugh, cry, space out—there’s no right or wrong, only the real you.💕',
    '🍭 What flavor is today’s mood?\nSweet, sour, or a bit bitter—write it down and know yourself a little more.',
    '🧸 Words you can’t say aloud can be whispered here.\nYour diary listens without interrupting. 💭',
    '🌕 Sometimes feelings just want to be seen.\nWriting opens a window so they can breathe. ✨',
    '🌱 Feelings need light and water too.\nJournaling is sunshine that helps them grow strong and gentle. 🌳',
    '📦 Tuck today’s feelings into a memory box.\nOne day you’ll look back and treasure these small stories.',
    '🎈 Moods have weather.\nSunny or stormy, writing is the umbrella you hold for yourself. ☔️',
  ];

  void _next() {
    final listLen = widget.isEnglish ? _en.length : _zh.length;
    setState(() => _index = (_index + 1) % listLen);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.isEnglish ? _en : _zh;
    final body = items[_index];

    return _BenefitCard(
      title: widget.title,
      body: body,
      scrollable: true, // 內容長在卡片內可捲動
      onAddPressed: _next, // 按右側方框切換下一條
    );
  }
}

/// 底部提示卡片（綠底、深綠文字、右側方框外連 icon）
/// scrollable=true 時，文字區超過高度會在卡片內部可捲動，不會溢出。
class _BenefitCard extends StatelessWidget {
  final String title;
  final String body;
  final bool scrollable;
  final VoidCallback onAddPressed;

  const _BenefitCard({
    required this.title,
    required this.body,
    required this.onAddPressed,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: DiaryScreen.deepGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 14,
            color: DiaryScreen.deepGreen,
          ),
        ),
      ],
    );

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
          // 左側文字（需要時可捲動）
          Expanded(
            child:
                scrollable
                    ? LayoutBuilder(
                      builder:
                          (context, c) => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: c.maxHeight,
                              ),
                              child: textColumn,
                            ),
                          ),
                    )
                    : textColumn,
          ),
          const SizedBox(width: 10),
          // 右側方框按鈕（點擊輪播下一條）
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
                Icons.open_in_new, // 保持你的原圖示
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
