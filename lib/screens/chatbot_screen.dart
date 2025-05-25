import 'package:flutter/material.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasRecommendation = false;
    final now = DateTime.now();
    hasRecommendation = now.minute % 2 == 1;

    String greeting =
        hasRecommendation
            ? '嘿~我找了一個專屬於你的味道，你要不要看看？還是你想聊聊什麼？'
            : '您好~我是Smaily，你想要聊聊什麼嗎？';

    return Scaffold(
      appBar: AppBar(title: const Text('Smaily AI')),
      body: Column(
        children: [
          Expanded(child: Center(child: Text(greeting))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: '輸入訊息'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
