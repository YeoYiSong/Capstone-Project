import 'dart:async';
import 'dart:convert';
import 'dart:math' as math; // ⬅ 用來做聲波的高斯衰減
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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

enum BreathMode { natural, guided }

class BreathingScreenState extends State<BreathingScreen> {
  // 調色盤（跟你給的圖）
  static const Color kBg = Color(0xFFDDEBD7);
  static const Color kInk = Color(0xFF2E5F3A);
  static const Color kSubInk = Color(0xFF5E7F6A);
  static const Color kPill = Color(0xFFE7F1E3);

  BreathMode _mode = BreathMode.natural;

  // 時長（分）— 5~10
  int duration = 5;

  // 流程
  int step = 0; // 0 選模式；1 準備；2 進行；3 完成
  bool _playIntro = false; // 引導模式會播放前言

  // 音訊/計時
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  bool _isPlaying = false;
  int _remainingSeconds = 0;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _getUserIdFromFirebase();
  }

  Future<void> _getUserIdFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final response = await http.post(
        Uri.parse('http://localhost:5000/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() => _userId = data['user_id'].toString());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ====== 音訊（只在引導呼吸用） ======
  Future<void> _playAudioSequence() async {
    if (!mounted || _mode != BreathMode.guided) return;
    try {
      if (_playIntro) {
        await _audioPlayer.play(AssetSource('breath/intro.mp3'));
        _audioPlayer.onPlayerComplete.listen((_) => _playGuideAudio());
      } else {
        _playGuideAudio();
      }
    } catch (_) {
      _toast(widget.isEnglish ? 'Failed to play audio' : '無法播放音檔');
    }
  }

  Future<void> _playGuideAudio() async {
    if (!mounted) return;
    try {
      await _audioPlayer.play(AssetSource('breath/guide.mp3'));
      _audioPlayer.onPlayerComplete.listen((_) async {
        if (_remainingSeconds > 0) {
          await _audioPlayer.play(AssetSource('breath/breathing_guide.mp4'));
          _audioPlayer.onPlayerComplete.listen((__) async {
            if (_remainingSeconds > 0) {
              await _audioPlayer.play(
                AssetSource('breath/breathing_guide.mp4'),
              );
            }
          });
        }
      });
    } catch (_) {
      _toast(widget.isEnglish ? 'Failed to play guide audio' : '無法播放引導音檔');
    }
  }

  // ====== 流程控制 ======
  void _goNextFromSelect() {
    // 不跳對話框：引導模式就固定播放前言，自然模式不播
    _playIntro = (_mode == BreathMode.guided);
    setState(() => step = 1);
  }

  void _startExercise() {
    setState(() {
      step = 2;
      _isPlaying = true;
      _remainingSeconds = duration * 60;
    });
    if (_mode == BreathMode.guided) _playAudioSequence();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
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
        if (_mode == BreathMode.guided) _audioPlayer.resume();
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

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return _buildSelectMode();
      case 1:
        return _buildPrepare();
      case 2:
        return _buildRunning();
      default:
        return _buildDone();
    }
  }

  // 0：模式選擇（按住大球左右滑即可切換）
  Widget _buildSelectMode() {
    double dragDx = 0.0;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          widget.isEnglish ? 'Breathing' : '呼吸',
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: widget.isEnglish ? 'Back' : '返回',
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kInk, width: 1.4),
              ),
              child: const Icon(Icons.arrow_back, color: kInk, size: 18),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 22),
          // 可左右滑的大球
          GestureDetector(
            onHorizontalDragStart: (_) => dragDx = 0,
            onHorizontalDragUpdate: (d) => dragDx += d.delta.dx,
            onHorizontalDragEnd: (_) {
              const threshold = 40.0;
              if (dragDx > threshold && _mode != BreathMode.guided) {
                setState(() => _mode = BreathMode.guided);
              } else if (dragDx < -threshold && _mode != BreathMode.natural) {
                setState(() => _mode = BreathMode.natural);
              }
            },
            child: _bigBall(
              label:
                  _mode == BreathMode.natural
                      ? (widget.isEnglish ? 'Natural' : '自然呼吸')
                      : (widget.isEnglish ? 'Guided' : '引導呼吸'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isEnglish
                ? 'Hold the circle and drag left/right to switch'
                : '按住大圓左右滑動可切換模式',
            style: TextStyle(color: kSubInk.withValues(alpha: 0.8)),
          ),

          const SizedBox(height: 18),

          // 時長：連續「聲波掃描」滑桿（5~10 分鐘）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _MinuteWavePicker(
              options: const [5, 6, 7, 8, 9, 10],
              minute: duration,
              onChanged: (m) => setState(() => duration = m),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isEnglish ? '$duration min' : '$duration 分鐘',
            style: const TextStyle(color: kSubInk, fontWeight: FontWeight.w700),
          ),

          const Spacer(),

          // 底線裝飾
          SizedBox(
            height: 120,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: kSubInk.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 下一步
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _goNextFromSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPill,
                  foregroundColor: kInk,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: Text(widget.isEnglish ? 'Next' : '下一步'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1：開始前提示
  Widget _buildPrepare() {
    final tip =
        (_mode == BreathMode.guided)
            ? (widget.isEnglish
                ? 'Guided awareness breathing. The intro will play this time.'
                : '引導覺察呼吸，本次會播放前言。')
            : (widget.isEnglish
                ? 'Just notice your breath. No guide will play.'
                : '自然覺察呼吸，本次不會播放引導。');

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          widget.isEnglish ? 'Breathing' : '呼吸',
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => setState(() => step = 0),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kInk, width: 1.4),
              ),
              child: const Icon(Icons.arrow_back, color: kInk, size: 18),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                tip,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPill,
                  foregroundColor: kInk,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: Text(widget.isEnglish ? 'Start' : '開始'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2：進行中
  Widget _buildRunning() {
    final title =
        (_mode == BreathMode.guided)
            ? (widget.isEnglish ? 'Guided breathing' : '引導呼吸進行中')
            : (widget.isEnglish ? 'Natural breathing' : '自然呼吸進行中');

    final progress = _remainingSeconds / (duration * 60);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          widget.isEnglish ? 'Breathing' : '呼吸',
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: _stopExercise,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kInk, width: 1.4),
              ),
              child: const Icon(Icons.close, color: kInk, size: 18),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: kInk,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isEnglish
                  ? 'Time Remaining: ${_formatDuration(_remainingSeconds)}'
                  : '剩餘時間：${_formatDuration(_remainingSeconds)}',
              style: const TextStyle(
                color: kSubInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: kPill,
                valueColor: const AlwaysStoppedAnimation<Color>(kInk),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pillButton(
                  label:
                      _isPlaying
                          ? (widget.isEnglish ? 'Pause' : '暫停')
                          : (widget.isEnglish ? 'Resume' : '繼續'),
                  onTap: _togglePause,
                ),
                const SizedBox(width: 16),
                _pillButton(
                  label: widget.isEnglish ? 'End' : '結束',
                  onTap: _stopExercise,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // 3：完成
  Widget _buildDone() {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          widget.isEnglish ? 'Breathing' : '呼吸',
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Text(
                widget.isEnglish ? 'Breathing Completed!' : '呼吸練習完成！',
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEnglish
                    ? 'Duration: $duration min'
                    : '時長：$duration 分鐘',
                style: const TextStyle(
                  color: kSubInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              _pillButton(
                label: widget.isEnglish ? 'Record Feelings' : '記錄感受',
                onTap: () {
                  if (_userId == null) {
                    _toast(
                      widget.isEnglish
                          ? 'User ID not available.'
                          : '無法取得使用者 ID',
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RecordFeelingsScreen(
                            isEnglish: widget.isEnglish,
                            date: DateTime.now(),
                            userId: _userId!,
                            duration: duration,
                            min: duration,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _pillButton(
                label: widget.isEnglish ? 'Back to Home' : '返回首頁',
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => HomeScreen(
                            username: 'User',
                            isEnglish: widget.isEnglish,
                          ),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 元件 =====
  Widget _bigBall({required String label}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: kPill.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: kInk,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _pillButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPill,
        foregroundColor: kInk,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toast(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }
}

/// 連續「聲波掃描」時間選擇器：options 例如 [5,6,7,8,9,10]
/// - 拖動時連續跟手，不吸附
/// - 當前分鐘 = 位置落在哪個區段就是哪個值（即 options[idx]）
/// - 軌道是一串會跟著手指產生波峰的 bar
class _MinuteWavePicker extends StatefulWidget {
  final List<int> options;
  final int minute;
  final ValueChanged<int> onChanged;

  const _MinuteWavePicker({
    required this.options,
    required this.minute,
    required this.onChanged,
  });

  @override
  State<_MinuteWavePicker> createState() => _MinuteWavePickerState();
}

class _MinuteWavePickerState extends State<_MinuteWavePicker> {
  late double _t; // 0..1 連續位置

  @override
  void initState() {
    super.initState();
    final n = widget.options.length;
    final idx = widget.options.indexOf(widget.minute).clamp(0, n - 1);
    _t = (n == 1) ? 0.0 : idx / (n - 1);
  }

  @override
  void didUpdateWidget(covariant _MinuteWavePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minute != widget.minute) {
      final n = widget.options.length;
      final idx = widget.options.indexOf(widget.minute).clamp(0, n - 1);
      setState(() => _t = (n == 1) ? 0.0 : idx / (n - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const double pad = 16; // 左右內縮，避免邊緣裁切
        final double w = c.maxWidth;
        final double usable = (w - pad * 2).clamp(1.0, double.infinity);
        final int n = widget.options.length;

        // 0..1 位置 -> 對應分鐘（區段）
        int minuteFromT(double t) {
          if (n <= 1) return widget.options.first;
          final pos = t * (n - 1); // 0..(n-1)
          final idx = pos.floor().clamp(0, n - 1);
          return widget.options[idx];
        }

        void updateByDx(double dx) {
          final nt = ((dx - pad) / usable).clamp(0.0, 1.0);
          if (nt == _t) return;
          setState(() => _t = nt);
          final m = minuteFromT(nt);
          if (m != widget.minute) widget.onChanged(m);
        }

        return SizedBox(
          height: 48,
          child: Stack(
            children: [
              // 聲波軌道
              Positioned.fill(
                child: CustomPaint(
                  painter: _BarsWavePainter(
                    t: _t,
                    barCount: 41,
                    pad: pad,
                    base: 6,
                    amp: 28,
                    sigmaFactor: 0.12,
                    colorBase: BreathingScreenState.kSubInk.withValues(
                      alpha: 0.40,
                    ),
                    colorPeak: BreathingScreenState.kInk,
                  ),
                ),
              ),
              // 手勢（整條都可拖）
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (d) => updateByDx(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) => updateByDx(d.localPosition.dx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 畫出整條「聲波」：以 t 決定中心位置，使用高斯衰減讓 bar 高度/顏色向兩側遞減
class _BarsWavePainter extends CustomPainter {
  final double t; // 0..1
  final int barCount;
  final double pad;
  final double base;
  final double amp;
  final double sigmaFactor;
  final Color colorBase;
  final Color colorPeak;

  _BarsWavePainter({
    required this.t,
    required this.barCount,
    required this.pad,
    required this.base,
    required this.amp,
    required this.sigmaFactor,
    required this.colorBase,
    required this.colorPeak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final usableW = (size.width - pad * 2).clamp(1.0, double.infinity);
    final centerX = pad + t * usableW;
    final sigma = size.width * sigmaFactor;

    final barPaint = Paint()..strokeCap = StrokeCap.round;
    final bottom = size.height * 0.65;
    final double barW = 4.0;
    final double gap = usableW / (barCount - 1);

    for (int i = 0; i < barCount; i++) {
      final double x = pad + gap * i;

      // 高斯：exp(- (dx^2) / (2 sigma^2))
      final double dx = (x - centerX);
      final double g = math.exp(-(dx * dx) / (2.0 * sigma * sigma)); // 0..1
      final double h = base + amp * g;
      final color = Color.lerp(colorBase, colorPeak, g.clamp(0.0, 1.0))!;

      barPaint
        ..color = color
        ..strokeWidth = barW;

      final double top = bottom - h;
      canvas.drawLine(Offset(x, bottom), Offset(x, top), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsWavePainter old) {
    return t != old.t ||
        barCount != old.barCount ||
        pad != old.pad ||
        base != old.base ||
        amp != old.amp ||
        sigmaFactor != old.sigmaFactor ||
        colorBase != old.colorBase ||
        colorPeak != old.colorPeak;
  }
}
