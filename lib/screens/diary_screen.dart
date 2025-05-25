import 'package:flutter/material.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';

class DiaryScreen extends StatelessWidget {
  final bool isEnglish;

  const DiaryScreen({super.key, this.isEnglish = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEnglish ? 'My Day' : '我的一天')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isEnglish ? 'What would you like to record?' : '你要記錄什麼？',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MomentFeelingsScreen(
                                isEnglish: isEnglish,
                                date: DateTime.now(), // 使用當前日期
                              ),
                        ),
                      );
                    },
                    child: Text(isEnglish ? 'Moment Feelings' : '當下的感受'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DayFeelingsScreen(
                                isEnglish: isEnglish,
                                date: DateTime.now(), // 使用當前日期
                              ),
                        ),
                      );
                    },
                    child: Text(isEnglish ? 'Day Feelings' : '整天的感受'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
