import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/hexagon_emotion_selector.dart';
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import 'diary_saved_screen.dart';

class DayFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final bool isReadOnly;
  final List<Map<String, dynamic>>? emotions;
  final String? mixedColor;
  final String? moodText;
  final String? details;

  const DayFeelingsScreen({
    super.key,
    this.isEnglish = false,
    required this.date,
    this.isReadOnly = false,
    this.emotions,
    this.mixedColor,
    this.moodText,
    this.details,
  });

  @override
  DayFeelingsScreenState createState() => DayFeelingsScreenState();
}

class DayFeelingsScreenState extends State<DayFeelingsScreen> {
  String moodText = '';
  late final TextEditingController _moodController;
  late final TextEditingController _detailsController;
  final FocusNode _moodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();

  final List<String> _prompts = [];
  final List<String> _chinesePrompts = [
    '今天有什麼讓你感到開心的事？',
    '有沒有什麼讓你感到壓力的事件？',
    '今天你學到了什麼新東西？',
    '你今天和誰有過特別的互動？',
    '有什麼讓你感到意外的事情嗎？',
    '今天的某個時刻讓你感到放鬆嗎？',
    '你今天有沒有完成什麼重要的任務？',
    '有什麼讓你感到挫折的瞬間？',
    '今天的天氣如何影響你的心情？',
    '你今天有沒有什麼特別的靈感或想法？',
  ];
  final List<String> _englishPrompts = [
    'What made you happy today?',
    'Was there anything stressful today?',
    'What new thing did you learn today?',
    'Who did you have a special interaction with today?',
    'Was there anything surprising today?',
    'Did you have a relaxing moment today?',
    'Did you complete any important tasks today?',
    'Was there a moment that frustrated you?',
    'How did the weather affect your mood today?',
    'Did you have any special inspirations or ideas today?',
  ];
  int _currentPromptIndex = 0;

  List<Map<String, dynamic>> _selectedEmotions = [];

  @override
  void initState() {
    super.initState();
    _prompts.addAll(widget.isEnglish ? _englishPrompts : _chinesePrompts);
    _currentPromptIndex = Random().nextInt(_prompts.length);
    _moodController = TextEditingController(text: widget.moodText ?? '');
    _detailsController = TextEditingController(text: widget.details ?? '');
    moodText = widget.moodText ?? '';
    if (widget.emotions != null) {
      _selectedEmotions = widget.emotions!;
    }
  }

  @override
  void dispose() {
    _moodController.dispose();
    _detailsController.dispose();
    _moodFocusNode.dispose();
    _detailsFocusNode.dispose();
    super.dispose();
  }

  void _switchPrompt() {
    if (!widget.isReadOnly) {
      setState(() {
        _currentPromptIndex = Random().nextInt(_prompts.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Day Feelings' : '整天的感受'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (!widget.isReadOnly)
                  HexagonEmotionSelector(
                    isEnglish: widget.isEnglish,
                    onEmotionSelected: (emotions) {
                      setState(() {
                        _selectedEmotions =
                            emotions
                                .map(
                                  (e) => {
                                    'emotion': e['emotion'],
                                    'intensity': e['intensity'],
                                  },
                                )
                                .toList();
                      });
                    },
                  )
                else
                  Text(
                    _selectedEmotions.isNotEmpty
                        ? _selectedEmotions
                            .map((e) => '${e['emotion']}: ${e['intensity']}%')
                            .join(', ')
                        : (widget.isEnglish ? 'No emotions selected' : '未選擇情緒'),
                    style: const TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 20),
                if (!widget.isReadOnly)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: GestureDetector(
                      key: ValueKey(_currentPromptIndex),
                      onTap: _switchPrompt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _prompts[_currentPromptIndex],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _moodController,
                      focusNode: _moodFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            widget.isEnglish
                                ? 'Why do you feel this way?'
                                : '為什麼有這種情緒？',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.blue.withValues(alpha: 0.05),
                      ),
                      onChanged: (text) {
                        moodText = text;
                      },
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      enabled: !widget.isReadOnly,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _detailsController,
                      focusNode: _detailsFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            widget.isEnglish
                                ? 'More details (optional)'
                                : '更多細節（可選）',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.blue.withValues(alpha: 0.05),
                      ),
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      enabled: !widget.isReadOnly,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!widget.isReadOnly)
                  ElevatedButton(
                    onPressed: () async {
                      void navigateToSavedScreen() {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DiarySavedScreen(
                                  isEnglish: widget.isEnglish,
                                  selectedEmotions: _selectedEmotions,
                                  mixedColor: mixColorsWithAlpha(
                                    _selectedEmotions,
                                  ),
                                ),
                          ),
                        );
                      }

                      void showErrorSnackBar(Exception e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save day entry: $e'),
                          ),
                        );
                      }

                      try {
                        final mixedColorWithAlpha = mixColorsWithAlpha(
                          _selectedEmotions,
                        );
                        // 先建一個預設情緒映射
                        Map<String, double> emotionMap = {
                          'joy': 0,
                          'sadness': 0,
                          'anger': 0,
                          'positive': 0,
                          'anxiety': 0,
                          'exhaust': 0,
                        };

                        // 如果有選擇情緒就填入
                        for (var emotion in _selectedEmotions) {
                          final e =
                              (emotion['emotion'] as String).toLowerCase();
                          final value =
                              double.tryParse(
                                emotion['intensity'].toString(),
                              ) ??
                              0;
                          if (emotionMap.containsKey(e)) {
                            emotionMap[e] = value;
                          }
                        }

                        await _apiClient.saveDiaryEntry(
                          date: widget.date,
                          type: 'Day',
                          emotions: _selectedEmotions,
                          mixedColor: mixedColorWithAlpha,
                          moodText: moodText,
                          details: _detailsController.text,
                          isEnglish: widget.isEnglish,
                          joy: emotionMap['joy']!,
                          sadness: emotionMap['sadness']!,
                          anger: emotionMap['anger']!,
                          positive: emotionMap['positive']!,
                          anxiety: emotionMap['anxiety']!,
                          exhaust: emotionMap['exhaust']!,
                        );

                        navigateToSavedScreen();
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error saving day entry: $e');
                        }
                        showErrorSnackBar(e as Exception);
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.isEnglish ? 'Done' : '完成'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
