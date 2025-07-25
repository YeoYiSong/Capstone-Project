import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';
import 'home_screen.dart';

class RecordFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final int duration;
  final String userId;
  final int min;

  const RecordFeelingsScreen({
    super.key,
    required this.isEnglish,
    required this.date,
    required this.duration,
    required this.userId,
    required this.min,
  });

  @override
  RecordFeelingsScreenState createState() => RecordFeelingsScreenState();
}

class RecordFeelingsScreenState extends State<RecordFeelingsScreen> {
  late final TextEditingController _feelingsController;
  final FocusNode _feelingsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feelingsController = TextEditingController();
  }

  Future<void> _saveBreathRecord() async {
    if (_feelingsController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish ? 'Please enter your feelings' : '請輸入你的感受',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.saveBreathRecord(
        userId: widget.userId,
        duration: widget.duration,
        min: widget.min,
        feeling: _feelingsController.text,
        type: '引導',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Breath record saved successfully!'
                  : '呼吸記錄已儲存！',
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    HomeScreen(username: 'User', isEnglish: widget.isEnglish),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving breath record: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to save breath record: $e'
                  : '儲存呼吸記錄失敗：$e',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    _feelingsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Record Feelings' : '記錄感受'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  widget.isEnglish
                      ? 'Take a moment to record anything that just happened'
                      : '花點時間記錄剛剛發生的任何事吧',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isEnglish
                      ? 'Breathing Exercise Duration: ${widget.duration} minutes'
                      : '呼吸練習時長：${widget.duration} 分鐘',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _feelingsController,
                      focusNode: _feelingsFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            widget.isEnglish
                                ? 'How do you feel after the breathing exercise?'
                                : '呼吸練習後的感受是什麼？',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.blue.withAlpha(20),
                      ),
                      maxLines: null,
                      minLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _saveBreathRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.isEnglish ? 'Save' : '儲存'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
