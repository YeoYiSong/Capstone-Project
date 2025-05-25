import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smaily 2'),
        actions: [IconButton(icon: const Icon(Icons.timer), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.isEnglish
                  ? 'Hello~ ${widget.username} owo'
                  : '你好~${widget.username} owo',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  context,
                  widget.isEnglish ? 'My Day' : '我的一天',
                  Icons.book,
                  '/diary',
                ),
                _buildCircleButton(
                  context,
                  widget.isEnglish ? 'Breathing' : '呼吸',
                  Icons.self_improvement,
                  '/breathing',
                ),
                _buildCircleButton(
                  context,
                  'Smaily AI',
                  Icons.chat,
                  '/chatbot',
                ),
                _buildCircleButton(
                  context,
                  widget.isEnglish ? 'Diary' : '本子',
                  Icons.history,
                  '/diary_review',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(
                  context,
                  widget.isEnglish ? 'Home' : '首頁',
                  Icons.home,
                  '/home',
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                ),
                _buildBottomButton(context, 'Store', Icons.store, '/store'),
                _buildBottomButton(
                  context,
                  widget.isEnglish ? 'Settings' : '設定',
                  Icons.settings,
                  '/settings',
                ),
              ],
            ),
          ),
        ],
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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

  Widget _buildCircleButton(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(context, route);
          },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.8),
            ),
            child: Center(child: Icon(icon, size: 32, color: Colors.black)),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed:
          onPressed ??
          () {
            Navigator.pushNamed(context, route);
          },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.yellow),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}
