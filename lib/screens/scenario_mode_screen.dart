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

class _ScenarioModeScreenState extends State<ScenarioModeScreen>
    with SingleTickerProviderStateMixin {
  // ===== Calming Palette =====
  static const Color kBgTop = Color(0xFFEAF6E9);
  static const Color kBgBottom = Color(0xFFD7EBDD);
  static const Color kInk = Color(0xFF2E5F3A);
  static const Color kSubInk = Color(0xFF587565);
  static const Color kPill = Color(0xFFEFF6EE);
  static const Color kAccent = Color(0xFF89BFA2);

  late Timer _timer;
  DateTime _dateTime = DateTime.now();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int currentIndex = 0;

  late final AnimationController _vizCtrl;

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
    {
      'title': '藍鵲清晨鳥鳴',
      'englishTitle': 'Taiwan Blue Magpie Dawn Calls',
      'file': 'assets/scenario_music/taiwan-blue-magpie-dawn-calls.mp3',
      'liked': false,
    },
    {
      'title': '窗邊雨聲·白噪音',
      'englishTitle': 'Rain on Window · White Noise',
      'file': 'assets/scenario_music/rain-on-window-white-noise.mp3',
      'liked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _dateTime = DateTime.now());
    });

    _vizCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    _vizCtrl.dispose();
    super.dispose();
  }

  // ===== Helpers (以檔名為唯一鍵) =====
  int _indexByFile(String file) =>
      musicList.indexWhere((m) => m['file'] == file);

  // ===== Favorites =====
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicList = musicList
          .map((m) => {...m, 'liked': prefs.getBool(m['title']) ?? m['liked']})
          .toList();
      _sortMusicList();
    });
  }

  Future<void> _toggleFavoriteByFile(String file) async {
    final prefs = await SharedPreferences.getInstance();

    // 記住目前播放的曲目檔案，避免排序後 currentIndex 跳走
    final String? playingFile =
        (currentIndex >= 0 && currentIndex < musicList.length)
        ? musicList[currentIndex]['file'] as String
        : null;

    final i = _indexByFile(file);
    if (i < 0) return;

    setState(() {
      musicList[i]['liked'] = !(musicList[i]['liked'] == true);
      prefs.setBool(musicList[i]['title'], musicList[i]['liked']);
      _sortMusicList();

      if (playingFile != null) {
        final newIdx = _indexByFile(playingFile);
        if (newIdx != -1) currentIndex = newIdx; // 保持現在播放曲目不變
      }
    });
  }

  void _sortMusicList() {
    musicList.sort((a, b) {
      if (a['liked'] && !b['liked']) return -1;
      if (!a['liked'] && b['liked']) return 1;
      return (a['englishTitle'] as String).toLowerCase().compareTo(
        (b['englishTitle'] as String).toLowerCase(),
      );
    });
  }

  // ===== Audio =====
  Future<void> _playMusic(int index) async {
    final isSame = index == currentIndex;
    setState(() {
      currentIndex = index;
      isPlaying = isSame ? !isPlaying : true;
    });

    if (isPlaying) {
      await _audioPlayer.play(
        AssetSource(musicList[index]['file'].replaceFirst('assets/', '')),
      );
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> _playMusicByFile(String file) async {
    final i = _indexByFile(file);
    if (i >= 0) {
      await _playMusic(i);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    // 注意：這裡不重新排序，只是複製目前順序（musicList 已在 setState 時排序）
    final sortedList = [...musicList];

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;
    final double clockCardHeight = isTablet ? 260 : 220;

    final String currentFile = sortedList[currentIndex]['file'];
    final bool currentLiked = sortedList[currentIndex]['liked'] == true;

    return Scaffold(
      backgroundColor: kBgBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kInk,
        title: Text(
          widget.isEnglish ? 'Scenario Mode' : '情境模式',
          style: t.textTheme.titleLarge?.copyWith(
            color: kInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgTop, kBgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // === Clock Card ===
                _softCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: SizedBox(
                    height: clockCardHeight,
                    child: _ClockPanel(
                      dateTime: _dateTime,
                      dialColor: Colors.white.withValues(alpha: 0.82),
                      ringColor: kAccent.withValues(alpha: 0.45),
                      tickColor: kInk.withValues(alpha: 0.55),
                      hourMinuteColor: kInk,
                      secondColor: kAccent,
                      hubColor: kAccent,
                      timeStyle: t.textTheme.titleMedium?.copyWith(
                        color: kInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Now Playing + Controls ===
                _softCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.isEnglish ? 'Now Playing' : '正在播放',
                          style: t.textTheme.labelLarge?.copyWith(
                            color: kSubInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isEnglish
                            ? sortedList[currentIndex]['englishTitle']
                            : sortedList[currentIndex]['title'],
                        textAlign: TextAlign.center,
                        style: t.textTheme.titleMedium?.copyWith(
                          color: kInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _pillButton(
                              icon: currentLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: widget.isEnglish
                                  ? (currentLiked ? 'Liked' : 'Like')
                                  : (currentLiked ? '已收藏' : '收藏'),
                              filled: currentLiked,
                              onTap: () => _toggleFavoriteByFile(currentFile),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pillButton(
                              icon: isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              label: widget.isEnglish
                                  ? (isPlaying ? 'Pause' : 'Play')
                                  : (isPlaying ? '暫停' : '播放'),
                              onTap: () => _playMusic(currentIndex),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pillButton(
                              icon: Icons.queue_music_rounded,
                              label: widget.isEnglish ? 'List' : '清單',
                              onTap: () async {
                                // 傳回 file，而不是 index，避免排序影響
                                final resultFile = await showModalBottomSheet<String>(
                                  context: context,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.92,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  builder: (context) {
                                    // 用 StatefulBuilder 讓底單內心形按鈕能即時刷新
                                    return StatefulBuilder(
                                      builder: (context, sbSet) {
                                        final localList = [...musicList];
                                        return ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          itemCount: localList.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, i) {
                                            final file = localList[i]['file'];
                                            final liked =
                                                localList[i]['liked'] == true;
                                            final isCurrent =
                                                file ==
                                                musicList[currentIndex]['file'];
                                            return ListTile(
                                              leading: IconButton(
                                                icon: Icon(
                                                  liked
                                                      ? Icons.favorite
                                                      : Icons
                                                            .favorite_border_rounded,
                                                  color: liked
                                                      ? kAccent
                                                      : kSubInk.withValues(
                                                          alpha: 0.6,
                                                        ),
                                                ),
                                                onPressed: () async {
                                                  await _toggleFavoriteByFile(
                                                    file,
                                                  );
                                                  // 更新底單畫面
                                                  sbSet(() {});
                                                },
                                                tooltip: widget.isEnglish
                                                    ? (liked
                                                          ? 'Unlike'
                                                          : 'Like')
                                                    : (liked ? '取消收藏' : '收藏'),
                                              ),
                                              title: Text(
                                                widget.isEnglish
                                                    ? localList[i]['englishTitle']
                                                    : localList[i]['title'],
                                                style: TextStyle(
                                                  color: kInk,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.play_arrow_rounded,
                                                ),
                                                color: kInk,
                                                onPressed: () {
                                                  Navigator.pop<String>(
                                                    context,
                                                    file,
                                                  );
                                                },
                                              ),
                                              onTap: () {
                                                Navigator.pop<String>(
                                                  context,
                                                  file,
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                                if (resultFile != null) {
                                  await _playMusicByFile(resultFile);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isEnglish ? 'Music Selection' : '音樂選擇',
                    style: t.textTheme.titleMedium?.copyWith(
                      color: kInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ===== 下方區域：播放中 → Ambient 視覺面板；未播放 → 清單 =====
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: isPlaying
                        ? _AmbientPanel(
                            key: const ValueKey('ambient'),
                            controller: _vizCtrl,
                            ink: kInk,
                            subInk: kSubInk,
                            accent: kAccent,
                            pill: kPill,
                            isEnglish: widget.isEnglish,
                          )
                        : ListView.separated(
                            key: const ValueKey('list'),
                            itemCount: sortedList.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final file = sortedList[index]['file'];
                              final liked = sortedList[index]['liked'] == true;
                              final isCurrent =
                                  file == sortedList[currentIndex]['file'];
                              return _softCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    _circleIcon(
                                      isCurrent
                                          ? Icons.graphic_eq_rounded
                                          : Icons.play_arrow_rounded,
                                      bg: isCurrent
                                          ? kAccent.withValues(alpha: 0.20)
                                          : kPill,
                                      fg: isCurrent ? kInk : kSubInk,
                                      onTap: () => _playMusicByFile(file),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.isEnglish
                                                ? sortedList[index]['englishTitle']
                                                : sortedList[index]['title'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.textTheme.titleSmall
                                                ?.copyWith(
                                                  color: kInk,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w900
                                                      : FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isCurrent
                                                ? (widget.isEnglish
                                                      ? 'Playing'
                                                      : '播放中')
                                                : (widget.isEnglish
                                                      ? 'Tap to play'
                                                      : '點擊播放'),
                                            style: t.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: kSubInk.withValues(
                                                    alpha: isCurrent
                                                        ? 0.9
                                                        : 0.7,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        liked
                                            ? Icons.favorite
                                            : Icons.favorite_border_rounded,
                                        color: liked ? kAccent : kSubInk,
                                      ),
                                      onPressed: () =>
                                          _toggleFavoriteByFile(file),
                                      tooltip: widget.isEnglish
                                          ? (liked ? 'Unlike' : 'Like')
                                          : (liked ? '取消收藏' : '收藏'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _softCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  static Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? kAccent : kPill,
        foregroundColor: filled ? Colors.white : kInk,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  static Widget _circleIcon(
    IconData icon, {
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg),
      ),
    );
  }
}

/// 自適應鐘面
class _ClockPanel extends StatelessWidget {
  final DateTime dateTime;
  final Color dialColor;
  final Color ringColor;
  final Color tickColor;
  final Color hourMinuteColor;
  final Color secondColor;
  final Color hubColor;
  final TextStyle? timeStyle;

  const _ClockPanel({
    required this.dateTime,
    required this.dialColor,
    required this.ringColor,
    required this.tickColor,
    required this.hourMinuteColor,
    required this.secondColor,
    required this.hubColor,
    this.timeStyle,
  });

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const double pad = 8;
        const double textReserve = 28;

        final double w = (c.maxWidth - pad * 2);
        final double h = (c.maxHeight - textReserve - pad);
        final double maxSquare = w.isFinite && h.isFinite
            ? (w < 0 || h < 0 ? 0.0 : min(w, h))
            : 0.0;

        return Column(
          children: [
            Expanded(
              child: Center(
                child: CustomPaint(
                  size: Size.square(maxSquare),
                  painter: CalmingClockPainter(
                    dateTime,
                    dialColor: dialColor,
                    ringColor: ringColor,
                    tickColor: tickColor,
                    hourMinuteColor: hourMinuteColor,
                    secondColor: secondColor,
                    hubColor: hubColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(_fmt(dateTime), style: timeStyle),
          ],
        );
      },
    );
  }
}

/// Calming style Clock painter
class CalmingClockPainter extends CustomPainter {
  final DateTime dateTime;

  final Color dialColor;
  final Color ringColor;
  final Color tickColor;
  final Color hourMinuteColor;
  final Color secondColor;
  final Color hubColor;

  CalmingClockPainter(
    this.dateTime, {
    required this.dialColor,
    required this.ringColor,
    required this.tickColor,
    required this.hourMinuteColor,
    required this.secondColor,
    required this.hubColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final dialPaint = Paint()
      ..color = dialColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius - 2, ringPaint);

    final bigTick = Paint()
      ..color = tickColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final smallTick = Paint()
      ..color = tickColor.withValues(alpha: 0.70)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final double angle = (pi / 30) * i;
      final double cosA = cos(angle - pi / 2);
      final double sinA = sin(angle - pi / 2);
      final bool isBig = i % 5 == 0;
      final double inner = radius * (isBig ? 0.83 : 0.88);
      final double outer = radius * 0.97;

      final start = Offset(center.dx + inner * cosA, center.dy + inner * sinA);
      final end = Offset(center.dx + outer * cosA, center.dy + outer * sinA);
      canvas.drawLine(start, end, isBig ? bigTick : smallTick);
    }

    final hourAngle =
        ((dateTime.hour % 12) + dateTime.minute / 60) * 30 * pi / 180;
    final minuteAngle = (dateTime.minute + dateTime.second / 60) * 6 * pi / 180;
    final secondAngle = dateTime.second * 6 * pi / 180;

    final handPaint = Paint()
      ..color = hourMinuteColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final hourHand = Offset(
      center.dx + radius * 0.52 * cos(hourAngle - pi / 2),
      center.dy + radius * 0.52 * sin(hourAngle - pi / 2),
    );
    final minuteHand = Offset(
      center.dx + radius * 0.72 * cos(minuteAngle - pi / 2),
      center.dy + radius * 0.72 * sin(minuteAngle - pi / 2),
    );

    canvas.drawLine(center, hourHand, handPaint);
    canvas.drawLine(center, minuteHand, handPaint..strokeWidth = 4);

    final secPaint = Paint()
      ..color = secondColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final secondHand = Offset(
      center.dx + radius * 0.80 * cos(secondAngle - pi / 2),
      center.dy + radius * 0.80 * sin(secondAngle - pi / 2),
    );
    final tail = Offset(
      center.dx - radius * 0.15 * cos(secondAngle - pi / 2),
      center.dy - radius * 0.15 * sin(secondAngle - pi / 2),
    );
    canvas.drawLine(tail, secondHand, secPaint);

    final hub = Paint()..color = hubColor;
    canvas.drawCircle(center, 4.5, hub);
    final hubHalo = Paint()..color = hubColor.withValues(alpha: 0.18);
    canvas.drawCircle(center, 9, hubHalo);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// ===== Ambient 擴充面板（播放時顯示）=====
class _AmbientPanel extends StatelessWidget {
  final Animation<double> controller;
  final Color ink;
  final Color subInk;
  final Color accent;
  final Color pill;
  final bool isEnglish;

  const _AmbientPanel({
    super.key,
    required this.controller,
    required this.ink,
    required this.subInk,
    required this.accent,
    required this.pill,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WavesPainter(
                  phase: controller.value * 2 * pi,
                  base: accent.withValues(alpha: 0.25),
                  mid: accent.withValues(alpha: 0.18),
                  light: accent.withValues(alpha: 0.12),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnglish ? 'Focus on your breath' : '把注意力放在呼吸上',
                    style: t.textTheme.titleSmall?.copyWith(
                      color: subInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEnglish
                        ? 'Inhale… hold… exhale…\nLet the sound carry you.'
                        : '吸氣… 停留… 呼氣…\n讓聲音帶著你漂流。',
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: ink.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: pill,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isEnglish ? 'Playing ambient visuals' : '播放中 · 沉浸視覺',
                        style: t.textTheme.labelLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 柔和多層波紋
class _WavesPainter extends CustomPainter {
  final double phase;
  final Color base;
  final Color mid;
  final Color light;

  _WavesPainter({
    required this.phase,
    required this.base,
    required this.mid,
    required this.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    void drawWave({
      required double amp,
      required double freq,
      required double speed,
      required double yOffset,
      required Color color,
    }) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()..moveTo(0, h);

      for (double x = 0; x <= w; x += 2) {
        final y =
            h * yOffset + amp * sin((x / w) * 2 * pi * freq + phase * speed);
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, paint);
    }

    drawWave(amp: h * 0.06, freq: 1.2, speed: 1.0, yOffset: 0.70, color: base);
    drawWave(amp: h * 0.05, freq: 1.6, speed: 1.6, yOffset: 0.75, color: mid);
    drawWave(
      amp: h * 0.045,
      freq: 2.1,
      speed: 2.2,
      yOffset: 0.80,
      color: light,
    );
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.base != base ||
        oldDelegate.mid != mid ||
        oldDelegate.light != light;
  }
}
