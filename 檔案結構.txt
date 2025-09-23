demosmaily/  # 專案根目錄
├── lib/
│   ├── main.dart主程式 用flutter run 跑，記得要cd到demosmaily
│   ├── screens/
│   │   ├── start_screen.dart初始頁面
│   │   ├── login_screen.dart登入頁面
│   │   ├── register_screen.dart註冊頁面
│   │   ├── home_screen.dart主頁面
│   │   ├── diary_screen.dart日記頁面
│   │   ├── moment_feelings_screen.dart當下感受頁面
│   │   ├── day_feelings_screen.dart整日感受頁面
│   │   ├── diary_saved_screen.dart日記保存頁面
│   │   ├── diary_review_screen.dart日記回顧頁面
│   │   ├── diary_locked_screen.dart日記鎖頁面
│   │   ├── breathing_screen.dart呼吸頁面
│   │   ├── settings_screen.dart設置頁面
│   │   ├── recommendation_screen.dart推薦商品頁面
│   │   ├── chatbot_screen.dart聊天機器人頁面
│   │   ├── store_screen.dart 商店頁面
│   ├── utils/
│   │   ├── color_mixing.dart 混色邏輯
│   │   ├── api_client.dart  連線
│   ├── widgets/
│   │   ├── hexagon_emotion_selector.dart六角模型
│   ├── firebase_options.dart  firebase設置
│
├── backend/  # 後端目錄
│   ├── app.py   後端模組 phython app.py，記得要cd到backend
│   ├── venv/  # 虛擬環境（可選，根據你的設置）