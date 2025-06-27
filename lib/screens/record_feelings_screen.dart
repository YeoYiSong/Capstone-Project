import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/api_client.dart';
import 'home_screen.dart';

class RecordFeelingsScreen extends StatefulWidget {
  final bool isEnglish;
  final DateTime date;
  final int duration;

  const RecordFeelingsScreen({
    super.key,
    required this.isEnglish,
    required this.date,
    required this.duration,
  });

  @override
  RecordFeelingsScreenState createState() => RecordFeelingsScreenState();
}

class RecordFeelingsScreenState extends State<RecordFeelingsScreen> {
  late final TextEditingController _feelingsController;
  final FocusNode _feelingsFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();

  String? _userId;

  @override
  void initState() {
    super.initState();
    _feelingsController = TextEditingController();
    _getUserId();
  }

  Future<void> _getUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final response = await http.post(
        Uri.parse('${_apiClient.baseUrl}/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': user.uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userId = data['user_id'].toString();
        });
      } else {
        if (kDebugMode) print('取得 user_id 失敗：${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('get_user_id 錯誤：$e');
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
      body: Padding(
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
              ElevatedButton(
                onPressed: () async {
                  void navigateToHomeScreen() {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HomeScreen(
                              username: 'User',
                              isEnglish: widget.isEnglish,
                            ),
                      ),
                      (route) => false,
                    );
                  }

                  void showErrorSnackBar(Exception e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('儲存感受失敗：$e')));
                  }

                  try {
                    if (_userId == null) {
                      throw Exception('無法取得 user_id');
                    }

                    await _apiClient.saveBreathRecord(
                      userId: _userId!,
                      duration: widget.duration,
                      min: widget.duration,
                      felling: _feelingsController.text,
                      type: '引導',
                    );

                    navigateToHomeScreen();
                  } catch (e) {
                    if (kDebugMode) {
                      print('儲存呼吸記錄錯誤：$e');
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
                child: Text(widget.isEnglish ? 'Save' : '儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
