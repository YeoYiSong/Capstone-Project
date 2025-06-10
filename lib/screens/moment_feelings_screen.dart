import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/hexagon_emotion_selector.dart';
import '../utils/color_mixing.dart';
import '../utils/api_client.dart';
import 'diary_saved_screen.dart';

class MomentFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final bool isReadOnly;
  final List<Map<String, dynamic>>? emotions;
  final String? mixedColor;
  final String? moodText;
  final String? details;

  const MomentFeelingsScreen({
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
  MomentFeelingsScreenState createState() => MomentFeelingsScreenState();
}

class MomentFeelingsScreenState extends State<MomentFeelingsScreen> {
  String moodText = '';
  late final TextEditingController _moodController;
  late final TextEditingController _detailsController;
  final FocusNode _moodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();

  List<Map<String, dynamic>> _selectedEmotions = [];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Moment Feelings' : '當下的感受'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
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
                      _selectedEmotions = emotions;
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
                          content: Text('Failed to save moment entry: $e'),
                        ),
                      );
                    }

                    final mixedColorWithAlpha = mixColorsWithAlpha(
                      _selectedEmotions,
                    );
                    try {
                      await _apiClient.saveDiaryEntry(
                        date: widget.date,
                        type: 'Moment',
                        emotions: _selectedEmotions,
                        mixedColor: mixedColorWithAlpha,
                        moodText: moodText,
                        details: _detailsController.text,
                        isEnglish: widget.isEnglish,
                      );
                      navigateToSavedScreen();
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error saving moment entry: $e');
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
    );
  }
}
