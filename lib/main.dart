import 'package:flutter/material.dart'; //引用material的設計套件

void main() {
  runApp(SmailyApp());
}

class SmailyApp extends StatelessWidget {
  const SmailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smaily',
      theme: ThemeData(primarySwatch: Colors.blue),
      // 根據 Use Case 文件規劃路由
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/diary': (context) => DiaryScreen(),
        '/recommendation': (context) => RecommendationScreen(),
        '/chatbot': (context) => ChatbotScreen(),
        '/breathing': (context) => BreathingScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

// ===== 登入頁面 (Use Case 1: 註冊與登入) =====
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登入')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('登入表單'),
              ElevatedButton(
                onPressed: () {
                  // 模擬登入成功後導向主畫面
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('登入'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('還沒有帳號？註冊'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 註冊頁面 =====
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('註冊')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/register.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('註冊表單 (Email、密碼、Google/Apple 快速登入)'),
              ElevatedButton(
                onPressed: () {
                  // 註冊成功後導向主畫面
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('註冊'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 主畫面 =====
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smaily 2 主畫面'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/home.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            ListTile(
              title: Text('我的一天 (日記)'),
              onTap: () {
                Navigator.pushNamed(context, '/diary');
              },
            ),
            ListTile(
              title: Text('精油與練習推薦'),
              onTap: () {
                Navigator.pushNamed(context, '/recommendation');
              },
            ),
            ListTile(
              title: Text('聊天機器人'),
              onTap: () {
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
            ListTile(
              title: Text('呼吸練習'),
              onTap: () {
                Navigator.pushNamed(context, '/breathing');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 日記頁面 (Use Case 2) =====
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的一天')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/diary.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('此刻你的心情如何？'),
              TextField(decoration: InputDecoration(hintText: '請輸入心情描述')),
              SizedBox(height: 20),
              Text('今天讓你感到最溫暖的事情是什麼？'),
              TextField(decoration: InputDecoration(hintText: '請輸入感恩事項')),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 提交日記後導向推薦頁面
                  Navigator.pushNamed(context, '/recommendation');
                },
                child: Text('提交日記'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 精油與練習推薦頁面 (Use Case 3) =====
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('推薦')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/recommendation.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('AI 分析結果：'),
              Text('今日建議使用薰衣草精油搭配 5 分鐘冥想'),
              ElevatedButton(
                onPressed: () {
                  // 若有連結購買頁面，這裡可以導向購買頁面
                },
                child: Text('了解更多'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 聊天機器人頁面 (Use Case 5) =====
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聊天機器人')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/chatbot.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200]!.withOpacity(0.5), // 设置半透明的背景色
                child: Center(child: Text('聊天記錄')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(hintText: '輸入訊息'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      // 發送訊息給 AI 回應
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 呼吸練習頁面 (Use Case 6) =====
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('呼吸練習')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/breathing.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('選擇一個呼吸練習'),
              ElevatedButton(
                onPressed: () {
                  // 4-7-8 呼吸法
                },
                child: Text('4-7-8 呼吸法'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 盒子呼吸法
                },
                child: Text('盒子呼吸法'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 設定與個人化頁面 (Use Case 7) =====
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/setting.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            ListTile(
              title: Text('每日提醒設定'),
              onTap: () {
                // 設定提醒
              },
            ),
            ListTile(
              title: Text('佈景主題'),
              onTap: () {
                // 更改佈景主題
              },
            ),
          ],
        ),
      ),
    );
  }
}
