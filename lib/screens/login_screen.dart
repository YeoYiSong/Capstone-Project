import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEnglish
                    ? 'Email and password cannot be empty'
                    : '郵箱和密碼不能為空',
              ),
            ),
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
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage =
            widget.isEnglish ? 'No user found for that email.' : '找不到該郵箱的用戶。';
      } else if (e.code == 'wrong-password') {
        errorMessage = widget.isEnglish ? 'Incorrect password.' : '密碼錯誤。';
      } else if (e.code == 'invalid-email') {
        errorMessage = widget.isEnglish ? 'Invalid email format.' : '無效的郵箱格式。';
      } else {
        errorMessage =
            widget.isEnglish
                ? 'Login failed: ${e.message}'
                : '登入失敗：${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'An error occurred: $e' : '發生錯誤：$e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      if (googleUser == null) {
        return;
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Google login failed: $e' : 'Google 登入失敗: $e',
            ),
          ),
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
                  onPressed: () {},
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
