import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'dart:convert';
import 'package:http/http.dart' as http; // ✅ 共用 http client
import '/network/http_client.dart'; // ✅ 我們的跨平台工廠
import '/utils/config.dart';

// ✅ 非阻塞地啟動推薦
import 'dart:async' show unawaited;

// 登入後要啟動推薦
import '../utils/recommendation_manager.dart';

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

  // ---------------- 共用：登入成功後做的事 ----------------
  Future<void> _afterLogin(User user, int userId) async {
    if (kDebugMode) {
      print(
        '[Login] userId=$userId, uid=${user.uid} -> kickoff recommendation (background)',
      );
    }
    // 背景啟動，不阻塞導頁
    unawaited(RecommendationManager.instance.kickoffAfterLogin());

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'name': user.displayName ?? user.email ?? 'User',
        'userId': userId,
        'uid': user.uid,
      },
    );
  }

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

      final UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final User? user = cred.user;
      if (user != null && mounted) {
        final int? userId = await _fetchUserId(user.uid);
        if (userId != null) {
          await _afterLogin(user, userId);
        }
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
        final int? userId = await _fetchUserId(user.uid);
        if (userId != null) {
          await _afterLogin(user, userId);
        }
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
      final LoginBehavior loginBehavior =
          kIsWeb ? LoginBehavior.dialogOnly : LoginBehavior.nativeWithFallback;

      if (kDebugMode) {
        print("Platform: ${kIsWeb ? 'Web' : 'Mobile'}");
        print("Using loginBehavior: $loginBehavior");
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginBehavior: loginBehavior,
      );

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
          final int? userId = await _fetchUserId(user.uid);
          if (userId != null) {
            await _afterLogin(user, userId);
          }
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

  // ✅ 跨平台 http client；Web 會自動 withCredentials，行動端用 IO client
  Future<int?> _fetchUserId(String firebaseUid) async {
    final http.Client client = createHttpClient(withCredentials: true);
    try {
      final response = await client
          .post(
            Uri.parse('${getBaseUrl()}/get_user_id'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'firebase_uid': firebaseUid}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('[Login] fetched user_id=${data['user_id']} from backend');
        }
        return data['user_id'] is int
            ? data['user_id'] as int
            : int.tryParse('${data['user_id']}');
      } else {
        _showSnackBar(
          widget.isEnglish
              ? 'Failed to fetch user ID from backend (HTTP ${response.statusCode})'
              : '無法從後端獲取使用者 ID（HTTP ${response.statusCode}）',
        );
        return null;
      }
    } catch (e) {
      _showSnackBar(widget.isEnglish ? 'Error: $e' : '錯誤：$e');
      return null;
    } finally {
      client.close();
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
              onPressed: () => Navigator.pop(dialogContext),
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

  // Widget _circleIconButton({
  //   required Widget icon,
  //   required VoidCallback? onPressed,
  //   EdgeInsetsGeometry padding = const EdgeInsets.all(6),
  // }) {
  //   return InkWell(
  //     onTap: onPressed,
  //     customBorder: const CircleBorder(),
  //     child: Container(
  //       padding: padding,
  //       decoration: BoxDecoration(
  //         color: Colors.white.withValues(alpha: 0.18),
  //         shape: BoxShape.circle,
  //         border: Border.all(
  //           color: Colors.white.withValues(alpha: 0.7),
  //           width: 1.4,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.18),
  //             blurRadius: 6,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: icon,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // ----- 文案 -----
    final String title = widget.isEnglish ? 'Log In' : '登入';
    final String emailLabel = widget.isEnglish ? 'Email' : 'Email:';
    final String pwdLabel = widget.isEnglish ? 'Password' : 'Password:';
    final String quick = widget.isEnglish ? 'Quick Login' : '快速登入';
    final String firstTimeQ =
        widget.isEnglish ? 'First time here? ' : '第一次使用嗎？';
    final String signupHere = widget.isEnglish ? 'Sign up here' : '在此註冊';

    // ----- 讓版面分散些的比例留白（小螢幕會自動可捲動） -----
    final double h = MediaQuery.of(context).size.height;
    final double topSpace = h * 0.12;
    final double midSpace = h * 0.08;
    final double bottomSpace = h * 0.10;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖
          Image.asset('assets/picture/bg.jpg', fit: BoxFit.cover),
          // 深色遮罩：讓背景暗淡（用 withValues）
          Container(color: Colors.black.withValues(alpha: 0.42)),

          // 內容
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topSpace),

                      // 標題
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Email（膠囊）
                      SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: _pillDecoration(
                            label: emailLabel,
                            hint:
                                widget.isEnglish
                                    ? 'Enter your email'
                                    : '輸入你的電子郵件',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password（膠囊 + 右側箭頭）
                      SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: _pillDecoration(
                            label: pwdLabel,
                            hint:
                                widget.isEnglish
                                    ? 'Enter your password'
                                    : '輸入你的密碼',
                          ).copyWith(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : IconButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : _signInWithEmail,
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 56,
                              minHeight: 56,
                            ),
                          ),
                        ),
                      ),

                      // 忘記密碼（靠右）
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: Text(
                            widget.isEnglish ? 'Forget password?' : '忘記密碼？',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),

                      SizedBox(height: midSpace),

                      // 快速登入（置中）
                      Center(
                        child: Column(
                          children: [
                            Text(
                              quick,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap:
                                      _isLoading ? null : _signInWithFacebook,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Image.asset(
                                      "assets/icons/fb.png",
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                GestureDetector(
                                  onTap: _isLoading ? null : _signInWithGoogle,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Image.asset(
                                      "assets/icons/google.png",
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 底部註冊連結（藍色底線）
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              firstTimeQ,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/register',
                                  arguments: {'isEnglish': widget.isEnglish},
                                );
                              },
                              child: Text(
                                signupHere,
                                style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: bottomSpace),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
