import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String username;
  final void Function(bool)? onThemeChanged;
  final bool isEnglish;

  const HomeScreen({
    super.key,
    required this.username,
    this.onThemeChanged,
    this.isEnglish = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 只存「從後端/帳號拿到的原始名字」，不要把語系字樣存進 state
  String _rawName = '';
  bool _hasUser = false;

  // 目前顯示到第幾條好處
  int _benefitIndex = 0;

  // 色票（與你其他頁面一致）
  static const Color deepGreen = Color(0xFF2E5F3A);
  static const Color chipGreen = Color(0xFFB7C8B1);
  static const Color whiteOverlay = Colors.white;

  // —— 好處清單（中文：照你提供；英文：等義版，不直翻） ——
  static const List<String> _zhBenefits = [
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

  static const List<String> _enBenefits = [
    "Journaling helps you notice emotions and shifts—and understand yourself better.",
    "Putting thoughts and feelings into words clears the mind and eases pressure.",
    "A steady writing habit supports emotion regulation and long-term mental health.",
    "A diary holds your feelings and life moments, letting you see change and growth.",
    "Just a few lines a day builds self-observation and an inner dialogue.",
    "Writing is care—a gentle pause you give yourself.",
    "🌟 Write it down and feel lighter.\nGiving your feelings an outlet makes today’s heaviness easier to carry tomorrow.",
    "🌈 Your mood is a color palette.\nDaily notes let you paint your day—yellow for joy, blue for sadness, all welcome.",
    "🍃 Seal worries in a little diary jar.\nWhen thoughts feel tangled, writing helps them loosen and rest.",
    "🐾 Tiny mood footprints, day by day.\nEach note marks where you’ve been so you don’t lose your way.",
    "📖 Your diary is a small universe.\nLaugh, cry, space out—there’s no right or wrong, only the real you.💕",
    "🍭 What flavor is today’s mood?\nSweet, sour, or a bit bitter—write it down and know yourself a little more.",
    "🧸 Words you can’t say aloud can be whispered here.\nYour diary listens without interrupting. 💭",
    "🌕 Sometimes feelings just want to be seen.\nWriting opens a window so they can breathe. ✨",
    "🌱 Feelings need light and water too.\nJournaling is sunshine that helps them grow strong and gentle. 🌳",
    "📦 Tuck today’s feelings into a memory box.\nOne day you’ll look back and treasure these small stories.",
    "🎈 Moods have weather.\nSunny or stormy, writing is the umbrella you hold for yourself. ☔️",
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (widget.isEnglish) {
      if (hour >= 5 && hour < 12) return 'Good morning, ';
      if (hour >= 12 && hour < 18) return 'Good afternoon, ';
      return 'Good evening, ';
    } else {
      if (hour >= 5 && hour < 12) return '早安，';
      if (hour >= 12 && hour < 18) return '午安，';
      return '晚安，';
    }
  }

  String get _currentBenefit {
    final list = widget.isEnglish ? _enBenefits : _zhBenefits;
    if (list.isEmpty) return '';
    final i = _benefitIndex % list.length;
    return list[i];
  }

  void _nextBenefit() {
    setState(() {
      final len = widget.isEnglish ? _enBenefits.length : _zhBenefits.length;
      _benefitIndex = (_benefitIndex + 1) % len;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchDisplayName();
  }

  Future<void> _fetchDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    _hasUser = user != null;

    if (user == null) {
      setState(() => _rawName = '');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'firebase_uid': user.uid}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rawName = (data['name'] ?? user.displayName ?? user.email ?? '');
        });
      } else {
        setState(() {
          _rawName = (user.displayName ?? user.email ?? '');
        });
      }
    } catch (_) {
      if (!mounted) return;
      final u = FirebaseAuth.instance.currentUser;
      setState(() {
        _rawName = (u?.displayName ?? u?.email ?? '');
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final greet = _greeting();

    // 這裡才依 isEnglish 即時決定顯示名稱
    final String displayName = () {
      if (_rawName.isNotEmpty) return _rawName;
      if (_hasUser) return widget.isEnglish ? 'User' : '使用者';
      return widget.isEnglish ? 'Guest' : '訪客';
    }();

    return Scaffold(
      // 讓背景圖能延伸到狀態列下
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, // 背後鋪底，避免圖片載入瞬間閃白
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.07,
              20,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 頂部：問候 + 右上角 ⤡ ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$greet$displayName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: deepGreen,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pushNamed(context, '/scenario'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: deepGreen, width: 1.4),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '⤡',
                          style: TextStyle(
                            fontSize: 20,
                            color: deepGreen,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── 白綠半透明提示卡（記錄的好處，按右側按鈕切換下一條） ──
                _BenefitCard(
                  title: widget.isEnglish ? 'Benefits of recording:' : '記錄的好處：',
                  body: _currentBenefit,
                  onIconPressed: _nextBenefit,
                ),

                const Spacer(),

                // ── 四個圓形功能按鈕 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeatureCircle(
                      label: widget.isEnglish ? 'My Day' : '我的一天',
                      icon: Icons.edit_note,
                      onTap: () => Navigator.pushNamed(context, '/diary'),
                    ),
                    _FeatureCircle(
                      label: widget.isEnglish ? 'Breathing' : '呼吸',
                      icon: Icons.self_improvement,
                      onTap: () => Navigator.pushNamed(context, '/breathing'),
                    ),
                    _FeatureCircle(
                      label: 'Breasy AI',
                      icon: Icons.chat_bubble_outline,
                      onTap: () => Navigator.pushNamed(context, '/chatbot'),
                    ),
                    _FeatureCircle(
                      label: widget.isEnglish ? 'Diary' : '本子',
                      icon: Icons.menu_book_outlined,
                      onTap:
                          () => Navigator.pushNamed(context, '/diary_review'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── 底部半透明底欄 ──
                Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: whiteOverlay.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home（點擊觸發登出對話框）
                      IconButton(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(
                          Icons.home_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/store'),
                        icon: const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/settings'),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final en = widget.isEnglish;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(en ? 'Confirm Logout' : '確定要登出嗎？'),
          content: Text(en ? 'Are you sure you want to logout?' : '您確定要登出嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(en ? 'Cancel' : '取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
              child: Text(en ? 'Confirm' : '確定'),
            ),
          ],
        );
      },
    );
  }
}

/// —— 白綠半透明提示卡 ——
/// 左側：標題粗體深綠、內文深綠；右側：描邊方框小按鈕（按下切換下一條）
class _BenefitCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onIconPressed;

  const _BenefitCard({
    required this.title,
    required this.body,
    required this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: const Offset(0, 8),
            blurRadius: 18,
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
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _HomeScreenState.deepGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: _HomeScreenState.deepGreen,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onIconPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _HomeScreenState.deepGreen,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.open_in_new, // 維持你的圖示，不更動其它邏輯
                color: _HomeScreenState.deepGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// —— 圓形功能按鈕（淡綠圓底、白圖示、像素字標籤） ——
class _FeatureCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCircle({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _HomeScreenState.chipGreen.withValues(alpha: 0.72),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Center(child: Icon(icon, size: 34, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 16,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
