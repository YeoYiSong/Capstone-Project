import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../utils/api_client.dart';
import 'home_screen.dart';
import 'record_feelings_screen.dart';

class BreathingScreen extends StatefulWidget {
  final bool isEnglish;

  const BreathingScreen({super.key, this.isEnglish = false});

  @override
  BreathingScreenState createState() => BreathingScreenState();
}

class BreathingScreenState extends State<BreathingScreen> {
  int duration = 5;
  int step = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  bool _isPlaying = false;
  int _remainingSeconds = 0;
  final ApiClient _apiClient = ApiClient();

  String? _userId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(AssetSource('breathing_guide.mp4'));
    _getUserIdFromFirebase();
  }

  Future<void> _getUserIdFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final response = await http.post(
        Uri.parse('${_apiClient.baseUrl}/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userId = data['user_id'].toString();
        });
      } else {
        if (kDebugMode) {
          print('後端回傳錯誤：${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('取得 userId 錯誤：$e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      step = 2;
      _isPlaying = true;
      _remainingSeconds = duration * 60;
    });
    _audioPlayer.play(AssetSource('breathing_guide.mp4'));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopExercise();
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPlaying) {
        _audioPlayer.pause();
        _timer?.cancel();
      } else {
        _audioPlayer.resume();
        _startTimer();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _stopExercise() {
    _audioPlayer.stop();
    _timer?.cancel();
    setState(() {
      step = 3;
      _isPlaying = false;
    });
    _saveBreathingDuration();
  }

  void _saveBreathingDuration() async {
    if (_userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish ? 'User ID not available.' : '無法取得使用者 ID',
          ),
        ),
      );
      return;
    }

    try {
      await _apiClient.saveBreathRecord(
        userId: _userId!,
        duration: duration,
        min: duration,
        felling: null,
        type: '引導',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'Duration saved!' : '練習時長已儲存！'),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('儲存練習時長錯誤：$e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('儲存練習時長失敗：$e')));
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEnglish ? 'Select Exercise Duration' : '選擇練習時間',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Slider(
                value: duration.toDouble(),
                min: 5,
                max: 10,
                divisions: 5,
                label: widget.isEnglish ? '$duration minutes' : '$duration 分鐘',
                onChanged: (value) {
                  setState(() {
                    duration = value.toInt();
                  });
                },
              ),
              Text(
                widget.isEnglish ? '$duration minutes' : '$duration 分鐘',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    step = 1;
                  });
                },
                child: Text(widget.isEnglish ? 'Next' : '下一步'),
              ),
            ],
          ),
        ),
      );
    } else if (step == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEnglish
                    ? 'Focus Tip: Concentrate on your breath'
                    : '觀照點提示：專注於你的鼻息',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startExercise,
                child: Text(widget.isEnglish ? 'Start' : '開始'),
              ),
            ],
          ),
        ),
      );
    } else if (step == 2) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEnglish ? 'Breathing Exercise in Progress' : '呼吸練習進行中',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isEnglish
                    ? 'Time Remaining: ${_formatDuration(_remainingSeconds)}'
                    : '剩餘時間：${_formatDuration(_remainingSeconds)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _remainingSeconds / (duration * 60),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _togglePause,
                    child: Text(
                      widget.isEnglish
                          ? (_isPlaying ? 'Pause' : 'Resume')
                          : (_isPlaying ? '暫停' : '繼續'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _stopExercise,
                    child: Text(widget.isEnglish ? 'End' : '結束'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.isEnglish
                    ? 'Duration Selected: $duration minutes'
                    : '選擇的時長：$duration 分鐘',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEnglish ? 'Breathing Exercise Completed!' : '呼吸練習已完成！',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isEnglish
                    ? 'Duration: $duration minutes'
                    : '時長：$duration 分鐘',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => RecordFeelingsScreen(
                            isEnglish: widget.isEnglish,
                            date: DateTime.now(),
                            duration: duration,
                          ),
                    ),
                  );
                },
                child: Text(widget.isEnglish ? 'Record Feelings' : '記錄感受'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
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
                },
                child: Text(widget.isEnglish ? 'Back to Home' : '返回首頁'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
