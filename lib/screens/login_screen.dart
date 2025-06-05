import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class LoginScreen extends StatefulWidget {
  final bool isEnglish;

  const LoginScreen({super.key, required this.isEnglish});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        if (mounted) {
          _showSnackBar(
            widget.isEnglish
                ? 'Email and password cannot be empty'
                : '郵箱和密碼不能為空',
          );
        }
        return;
      }
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user.displayName ?? user.email ?? 'User',
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      if (mounted) {
        _showSnackBar(widget.isEnglish ? 'An error occurred: $e' : '發生錯誤：$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            kIsWeb
                ? '483152981384-82gv1o0baejlppm0ouqj10ppdj56i7ov.apps.googleusercontent.com'
                : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user.displayName ?? user.email ?? 'User',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          widget.isEnglish ? 'Google login failed: $e' : 'Google 登入失敗: $e',
        );
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      // 檢查當前平台並設置適當的 loginBehavior
      final LoginBehavior loginBehavior =
          kIsWeb ? LoginBehavior.dialogOnly : LoginBehavior.nativeWithFallback;

      // 添加調試日誌以檢查平台和行為
      if (kDebugMode) {
        print("Platform: ${kIsWeb ? 'Web' : 'Mobile'}");
        print("Using loginBehavior: $loginBehavior");
      }

      // 執行 Facebook 登入
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginBehavior: loginBehavior,
      );

      // 詳細調試日誌
      if (kDebugMode) {
        print("Facebook login status: ${result.status}");
        print("Facebook login message: ${result.message}");
        print("Facebook accessToken: ${result.accessToken?.tokenString}");
        print("Full result: ${result.toString()}");
      }

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
        final User? user = userCredential.user;
        if (user != null && mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: user.displayName ?? user.email ?? 'User',
          );
        }
      } else {
        if (mounted) {
          _showDialog(
            'Facebook 登入失敗',
            'Status: ${result.status}\nMessage: ${result.message ?? "無錯誤訊息"}\n'
                'Platform: ${kIsWeb ? "Web" : "Mobile"}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Exception during Facebook login: $e");
      }
      if (mounted) {
        _showSnackBar(
          widget.isEnglish
              ? 'Error during Facebook login: $e'
              : 'Facebook 登入錯誤：$e',
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog<BuildContext>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(widget.isEnglish ? 'Reset Password' : '重置密碼'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: widget.isEnglish ? 'Enter your email' : '輸入您的郵箱',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(widget.isEnglish ? 'Cancel' : '取消'),
            ),
            TextButton(
              onPressed: () async {
                final String email = emailController.text.trim();
                if (email.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.isEnglish ? 'Email cannot be empty' : '郵箱不能為空',
                        ),
                      ),
                    );
                  }
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.isEnglish
                              ? 'Password reset email sent!'
                              : '密碼重置郵件已發送！',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(widget.isEnglish ? 'Error: $e' : '錯誤：$e'),
                      ),
                    );
                  }
                }
              },
              child: Text(widget.isEnglish ? 'Send' : '發送'),
            ),
          ],
        );
      },
    );
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage =
            widget.isEnglish ? 'No user found for that email.' : '找不到該郵箱的用戶。';
        break;
      case 'wrong-password':
        errorMessage = widget.isEnglish ? 'Incorrect password.' : '密碼錯誤。';
        break;
      case 'invalid-email':
        errorMessage = widget.isEnglish ? 'Invalid email format.' : '無效的郵箱格式。';
        break;
      default:
        errorMessage =
            widget.isEnglish
                ? 'Login failed: ${e.message}'
                : '登入失敗：${e.message}';
    }
    _showSnackBar(errorMessage);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.isEnglish ? 'Smaily 2' : 'Smaily 2',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Email' : '郵箱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Password' : '密碼',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: Text(widget.isEnglish ? 'Forget password?' : '忘記密碼？'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          widget.isEnglish ? 'Log In' : '登入',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(widget.isEnglish ? 'or' : '或'),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/register',
                  arguments: {'isEnglish': widget.isEnglish},
                );
              },
              child: Text(widget.isEnglish ? 'Sign Up' : '註冊'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _signInWithFacebook,
                  icon: Image.asset("assets/icons/fb.png", width: 40),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {},
                  icon: Image.asset("assets/icons/apple.png", width: 40),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset("assets/icons/google.png", width: 40),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
