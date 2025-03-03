import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '原神介紹',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GenshinImpactPage(),
    );
  }
}

class GenshinImpactPage extends StatelessWidget {
  const GenshinImpactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('原神介紹')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 顯示圖片
              Image.asset('assets/picture/genshin.png', fit: BoxFit.cover),
              SizedBox(height: 20), // 間距
              // 遊戲介紹文字
              Text(
                '原神',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '《原神》是由米哈遊開發的一款開放世界動作角色扮演遊戲。遊戲以奇幻世界「提瓦特」為背景，玩家將扮演「旅行者」，探索這個充滿神秘與冒險的世界。',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                '遊戲特色：',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1. 開放世界：自由探索廣闊的地圖，發現隱藏的寶藏和秘密。\n'
                '2. 角色收集：收集並培養多種獨特的角色，每個角色都有專屬的技能和故事。\n'
                '3. 元素互動：利用火、水、風、雷等元素進行戰鬥和解謎。\n'
                '4. 多人合作：與朋友組隊，挑戰強大的敵人。',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              // 按鈕
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // 按鈕點擊事件
                    print('前往官方網站');
                  },
                  child: Text('前往官方網站'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
