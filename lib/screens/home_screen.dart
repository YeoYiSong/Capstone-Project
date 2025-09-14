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
  String _displayName = '';

  // 色票（與你其他頁面一致）
  static const Color deepGreen = Color(0xFF2E5F3A);
  static const Color chipGreen = Color(0xFFB7C8B1);
  static const Color whiteOverlay = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchDisplayName();
  }

  Future<void> _fetchDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _displayName = widget.isEnglish ? 'Guest' : '訪客');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'firebase_uid': user.uid}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _displayName =
              data['name'] ??
              user.displayName ??
              user.email ??
              (widget.isEnglish ? 'User' : '使用者');
        });
      } else {
        setState(() {
          _displayName =
              user.displayName ??
              user.email ??
              (widget.isEnglish ? 'User' : '使用者');
        });
      }
    } catch (e) {
      setState(() {
        _displayName =
            user.displayName ??
            user.email ??
            (widget.isEnglish ? 'User' : '使用者');
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
    final greet = widget.isEnglish ? 'Good day, ' : '早安，';
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 頂部：問候 + 右上角 ⤡ ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$greet$_displayName',
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

                const SizedBox(height: 16),

                // ── 白綠半透明提示卡（記錄的好處） ──
                _BenefitCard(
                  title: widget.isEnglish ? 'Benefits of recording:' : '記錄的好處：',
                  body:
                      widget.isEnglish
                          ? 'Daily short notes help build self-observation and inner dialogue.'
                          : '每天簡單記錄，有助於建立自我觀察與內在對話的習慣。',
                  onIconPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.isEnglish ? 'Coming soon' : '更多功能即將推出！',
                        ),
                      ),
                    );
                  },
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
                      label: 'Smiley AI',
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
                      // Home（延用你原本：點擊觸發登出對話框）
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isEnglish ? 'Confirm Logout' : '確定要登出嗎？'),
          content: Text(
            widget.isEnglish ? 'Are you sure you want to logout?' : '您確定要登出嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.isEnglish ? 'Cancel' : '取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
              child: Text(widget.isEnglish ? 'Confirm' : '確定'),
            ),
          ],
        );
      },
    );
  }
}

/// —— 白綠半透明提示卡 ——
/// 左側：標題粗體深綠、內文深綠；右側：描邊方框小按鈕
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
                Icons.open_in_new,
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
