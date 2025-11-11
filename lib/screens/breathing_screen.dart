import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'record_feelings_screen.dart';
import '/utils/config.dart';

class BreathingScreen extends StatefulWidget {
  final bool isEnglish;
  const BreathingScreen({super.key, this.isEnglish = false});

  @override
  BreathingScreenState createState() => BreathingScreenState();
}

enum BreathMode { natural, guided }

class BreathingScreenState extends State<BreathingScreen> {
  // 調色盤
  static const Color kBg = Color(0xFFDDEBD7);
  static const Color kInk = Color(0xFF2E5F3A);
  static const Color kSubInk = Color(0xFF5E7F6A);
  static const Color kPill = Color(0xFFE7F1E3);

  // 葉子圖
  static const String kLeafAsset = 'assets/picture/fullleaf.png';
  static const String kHalfLeafAsset = 'assets/picture/halfleaf.png';

  BreathMode _mode = BreathMode.natural;

  // 時長（分）— 5~10
  int duration = 5;

  // 流程
  int step = 0; // 0 選模式；1 準備；2 進行；3 完成

  // 音訊/計時
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  Timer? _timer;
  bool _isPlaying = false;
  int _remainingSeconds = 0;

  // ✅ 實際跑的秒數
  int _elapsedSeconds = 0;

  // 引導模式：是否播放前言（由對話框決定）
  bool _guidedPlayIntro = false;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setVolume(1.0);
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _getUserIdFromFirebase();
  }

  Future<void> _getUserIdFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final base = getBaseUrl();
      final url = '$base/get_user_id';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'firebase_uid': uid}),
          )
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final v = data['user_id'];
        if (v != null) setState(() => _userId = v.toString());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelAudioCompleteSub();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ====== 音訊控制 ======
  void _cancelAudioCompleteSub() {
    _completeSub?.cancel();
    _completeSub = null;
  }

  Future<void> _playOnce(String assetPath) async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.play(AssetSource(assetPath));
  }

  Future<void> _playBrownLoop() async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(
      AssetSource('scenario_music/relaxing-smoothed-brown-noise.mp3'),
    );
  }

  void _onceThen(Future<void> Function() next) {
    _cancelAudioCompleteSub();
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) async {
      if (!mounted || step != 2 || !_isPlaying) return;
      await next();
    });
  }

  /// 開始依模式播放：
  /// - natural: 直接循環 brown noise
  /// - guided : 依使用者選擇
  ///     - 播放前言：intro → guide → 循環 brown noise
  ///     - 略過前言：guide → 循環 brown noise
  Future<void> _playAudioForCurrentMode() async {
    _cancelAudioCompleteSub();
    try {
      if (_mode == BreathMode.natural) {
        // ✅ 只循環環境音
        await _playBrownLoop();
      } else {
        // ✅ 引導模式：先依選擇播放
        if (_guidedPlayIntro) {
          await _playOnce('breath/intro.mp3');
          _onceThen(() async {
            await _playOnce('breath/guide.mp3');
            _onceThen(() async {
              await _playBrownLoop();
            });
          });
        } else {
          await _playOnce('breath/guide.mp3');
          _onceThen(() async {
            await _playBrownLoop();
          });
        }
      }
    } catch (_) {
      _toast(widget.isEnglish ? 'Failed to play audio' : '無法播放音檔');
    }
  }

  // ====== 流程控制 ======
  void _goNextFromSelect() {
    setState(() => step = 1);
  }

  Future<void> _startExercise() async {
    // 引導模式：先詢問是否播放前言
    if (_mode == BreathMode.guided) {
      final ans = await _askPlayIntroDialog();
      if (ans == null) return; // 使用者關閉對話框，不啟動
      _guidedPlayIntro = ans;
    } else {
      _guidedPlayIntro = false;
    }

    _elapsedSeconds = 0; // ✅ 重置實際時長
    setState(() {
      step = 2;
      _isPlaying = true;
      _remainingSeconds = duration * 60;
    });

    // 依模式啟動音訊
    await _playAudioForCurrentMode();
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

  void _togglePause() async {
    setState(() {
      if (_isPlaying) {
        _audioPlayer.pause(); // 暫停音訊
        _timer?.cancel(); // 停止計時
      } else {
        if (_remainingSeconds > 0) {
          _audioPlayer.resume(); // 恢復音訊
          _startTimer(); // 恢復計時
        }
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _stopExercise() {
    _cancelAudioCompleteSub();
    _audioPlayer.stop();
    _timer?.cancel();

    // ✅ 實際跑的秒數：總秒數 - 剩餘秒數（安全夾取）
    final total = duration * 60;
    final ran = (total - _remainingSeconds);
    _elapsedSeconds = ran.clamp(0, total);

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

  // ---- 綠色底色 + 葉子鋪滿高度（不裁切、不過度放大）+ 透明 Scaffold 疊上層 ----
  Widget _bgFrame({
    required PreferredSizeWidget appBar,
    required Widget body,
    Widget? bottomNav,
    String imageAsset = kHalfLeafAsset, // 想用整張葉子就改成 kLeafAsset
  }) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: kBg)), // 最底層綠色
        // 葉子背景：以「高度」為基準鋪滿，寬度多出/不足處用綠色底色補
        Positioned.fill(
          child: IgnorePointer(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fitHeight, // 撐滿「高度」，不裁切
                alignment: Alignment.bottomCenter, // 葉子錨在底部
                child: Image.asset(
                  imageAsset,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),

        // 你的 UI 疊在最上層
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNav,
        ),
      ],
    );
  }

  // 0：模式選擇
  Widget _buildSelectMode() {
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
      body: _scrollWrap(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
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
              clipBehavior: Clip.antiAlias,
              child: _ModeWheel(
                isEnglish: widget.isEnglish,
                initial: _mode,
                onChanged: (m) {
                  if (_mode != m) {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = m);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isEnglish ? 'Swipe up/down to switch' : '上下滑動可切換模式',
              style: TextStyle(color: kSubInk.withValues(alpha: 0.8)),
            ),
            _leafStrip(
              kLeafAsset,
              padding: const EdgeInsets.only(top: 12, bottom: 8),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _MinuteWavePicker(
                options: const [5, 6, 7, 8, 9, 10],
                minute: duration,
                onChanged: (m) => setState(() => duration = m),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEnglish ? '$duration min' : '$duration 分鐘',
              style: const TextStyle(
                color: kSubInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 2, color: kSubInk.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            SizedBox(
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
          ],
        ),
      ),
    );
  }

  // 葉子條（只用在選擇頁）
  Widget _leafStrip(
    String asset, {
    EdgeInsets padding = const EdgeInsets.only(top: 12, bottom: 8),
  }) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Image.asset(
          asset,
          fit: BoxFit.fitWidth,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  // 1：準備頁 —— 全屏葉子 + 內容完全置中
  Widget _buildPrepare() {
    final tip = (_mode == BreathMode.guided)
        ? (widget.isEnglish
              ? 'Guided awareness breathing. The intro will play this time.'
              : '引導覺察呼吸，本次會播放前言。')
        : (widget.isEnglish
              ? 'Just notice your breath. No guide will play.'
              : '自然覺察呼吸，本次不會播放引導。');

    return _bgFrame(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              tip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kInk,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
      bottomNav: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: _pillIconButton(
                  icon: Icons.play_arrow_rounded,
                  label: widget.isEnglish ? 'Start' : '開始',
                  onTap: _startExercise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2：進行中 —— 全屏葉子 + 標題/時間/進度條完全置中
  Widget _buildRunning() {
    final title = (_mode == BreathMode.guided)
        ? (widget.isEnglish ? 'Guided breathing' : '引導呼吸進行中')
        : (widget.isEnglish ? 'Natural breathing' : '自然呼吸進行中');

    final progress = _remainingSeconds / (duration * 60);

    return _bgFrame(
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isEnglish
                      ? 'Time Remaining: ${_formatDuration(_remainingSeconds)}'
                      : '剩餘時間：${_formatDuration(_remainingSeconds)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kSubInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: kPill,
                      valueColor: const AlwaysStoppedAnimation<Color>(kInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNav: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: _pillIconButton(
                  icon: _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: _isPlaying
                      ? (widget.isEnglish ? 'Pause' : '暫停')
                      : (widget.isEnglish ? 'Resume' : '繼續'),
                  onTap: _togglePause,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pillIconButton(
                  icon: Icons.stop_rounded,
                  label: widget.isEnglish ? 'End' : '結束',
                  onTap: _stopExercise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3：完成（保留）
  Widget _buildDone() {
    final completeHint = widget.isEnglish
        ? 'Take a moment to note how you feel after breathing.'
        : '花一點時間記下呼吸後的感受。';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.isEnglish ? 'Breathing Completed!' : '呼吸練習完成！',
              style: const TextStyle(
                color: kInk,
                fontWeight: FontWeight.w900,
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // ✅ 顯示實際時長（mm:ss）
            Text(
              widget.isEnglish
                  ? 'Duration: ${_formatDuration(_elapsedSeconds)}'
                  : '時長：${_formatDuration(_elapsedSeconds)}',
              style: const TextStyle(
                color: kSubInk,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: kPill,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, color: kInk),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      completeHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () async {
                if (_userId == null) {
                  await _getUserIdFromFirebase();
                }
                if (_userId == null) {
                  _toast(
                    widget.isEnglish ? 'User ID not available.' : '無法取得使用者 ID',
                  );
                  return;
                }
                if (!mounted) return;

                // ✅ 導頁時帶「實際分鐘」
                final actualMinutes = (_elapsedSeconds / 60).round();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordFeelingsScreen(
                      isEnglish: widget.isEnglish,
                      date: DateTime.now(),
                      userId: _userId!,
                      duration: actualMinutes, // ✅ 實際分鐘
                      min: actualMinutes, // ✅ 實際分鐘
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPill,
                foregroundColor: kInk,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(widget.isEnglish ? 'Record Feelings' : '記錄感受'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      username: 'User',
                      isEnglish: widget.isEnglish,
                    ),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPill,
                foregroundColor: kInk,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(widget.isEnglish ? 'Back to Home' : '返回首頁'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 對話框：是否播放前言 =====
  Future<bool?> _askPlayIntroDialog() {
    final title = widget.isEnglish ? 'Play Intro?' : '要播放前言嗎？';
    final desc = widget.isEnglish
        ? 'A short intro to breathing relaxation—recommended for your first session.'
        : '這是一段介紹呼吸放鬆的前言喲~建議你第一次聽聽看~';
    final yes = widget.isEnglish ? 'Play Intro' : '播放前言';
    final no = widget.isEnglish ? 'Skip Intro' : '略過前言';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: kPill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          content: Text(
            desc,
            style: const TextStyle(
              color: kSubInk,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.record_voice_over_rounded, size: 20),
                    label: Text(yes),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPill,
                      foregroundColor: kInk,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      side: const BorderSide(color: kInk, width: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    icon: const Icon(Icons.skip_next_rounded, size: 20),
                    label: Text(no),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPill,
                      foregroundColor: kInk,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      side: const BorderSide(color: kInk, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ===== 共用小元件 =====
  Widget _pillIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPill,
        foregroundColor: kInk,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  // 捲動包裝（選擇頁使用）
  Widget _scrollWrap({required EdgeInsets padding, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
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

/// 🛞 兩列的圓形滾輪
class _ModeWheel extends StatefulWidget {
  final bool isEnglish;
  final BreathMode initial;
  final ValueChanged<BreathMode> onChanged;

  const _ModeWheel({
    required this.isEnglish,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_ModeWheel> createState() => _ModeWheelState();
}

class _ModeWheelState extends State<_ModeWheel> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    final initIndex = widget.initial == BreathMode.natural ? 0 : 1;
    _ctrl = FixedExtentScrollController(initialItem: initIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _labelFor(BreathMode m) {
    if (widget.isEnglish) return m == BreathMode.natural ? 'Natural' : 'Guided';
    return m == BreathMode.natural ? '自然呼吸' : '引導呼吸';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 18,
          right: 18,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BreathingScreenState.kSubInk.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: _ctrl,
          itemExtent: 44,
          diameterRatio: 1.8,
          perspective: 0.003,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            final m = index == 0 ? BreathMode.natural : BreathMode.guided;
            widget.onChanged(m);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: 2,
            builder: (context, index) {
              final mode = index == 0 ? BreathMode.natural : BreathMode.guided;
              final isSelected = _ctrl.selectedItem == index;
              return Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: isSelected
                        ? BreathingScreenState.kInk
                        : BreathingScreenState.kSubInk.withValues(alpha: 0.55),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: isSelected ? 18 : 16,
                  ),
                  child: Text(_labelFor(mode)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 連續「聲波掃描」時間選擇器
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
  late double _t; // 0..1

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
        const double pad = 16;
        final double w = c.maxWidth;
        final double usable = (w - pad * 2).clamp(1.0, double.infinity);
        final int n = widget.options.length;

        int minuteFromT(double t) {
          if (n <= 1) return widget.options.first;
          final pos = t * (n - 1);
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

/// 畫出整條「聲波」
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

      final double dx = (x - centerX);
      final double g = math.exp(-(dx * dx) / (2.0 * sigma * sigma));
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
