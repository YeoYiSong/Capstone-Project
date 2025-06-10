import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';

class ScenarioModeScreen extends StatefulWidget {
  final bool isEnglish;

  const ScenarioModeScreen({super.key, required this.isEnglish});

  @override
  State<ScenarioModeScreen> createState() => _ScenarioModeScreenState();
}

class _ScenarioModeScreenState extends State<ScenarioModeScreen> {
  late Timer _timer;
  late DateTime _dateTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int currentIndex = 0;

  List<Map<String, dynamic>> musicList = [
    {
      'title': '放鬆平滑棕噪聲',
      'englishTitle': 'Relaxing Smoothed Brown Noise',
      'file': 'assets/scenario_music/relaxing-smoothed-brown-noise.mp3',
      'liked': false,
    },
    {
      'title': '柔和棕噪聲',
      'englishTitle': 'Soft Brown Noise',
      'file': 'assets/scenario_music/soft-brown-noise-.mp3',
      'liked': false,
    },
    {
      'title': '舒緩深層噪聲',
      'englishTitle': 'Soothing Deep Noise',
      'file': 'assets/scenario_music/soothing-deep-noise-.mp3',
      'liked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _dateTime = DateTime.now();
    _loadFavorites();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _dateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicList =
          musicList.map((music) {
            final isFavorite = prefs.getBool(music['title']) ?? music['liked'];
            return {...music, 'liked': isFavorite};
          }).toList();
      _sortMusicList();
    });
  }

  Future<void> _toggleFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicList[index]['liked'] = !musicList[index]['liked'];
      prefs.setBool(musicList[index]['title'], musicList[index]['liked']);
      _sortMusicList();
    });
  }

  void _sortMusicList() {
    setState(() {
      musicList.sort((a, b) {
        if (a['liked'] && !b['liked']) return -1;
        if (!a['liked'] && b['liked']) return 1;
        return 0;
      });
    });
  }

  Future<void> _playMusic(int index) async {
    setState(() {
      currentIndex = index;
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      await _audioPlayer.play(
        AssetSource(musicList[index]['file'].replaceFirst('assets/', '')),
      );
    } else {
      await _audioPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = [...musicList];

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEnglish ? 'Scenario Mode' : '情景模式')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 模擬時鐘
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: ClockPainter(_dateTime),
              child: Container(),
            ),
          ),
          const SizedBox(height: 20),
          // 正在播放
          Text(
            widget.isEnglish ? 'Now Playing:' : '正在播放：',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            widget.isEnglish
                ? sortedList[currentIndex]['englishTitle']
                : sortedList[currentIndex]['title'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // 控制按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  sortedList[currentIndex]['liked']
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: sortedList[currentIndex]['liked'] ? Colors.red : null,
                ),
                onPressed: () => _toggleFavorite(currentIndex),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 40,
                  color: Colors.blue,
                ),
                onPressed: () => _playMusic(currentIndex),
              ),
              IconButton(
                icon: const Icon(Icons.list, color: Colors.blue),
                onPressed: () async {
                  final result = await showModalBottomSheet<int>(
                    context: context,
                    builder:
                        (context) => ListView.builder(
                          itemCount: sortedList.length,
                          itemBuilder:
                              (context, index) => ListTile(
                                leading: Icon(
                                  sortedList[index]['liked']
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      sortedList[index]['liked']
                                          ? Colors.red
                                          : null,
                                ),
                                title: Text(
                                  widget.isEnglish
                                      ? sortedList[index]['englishTitle']
                                      : sortedList[index]['title'],
                                ),
                                onTap: () {
                                  Navigator.pop(context, index);
                                  _playMusic(index);
                                },
                              ),
                        ),
                  );
                  if (result != null) {
                    setState(() {
                      currentIndex = result;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 音樂列表標題
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.isEnglish ? 'Music Selection' : '音樂選擇',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 音樂列表
          Expanded(
            child: ListView.builder(
              itemCount: sortedList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.blue),
                    onPressed: () => _playMusic(index),
                  ),
                  title: Text(
                    widget.isEnglish
                        ? sortedList[index]['englishTitle']
                        : sortedList[index]['title'],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      sortedList[index]['liked']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: sortedList[index]['liked'] ? Colors.red : null,
                    ),
                    onPressed: () => _toggleFavorite(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime dateTime;

  ClockPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    // 時鐘背景
    final circlePaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // 時鐘邊框
    final borderPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);

    // 時鐘刻度
    final tickPaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final start = Offset(
        center.dx + radius * 0.9 * cos(angle - pi / 2),
        center.dy + radius * 0.9 * sin(angle - pi / 2),
      );
      final end = Offset(
        center.dx + radius * cos(angle - pi / 2),
        center.dy + radius * sin(angle - pi / 2),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // 時針
    final hourAngle =
        (dateTime.hour % 12 + dateTime.minute / 60) * 30 * pi / 180;
    final hourHand = Offset(
      center.dx + radius * 0.5 * cos(hourAngle - pi / 2),
      center.dy + radius * 0.5 * sin(hourAngle - pi / 2),
    );

    // 分針
    final minuteAngle = dateTime.minute * 6 * pi / 180;
    final minuteHand = Offset(
      center.dx + radius * 0.7 * cos(minuteAngle - pi / 2),
      center.dy + radius * 0.7 * sin(minuteAngle - pi / 2),
    );

    // 繪製時針和分針
    final handPaint =
        Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6;
    canvas.drawLine(center, hourHand, handPaint);
    canvas.drawLine(center, minuteHand, handPaint);

    // 中心點
    final centerPaint = Paint()..color = Colors.blue;
    canvas.drawCircle(center, 5, centerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
