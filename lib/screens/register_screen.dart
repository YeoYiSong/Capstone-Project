import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  final bool isEnglish;

  const RegisterScreen({super.key, required this.isEnglish});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // ---------- Auth ----------
  Future<void> _registerWithEmail() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Email and password cannot be empty'
                  : '電子郵件與密碼不能為空',
            ),
          ),
        );
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      final user = cred.user;
      if (user != null) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user.displayName ?? user.email ?? 'User',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg =
              widget.isEnglish ? 'The email is already in use.' : '該電子郵件已被使用。';
          break;
        case 'invalid-email':
          msg = widget.isEnglish ? 'Invalid email format.' : '電子郵件格式無效。';
          break;
        case 'weak-password':
          msg = widget.isEnglish ? 'The password is too weak.' : '密碼太弱。';
          break;
        default:
          msg =
              widget.isEnglish
                  ? 'Registration failed: ${e.message}'
                  : '註冊失敗：${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'An error occurred: $e' : '發生錯誤：$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      UserCredential cred;
      if (kIsWeb) {
        cred = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        final google = GoogleSignIn();
        final account = await google.signIn();
        if (account == null) return;
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      final user = cred.user;
      if (user != null) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user.displayName ?? user.email ?? 'User',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Google registration failed: $e'
                  : 'Google 註冊失敗：$e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  InputDecoration _pillDecoration({
    required String label,
    required String hint,
  }) {
    const pillRadius = 28.0;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.white60),
      filled: true,
      // 半透明白，疊在背景上（使用 withValues）
      fillColor: Colors.white.withValues(alpha: 0.16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: const BorderSide(color: Color(0xFF91D5FF), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEnglish ? 'Sign Up' : '註冊';
    final emailLabel = widget.isEnglish ? 'Email' : '電子郵件';
    final pwdLabel = widget.isEnglish ? 'Password' : '密碼';
    final quick = widget.isEnglish ? 'Quick Sign Up' : '快速註冊';
    final haveAcc = widget.isEnglish ? 'Already have an account? ' : '已經有帳號了？';
    final login = widget.isEnglish ? 'Log in' : '點我登入';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖
          Image.asset('assets/picture/bg.jpg', fit: BoxFit.cover),
          // 深色遮罩：讓背景暗淡（用 withValues）
          Container(
            color: Colors.black.withValues(alpha: 0.42), // 想更暗：0.50；更亮：0.30
          ),

          // 內容
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- 電子郵件 ----------
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: _pillDecoration(
                      label: emailLabel,
                      hint: widget.isEnglish ? 'Enter your email' : '輸入你的電子郵件',
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ---------- 密碼 ----------
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: _pillDecoration(
                      label: pwdLabel,
                      hint: widget.isEnglish ? 'Enter your password' : '輸入你的密碼',
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ---------- 圓形箭頭按鈕 + 文案 ----------
                  Column(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerWithEmail,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            elevation: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            shadowColor: Colors.black26,
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.4,
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quick,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // ---------- Google 按鈕 ----------
                  IconButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Image.asset("assets/icons/google.png", width: 40),
                    tooltip: 'Google',
                  ),

                  const SizedBox(height: 16),

                  // ---------- 登入連結 ----------
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        haveAcc,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          login,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
