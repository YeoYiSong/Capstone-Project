import 'package:flutter/material.dart';
import 'diary_screen.dart';
import 'breathing_screen.dart';

class DiarySavedScreen extends StatelessWidget {
  final bool isEnglish;
  final List<Map<String, dynamic>> selectedEmotions;
  final String mixedColor;

  const DiarySavedScreen({
    super.key,
    this.isEnglish = false,
    required this.selectedEmotions,
    required this.mixedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorValue = int.parse(mixedColor.replaceFirst('#', ''), radix: 16);
    final mixedColorValue = Color(colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Saved to Diary' : '已存入本子'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => DiaryScreen(isEnglish: isEnglish),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: Container(
        color: mixedColorValue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isEnglish
                    ? 'Saved to diary!\nYou can try the following exercises too!'
                    : '已存入本子！\n你可以做以下的練習，也很不錯！',
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: mixedColorValue,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    mixedColor,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BreathingScreen(isEnglish: isEnglish),
                    ),
                  );
                },
                icon: const Icon(Icons.self_improvement),
                label: Text(isEnglish ? 'Breathing' : '呼吸'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/diary_review');
                },
                child: Text(isEnglish ? 'View Diary' : '查看本子'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
