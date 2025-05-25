import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';

class BreathingScreen extends StatefulWidget {
  final bool isEnglish;

  const BreathingScreen({super.key, this.isEnglish = false});

  @override
  BreathingScreenState createState() => BreathingScreenState();
}

class BreathingScreenState extends State<BreathingScreen> {
  int duration = 5; // 初始值改為 5 分鐘（新範圍的最小值）
  int step = 0; // 當前階段（0: 選擇時長, 1: 準備, 2: 練習, 3: 完成）
  final AudioPlayer _audioPlayer = AudioPlayer(); // 音頻播放器
  Timer? _timer; // 計時器，用於控制練習時長
  bool _isPlaying = false; // 音頻是否正在播放
  int _remainingSeconds = 0; // 剩餘時間（秒）

  @override
  void initState() {
    super.initState();
    // 初始化音頻播放器，設置音頻文件
    _audioPlayer.setSource(AssetSource('breathing_guide.mp4'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 清理音頻播放器
    _timer?.cancel(); // 取消計時器
    super.dispose();
  }

  // 開始練習：啟動音頻和計時器
  void _startExercise() {
    setState(() {
      step = 2;
      _isPlaying = true;
      _remainingSeconds = duration * 60; // 將分鐘轉換為秒
    });
    _audioPlayer.play(AssetSource('breathing_guide.mp4')); // 播放音頻
    _startTimer(); // 啟動計時器
  }

  // 啟動計時器，根據選擇的時長倒計時
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopExercise(); // 時間到，停止練習
        }
      });
    });
  }

  // 暫停或繼續練習
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

  // 停止練習：停止音頻和計時器，進入完成階段
  void _stopExercise() {
    _audioPlayer.stop();
    _timer?.cancel();
    setState(() {
      step = 3;
      _isPlaying = false;
    });
  }

  // 格式化剩餘時間為 MM:SS
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      // 階段 0：選擇練習時長
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
                min: 5, // 更改最小值為 5
                max: 10, // 更改最大值為 10
                divisions: 5, // 調整分段為 5（5, 6, 7, 8, 9, 10）
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
      // 階段 1：準備開始
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
      // 階段 2：練習進行中
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
              // 進度條
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
            ],
          ),
        ),
      );
    } else {
      // 階段 3：練習完成
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => HomeScreen(
                            username: 'jiuke',
                            isEnglish: widget.isEnglish,
                          ),
                    ),
                    (route) => false,
                  );
                },
                child: Text(widget.isEnglish ? 'Finish' : '結束'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
