import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
  String? _userId;
  bool _playIntro = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _getUserIdFromFirebase();
  }

  Future<void> _getUserIdFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No user logged in');
        }
        return;
      }

      final uid = user.uid;
      final response = await http.post(
        Uri.parse('http://localhost:5000/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userId = data['user_id'].toString();
          });
        }
        if (kDebugMode) {
          print('User ID fetched: $_userId');
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch user ID: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user ID: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _playAudioSequence() async {
    try {
      if (_playIntro) {
        if (kDebugMode) {
          print('Playing intro.mp3');
        }
        await _audioPlayer.play(AssetSource('breath/intro.mp3'));
        _audioPlayer.onPlayerComplete.listen((event) {
          _playGuideAudio();
        });
      } else {
        _playGuideAudio();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to play audio. Please try again.'
                  : '無法播放音頻，請重試。',
            ),
          ),
        );
      }
    }
  }

  Future<void> _playGuideAudio() async {
    try {
      if (kDebugMode) {
        print('Playing guide.mp3');
      }
      await _audioPlayer.play(AssetSource('breath/guide.mp3'));
      _audioPlayer.onPlayerComplete.listen((event) {
        if (_remainingSeconds > 0) {
          if (kDebugMode) {
            print('Playing breathing_guide.mp4');
          }
          _audioPlayer.play(AssetSource('breath/breathing_guide.mp4'));
          _audioPlayer.onPlayerComplete.listen((event) {
            if (_remainingSeconds > 0) {
              // Loop breathing_guide.mp4 if time remains
              _audioPlayer.play(
                AssetSource('assets/breath/breathing_guide.mp4'),
              );
            }
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error playing guide audio: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Failed to play guide audio. Please try again.'
                  : '無法播放引導音頻，請重試。',
            ),
          ),
        );
      }
    }
  }

  void _startExercise() {
    setState(() {
      step = 2;
      _isPlaying = true;
      _remainingSeconds = duration * 60;
    });
    _playAudioSequence();
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
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isEnglish ? 'Play Introduction?' : '是否播放前言？'),
          content: Text(
            widget.isEnglish
                ? 'Would you like to listen to the introduction? Recommended for first-time users!'
                : '您想聆聽前言說明嗎？建議首次使用者聆聽喲~~',
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _playIntro = true;
                  step = 1;
                });
                Navigator.of(context).pop();
              },
              child: Text(widget.isEnglish ? 'Yes' : '是'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _playIntro = false;
                  step = 1;
                });
                Navigator.of(context).pop();
              },
              child: Text(widget.isEnglish ? 'Skip' : '跳過'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/picture/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
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
                  label:
                      widget.isEnglish ? '$duration minutes' : '$duration 分鐘',
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
                  onPressed: _showIntroDialog,
                  child: Text(widget.isEnglish ? 'Next' : '下一步'),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (step == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/picture/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
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
        ),
      );
    } else if (step == 2) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/picture/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isEnglish
                      ? 'Breathing Exercise in Progress'
                      : '呼吸練習進行中',
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
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEnglish ? 'Breathing Exercise' : '呼吸練習'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/picture/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isEnglish
                      ? 'Breathing Exercise Completed!'
                      : '呼吸練習已完成！',
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
                    if (_userId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.isEnglish
                                  ? 'User ID not available.'
                                  : '無法取得使用者 ID',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecordFeelingsScreen(
                              isEnglish: widget.isEnglish,
                              date: DateTime.now(),
                              userId: _userId!,
                              duration: duration,
                              min: duration,
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
        ),
      );
    }
  }
}
