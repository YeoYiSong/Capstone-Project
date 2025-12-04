import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 新增：用來鎖定螢幕方向
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/diary_review_screen.dart';
import 'screens/store_screen.dart';
import 'screens/scenario_mode_screen.dart';
import '/utils/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 全 app 鎖定為「直式」顯示（只允許 portraitUp）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // 如果你想允許倒過來直式（手機顛倒）可以再加：
    // DeviceOrientation.portraitDown,
  ]);

  // 初始化 Facebook Auth（僅限 Web）
  if (kIsWeb) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "9566947040053985",
      cookie: true,
      xfbml: true,
      version: "v19.0",
    );
  }

  // 初始化 Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 初始化日期格式
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('zh_CN', null);

  // 初始化 ApiClient，自動配置 baseUrl
  await ApiClient.initialize();

  runApp(const Smaily2App());
}

class Smaily2App extends StatefulWidget {
  const Smaily2App({super.key});

  @override
  State<Smaily2App> createState() => _Smaily2AppState();
}

class _Smaily2AppState extends State<Smaily2App> {
  bool _isEnglish = false;
  bool _isDiaryLocked = false;
  String? _diaryPassword;

  void _toggleLanguage(bool isEnglish) {
    setState(() {
      _isEnglish = isEnglish;
    });
  }

  void _toggleDiaryLock(bool isLocked, {String? password}) {
    setState(() {
      _isDiaryLocked = isLocked;
      if (isLocked && password != null) {
        _diaryPassword = password;
      } else if (!isLocked) {
        _diaryPassword = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smaily',
      // ✅ 固定使用淺色主題
      theme: ThemeData(
        fontFamily: 'PixelFont',
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      locale: _isEnglish ? const Locale('en', 'US') : const Locale('zh', 'CN'),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/login': (context) => LoginScreen(isEnglish: _isEnglish),
        '/register': (context) => RegisterScreen(isEnglish: _isEnglish),
        '/home': (context) =>
            HomeScreen(username: 'jiuke', isEnglish: _isEnglish),
        '/diary': (context) => DiaryScreen(isEnglish: _isEnglish),
        '/chatbot': (context) => ChatbotScreen(isEnglish: _isEnglish),
        '/breathing': (context) => BreathingScreen(isEnglish: _isEnglish),
        '/settings': (context) => SettingsScreen(
          isEnglish: _isEnglish,
          onLanguageChanged: _toggleLanguage,
          isDiaryLocked: _isDiaryLocked,
          onDiaryLockChanged: _toggleDiaryLock,
        ),
        '/diary_review': (context) => DiaryReviewScreen(
          isDiaryLocked: _isDiaryLocked,
          diaryPassword: _diaryPassword,
          isEnglish: _isEnglish,
        ),
        '/store': (context) => StoreScreen(isEnglish: _isEnglish),
        '/scenario': (context) => ScenarioModeScreen(isEnglish: _isEnglish),
      },
    );
  }
}
