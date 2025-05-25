import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/hexagon_emotion_selector.dart';
import '../widgets/doodle_painter.dart';
import '../models/doodle_stroke.dart';
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
  bool showToolbox = false;
  Color selectedColor = Colors.black;
  bool isErasing = false;
  List<DoodleStroke> doodleStrokes = [];
  List<Offset> currentStroke = [];
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
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart:
                widget.isReadOnly
                    ? null
                    : (details) {
                      if (showToolbox && !isErasing) {
                        setState(() {
                          currentStroke = [details.localPosition];
                        });
                      }
                    },
            onPanUpdate:
                widget.isReadOnly
                    ? null
                    : (details) {
                      if (showToolbox) {
                        setState(() {
                          if (isErasing) {
                            doodleStrokes.removeWhere(
                              (stroke) => stroke.points.any(
                                (point) =>
                                    (point - details.localPosition).distance <
                                    20,
                              ),
                            );
                          } else {
                            currentStroke.add(details.localPosition);
                          }
                        });
                      }
                    },
            onPanEnd:
                widget.isReadOnly
                    ? null
                    : (details) {
                      if (showToolbox &&
                          !isErasing &&
                          currentStroke.isNotEmpty) {
                        setState(() {
                          doodleStrokes.add(
                            DoodleStroke(
                              points: List.from(currentStroke),
                              color: selectedColor,
                            ),
                          );
                          currentStroke.clear();
                        });
                      }
                    },
            child: CustomPaint(
              painter: Assys(doodleStrokes, currentStroke, selectedColor),
              child: Container(height: 200, color: Colors.transparent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              physics:
                  showToolbox
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 220),
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
                          : (widget.isEnglish
                              ? 'No emotions selected'
                              : '未選擇情緒'),
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
                      child: Text(widget.isEnglish ? 'Done' : '完成'),
                    ),
                ],
              ),
            ),
          ),
          if (showToolbox && !widget.isReadOnly)
            Positioned(top: 80, right: 16, child: _buildToolbox()),
        ],
      ),
      floatingActionButton:
          !widget.isReadOnly
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    showToolbox = !showToolbox;
                  });
                },
                child: const Icon(Icons.brush),
              )
              : null,
    );
  }

  Widget _buildToolbox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.grey)],
      ),
      child: Column(
        children: [
          Text(widget.isEnglish ? 'Toolbox' : '工具盒'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.brush, color: Colors.black),
                onPressed: () {
                  setState(() {
                    selectedColor = Colors.black;
                    isErasing = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.brush, color: Colors.red),
                onPressed: () {
                  setState(() {
                    selectedColor = Colors.red;
                    isErasing = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.brush, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    selectedColor = Colors.blue;
                    isErasing = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.cleaning_services, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    isErasing = !isErasing;
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Text('😊', style: TextStyle(fontSize: 30)),
                onPressed: () {
                  _addEmojiToFocusedField('😊');
                },
              ),
              IconButton(
                icon: const Text('🌟', style: TextStyle(fontSize: 30)),
                onPressed: () {
                  _addEmojiToFocusedField('🌟');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addEmojiToFocusedField(String emoji) {
    late TextEditingController controller;
    late FocusNode activeFocusNode;

    if (_moodFocusNode.hasFocus) {
      controller = _moodController;
      activeFocusNode = _moodFocusNode;
    } else if (_detailsFocusNode.hasFocus) {
      controller = _detailsController;
      activeFocusNode = _detailsFocusNode;
    } else {
      controller = _moodController;
      activeFocusNode = _moodFocusNode;
      activeFocusNode.requestFocus();
    }

    setState(() {
      final text = controller.text;
      final selection = controller.selection;
      final newText =
          selection.start >= 0
              ? text.replaceRange(selection.start, selection.end, emoji)
              : text + emoji;
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset:
            selection.start >= 0
                ? selection.start + emoji.length
                : text.length + emoji.length,
      );
    });
  }
}
