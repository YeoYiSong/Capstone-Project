import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDarkTheme;
  final void Function(bool) onThemeChanged;
  final bool isEnglish;
  final void Function(bool) onLanguageChanged;
  final bool isDiaryLocked;
  final void Function(bool, {String? password}) onDiaryLockChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.isEnglish,
    required this.onLanguageChanged,
    required this.isDiaryLocked,
    required this.onDiaryLockChanged,
  });

  void _showPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEnglish ? 'Set Diary Password' : '設定本子密碼'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: isEnglish ? 'Enter password' : '輸入密碼',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDiaryLockChanged(false);
              },
              child: Text(isEnglish ? 'Cancel' : '取消'),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.isNotEmpty) {
                  onDiaryLockChanged(true, password: password);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEnglish ? 'Password cannot be empty' : '密碼不能為空',
                      ),
                    ),
                  );
                }
              },
              child: Text(isEnglish ? 'Confirm' : '確認'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEnglish ? 'Settings' : '設定')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            ListTile(title: Text(isEnglish ? 'Account' : '帳戶')),
            ListTile(
              title: Text(isEnglish ? 'Change Phone' : '更換電話'),
              onTap: () {},
            ),
            ListTile(
              title: Text(isEnglish ? 'Password Settings' : '密碼設定'),
              onTap: () {},
            ),
            ListTile(
              title: Text(isEnglish ? 'Theme (Light/Dark)' : '主題（明/暗）'),
              trailing: Switch(
                value: isDarkTheme,
                onChanged: (value) {
                  onThemeChanged(value);
                },
              ),
            ),
            ListTile(
              title: Text(isEnglish ? 'Language (Ch/En)' : '語言（中/英）'),
              trailing: Switch(
                value: isEnglish,
                onChanged: (value) {
                  onLanguageChanged(value);
                },
              ),
            ),
            ListTile(
              title: Text(isEnglish ? 'Notification Settings' : '通知設定'),
              onTap: () {},
            ),
            ListTile(
              title: Text(isEnglish ? 'Diary Password Lock' : '本子密碼鎖'),
              trailing: Switch(
                value: isDiaryLocked,
                onChanged: (value) {
                  if (value) {
                    _showPasswordDialog(context);
                  } else {
                    onDiaryLockChanged(false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
