import 'package:flutter/material.dart'; //引用material的設計套件

void main() {
  runApp(Smaily2App());
}

class Smaily2App extends StatelessWidget {
  const Smaily2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smaily',
      theme: ThemeData(primarySwatch: Colors.blue),
      // 根據 Use Case 文件規劃路由
      initialRoute: '/',
      routes: {
        '/': (context) => StartScreen(),
        '/login': (context) => LoginScreen(),
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

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📌 背景裝飾
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 39, 1, 177),
                    Colors.white,
                  ], // 深藍色背景
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 📌 主內容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // 📌 標語
                const Text(
                  "感受當下，\n療癒每一刻。",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                // 📌 APP 名稱
                const Text(
                  "Smaily",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                // 📌 "Go" 圓形按鈕
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward,
                          size: 32,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 登入頁面 (Use Case 1: 註冊與登入) =====
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Smaily 2",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 📌 輸入框：帳號
            TextField(
              decoration: InputDecoration(
                hintText: "Phone, user name or email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),

            // 📌 輸入框：密碼
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 8),

            // 📌 忘記密碼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Forget password?"),
              ),
            ),
            const SizedBox(height: 16),

            // 📌 按鈕：登入
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 按鈕顏色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Log In",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📌 分隔線
            Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("or"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),

            // 📌 註冊按鈕
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("Sign Up"),
            ),
            const SizedBox(height: 10),

            // 📌 快速登入（Facebook, Apple, Gmail）
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
                  onPressed: () {},
                  icon: Image.asset("assets/icons/google.png", width: 40),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {},
                  icon: Image.asset("assets/icons/gmail.jpg", width: 40),
                ),
              ],
            ),
          ],
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
                color: Colors.grey[200]!.withValues(alpha: 0.5), // 设置半透明的背景色
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
