import 'package:flutter/material.dart';

void main() {
  runApp(const Smaily2App());
}

class Smaily2App extends StatelessWidget {
  const Smaily2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smaily',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home':
            (context) => const HomeScreen(username: 'jiuke'), // 假設用戶名為 jiuke
        '/diary': (context) => const DiaryScreen(),
        '/recommendation': (context) => const RecommendationScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/breathing': (context) => const BreathingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/diary_review': (context) => const DiaryReviewScreen(), // 新增日記回顧頁面
        '/store': (context) => const StoreScreen(), // 新增 Store 頁面
      },
    );
  }
}

// ===== 啟動畫面 =====
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 39, 1, 177), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text(
                  "感受當下，\n療癒每一刻。",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Smaily",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
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

// ===== 登入頁面 =====
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Forget password?"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 假設登入成功，傳遞用戶名到主畫面
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                    arguments: 'jiuke',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("Sign Up"),
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
      appBar: AppBar(title: const Text('註冊')),
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
              const Text('註冊表單 (Email、密碼、Google/Apple 快速登入)'),
              ElevatedButton(
                onPressed: () {
                  // 註冊成功後導向主畫面
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                    arguments: 'jiuke',
                  );
                },
                child: const Text('註冊'),
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
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smaily 2 主畫面'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左上角問候語
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '早安，$username！',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(), // 將下方內容推到頁面底部
            // 第一個位置：四個圓形按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton(context, '我的一天', Icons.book, '/diary'),
                  _buildCircleButton(
                    context,
                    '呼吸',
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
                    '本子',
                    Icons.history,
                    '/diary_review',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 第二個位置：三個按鈕
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(context, '首頁', Icons.home, '/home'),
                  _buildBottomButton(context, 'Store', Icons.store, '/store'),
                  _buildBottomButton(
                    context,
                    '設定',
                    Icons.settings,
                    '/settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 圓形按鈕組件
  Widget _buildCircleButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
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
              border: Border.all(color: Colors.black54, width: 2),
            ),
            child: Center(child: Icon(icon, size: 32, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 底部按鈕組件
  Widget _buildBottomButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// ===== 日記頁面 =====
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的一天')),
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
              const Text('此刻你的心情如何？'),
              TextField(decoration: InputDecoration(hintText: '請輸入心情描述')),
              const SizedBox(height: 20),
              const Text('今天讓你感到最溫暖的事情是什麼？'),
              TextField(decoration: InputDecoration(hintText: '請輸入感恩事項')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 提交日記後導向推薦頁面
                  Navigator.pushNamed(context, '/recommendation');
                },
                child: const Text('提交日記'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 精油與練習推薦頁面 =====
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('推薦')),
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
              const Text('AI 分析結果：'),
              const Text('今日建議使用薰衣草精油搭配 5 分鐘冥想'),
              ElevatedButton(
                onPressed: () {
                  // 若有連結購買頁面，這裡可以導向購買頁面
                },
                child: const Text('了解更多'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 聊天機器人頁面 =====
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('聊天機器人')),
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
                color: Colors.grey[200]!.withValues(alpha: 0.5),
                child: const Center(child: Text('聊天記錄')),
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
                    icon: const Icon(Icons.send),
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

// ===== 呼吸練習頁面 =====
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('呼吸練習')),
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
              const Text('選擇一個呼吸練習'),
              ElevatedButton(
                onPressed: () {
                  // 4-7-8 呼吸法
                },
                child: const Text('4-7-8 呼吸法'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 盒子呼吸法
                },
                child: const Text('盒子呼吸法'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 設定與個人化頁面 =====
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
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
              title: const Text('每日提醒設定'),
              onTap: () {
                // 設定提醒
              },
            ),
            ListTile(
              title: const Text('佈景主題'),
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

// ===== 日記回顧頁面 =====
class DiaryReviewScreen extends StatelessWidget {
  const DiaryReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日記回顧')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/diary_review.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text(
            '這裡是你所有的日記回顧',
            style: TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

// ===== Store 頁面 =====
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/store.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text(
            '歡迎來到 Smaily 商店！',
            style: TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
