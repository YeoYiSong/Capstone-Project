import 'package:flutter/material.dart';
import 'diary_review_screen.dart';

class DiaryLockedScreen extends StatefulWidget {
  final String diaryPassword;
  final bool isEnglish;

  const DiaryLockedScreen({
    super.key,
    required this.diaryPassword,
    this.isEnglish = false,
  });

  @override
  State<DiaryLockedScreen> createState() => _DiaryLockedScreenState();
}

class _DiaryLockedScreenState extends State<DiaryLockedScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordIncorrect = false;

  void _verifyPassword(BuildContext context) {
    if (_passwordController.text == widget.diaryPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => DiaryReviewScreen(
                isDiaryLocked: false,
                isEnglish: widget.isEnglish,
              ),
        ),
      );
    } else {
      setState(() {
        _isPasswordIncorrect = true;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEnglish ? 'Locked Diary' : '本子已鎖定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isEnglish
                  ? 'Please enter the password to unlock your diary'
                  : '請輸入密碼以解鎖你的本子',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Enter password' : '輸入密碼',
                border: const OutlineInputBorder(),
                errorText:
                    _isPasswordIncorrect
                        ? (widget.isEnglish ? 'Incorrect password' : '密碼錯誤')
                        : null,
              ),
              onSubmitted: (_) => _verifyPassword(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _verifyPassword(context),
              child: Text(widget.isEnglish ? 'Unlock' : '解鎖'),
            ),
          ],
        ),
      ),
    );
  }
}
