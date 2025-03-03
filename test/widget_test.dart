import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart'; // 確保路徑正確

void main() {
  testWidgets('測試原神介紹頁面', (WidgetTester tester) async {
    // 建立測試用的 MyApp
    await tester.pumpWidget(MyApp());

    // 檢查 AppBar 的標題是否正確
    expect(find.text('原神介紹'), findsOneWidget);

    // 檢查圖片是否正確顯示
    expect(find.byType(Image), findsOneWidget);

    // 檢查標題文字是否正確
    expect(find.text('原神'), findsOneWidget);

    // 檢查遊戲介紹文字是否正確
    expect(
      find.text(
        '《原神》是由米哈遊開發的一款開放世界動作角色扮演遊戲。遊戲以奇幻世界「提瓦特」為背景，玩家將扮演「旅行者」，探索這個充滿神秘與冒險的世界。',
      ),
      findsOneWidget,
    );

    // 檢查遊戲特色標題是否正確
    expect(find.text('遊戲特色：'), findsOneWidget);

    // 檢查遊戲特色內容是否正確
    expect(find.text('1. 開放世界：自由探索廣闊的地圖，發現隱藏的寶藏和秘密。'), findsOneWidget);
    expect(find.text('2. 角色收集：收集並培養多種獨特的角色，每個角色都有專屬的技能和故事。'), findsOneWidget);
    expect(find.text('3. 元素互動：利用火、水、風、雷等元素進行戰鬥和解謎。'), findsOneWidget);
    expect(find.text('4. 多人合作：與朋友組隊，挑戰強大的敵人。'), findsOneWidget);

    // 檢查按鈕是否存在
    expect(find.text('前往官方網站'), findsOneWidget);

    // 模擬點擊按鈕
    await tester.tap(find.text('前往官方網站'));
    await tester.pump(); // 更新畫面狀態

    // 檢查按鈕點擊後的行為（例如終端輸出）
    // 這裡可以根據你的需求添加更多測試
  });
}
