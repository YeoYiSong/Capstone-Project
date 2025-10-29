import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final PageController _controller;
  int _index = 0; // 0..2: 引導, 3: Go 頁
  double _dragDx = 0.0; // 手勢方向

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool fromNotification = arguments?['fromNotification'] == true;
    final bool isEnglish = arguments?['isEnglish'] == true;

    if (fromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      });
    }

    // 第1~3頁文案
    final List<String> lines =
        isEnglish
            ? const [
              'Pause,\nlisten to your inner voice.',
              'A little journaling and breathing each day,\nnourish your heart.',
              'Let healing,\nbecome part of everyday life.',
            ]
            : const [
              '停下來，\n聽見自己內心的聲音。',
              '每天一點記錄與呼吸，\n滋養你的心。',
              '讓療癒，\n成為日常的一部分。',
            ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 手勢控制：只允許右->左前進；在第4頁滑動不動作
          GestureDetector(
            onHorizontalDragStart: (_) => _dragDx = 0.0,
            onHorizontalDragUpdate: (d) => _dragDx += d.primaryDelta ?? 0.0,
            onHorizontalDragEnd: (_) {
              if (_dragDx < -40) _goNext();
              _dragDx = 0.0;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                if (i <= 2) {
                  // ===== 第1~3頁：全螢幕背景 + 遮罩 + 文案（水平垂直置中，280×58）=====
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/picture/bg.jpg', fit: BoxFit.cover),
                      Container(color: Colors.black.withValues(alpha: 0.42)),
                      Center(
                        child: SizedBox(
                          width: 280, // Figma: 280
                          height: 58, // Figma: 58
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              lines[i],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                              style: TextStyle(
                                height: 1.3,
                                fontSize: 28, // 由 FittedBox 控制縮放
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.92),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // ===== 第4頁：背景也用 bg.jpg（無漸層），保留內容 + Go 按鈕 =====
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/picture/bg.jpg', fit: BoxFit.cover),
                      Container(color: Colors.black.withValues(alpha: 0.42)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 80,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Text(
                              isEnglish
                                  ? "Feel the moment,\nheal every moment."
                                  : "感受當下，\n療癒每一刻。",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.92),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              "Breasy",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                    arguments: {'isEnglish': isEnglish},
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Go",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // 底部三顆圓形指示器（第4頁隱藏）— 尺寸 15×15
          if (_index < 3)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final bool active = _index == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            active
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.transparent,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.6,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
