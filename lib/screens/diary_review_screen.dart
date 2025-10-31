import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'diary_locked_screen.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';
import '../utils/api_client.dart';
import 'search_diary_screen.dart';

class DiaryReviewScreen extends StatefulWidget {
  final bool isDiaryLocked;
  final String? diaryPassword;
  final bool isEnglish;

  const DiaryReviewScreen({
    super.key,
    required this.isDiaryLocked,
    this.diaryPassword,
    this.isEnglish = false,
  });

  @override
  DiaryReviewScreenState createState() => DiaryReviewScreenState();
}

class DiaryReviewScreenState extends State<DiaryReviewScreen>
    with SingleTickerProviderStateMixin {
  static const Color kBg = Color(0xFFDDEBD7);
  static const Color kInk = Color(0xFF2E5F3A);
  static const Color kSubInk = Color(0xFF5E7F6A);
  static const Color kPillBg = Color(0xFFE7F1E3);

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<DiaryEntry> _diaryEntries = [];
  Map<DateTime, String> _dayColors = {};
  List<BreathRecord> _breathRecords = [];
  final ApiClient _apiClient = ApiClient();

  late final AnimationController _fillCtrl;
  bool _shouldAnimate = false;
  DateTime? _animDate;
  Color? _animColor;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries(_selectedDay);
    _loadAllDayColors();
    _loadBreathRecords(_selectedDay);

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['animate'] == true) {
        final DateTime? d = args['date'] as DateTime?;
        final String? hex = args['color'] as String?;
        if (d != null && hex != null && hex.trim().isNotEmpty) {
          setState(() {
            _shouldAnimate = true;
            _animDate = DateTime(d.year, d.month, d.day);
            _animColor = _hexToColor(hex);
            _selectedDay = _animDate!;
            _focusedDay = _animDate!;
          });
          _fillCtrl
              .forward(from: 0)
              .whenComplete(() => setState(() => _shouldAnimate = false));
        }
      }
    });
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryEntries(DateTime date) async {
    try {
      final entries = await _apiClient.getDiaryEntriesByDate(date);
      if (!mounted) return;
      setState(() => _diaryEntries = entries);
    } catch (e) {
      if (kDebugMode) print('Error loading diary entries: $e');
    }
  }

  Future<void> _loadAllDayColors() async {
    try {
      final allEntries = await _apiClient.getAllDiaryEntries();
      final dayColors = <DateTime, String>{};
      for (var entry in allEntries) {
        if (entry.type == 'Day' && entry.mixedColor != null) {
          final key = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          dayColors[key] = entry.mixedColor!;
        }
      }
      if (!mounted) return;
      setState(() => _dayColors = dayColors);
    } catch (e) {
      if (kDebugMode) print('Error loading day colors: $e');
    }
  }

  Future<void> _loadBreathRecords(DateTime date) async {
    try {
      final records = await _apiClient.getBreathRecordsByDate(date);
      if (!mounted) return;
      setState(() => _breathRecords = records);
    } catch (e) {
      if (kDebugMode) print('Error loading breath records: $e');
    }
  }

  Color _getColorForDay(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final hex = _dayColors[key];
    if (hex != null) {
      try {
        var s = hex.replaceAll('#', '');
        if (s.length == 6) s = 'FF$s';
        return Color(int.parse('0x$s'));
      } catch (_) {}
    }
    return kPillBg;
  }

  Color _hexToColor(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x')) s = s.substring(2);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  Widget _buildDayContainer(
    DateTime date, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final baseColor = _getColorForDay(date);
    final bool isTarget =
        _shouldAnimate &&
        _animDate != null &&
        date.year == _animDate!.year &&
        date.month == _animDate!.month &&
        date.day == _animDate!.day;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isToday && !isSelected ? kPillBg : baseColor,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: kInk, width: 2)
                    : Border.all(color: Colors.black12, width: 0.5),
              ),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : kInk,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (isTarget && _animColor != null)
              AnimatedBuilder(
                animation: _fillCtrl,
                builder: (_, _) {
                  final scale = Curves.easeOut.transform(_fillCtrl.value);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _animColor!.withValues(
                          alpha: 0.15 + 0.85 * _fillCtrl.value,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeafDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: Image.asset(
          'assets/picture/fullleaf.png',
          fit: BoxFit.fitWidth,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  List<Widget> _buildMomentTiles() {
    final momentEntries = _diaryEntries
        .where((entry) => entry.type == 'Moment')
        .toList();
    if (momentEntries.isEmpty) {
      return [
        Text(
          widget.isEnglish ? 'No moment entries for this date.' : '此日期無當下感受記錄。',
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
      ];
    }
    return momentEntries.map((entry) {
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: kPillBg,
          child: Icon(Icons.notes, color: kInk, size: 18),
        ),
        title: Text(
          '${entry.time} ${entry.emotions.map((e) => e['emotion']).join(', ')}',
          style: const TextStyle(color: kInk),
        ),
        subtitle: Text(
          entry.moodText ?? (widget.isEnglish ? 'No text' : '無文字'),
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MomentFeelingsScreen(
                isEnglish: widget.isEnglish,
                date: entry.date,
                isReadOnly: true,
                emotions: entry.emotions,
                mixedColor: entry.mixedColor,
                moodText: entry.moodText,
                details: entry.details,
              ),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildDaySection() {
    final dayEntry = _diaryEntries.firstWhere(
      (entry) => entry.type == 'Day',
      orElse: () => DiaryEntry(
        id: -1,
        date: _selectedDay,
        time: '',
        type: 'Day',
        emotions: [],
        mixedColor: null,
        moodText: null,
        details: null,
        isEnglish: widget.isEnglish,
      ),
    );

    if (dayEntry.id == -1) {
      return [
        Text(
          widget.isEnglish ? 'No day entry for this date.' : '此日期無整天感受記錄。',
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
      ];
    }

    return [
      ListTile(
        leading: const CircleAvatar(
          backgroundColor: kPillBg,
          child: Icon(Icons.event_note, color: kInk, size: 18),
        ),
        title: Text(
          dayEntry.emotions.map((e) => e['emotion']).join(', '),
          style: const TextStyle(color: kInk),
        ),
        subtitle: Text(
          dayEntry.moodText ?? (widget.isEnglish ? 'No text' : '無文字'),
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DayFeelingsScreen(
                isEnglish: widget.isEnglish,
                date: dayEntry.date,
                isReadOnly: true,
                emotions: dayEntry.emotions,
                mixedColor: dayEntry.mixedColor,
                moodText: dayEntry.moodText,
                details: dayEntry.details,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildBreathSection() {
    if (_breathRecords.isEmpty) {
      return [
        Text(
          widget.isEnglish
              ? 'No breathing records for this date.'
              : '此日期無呼吸記錄。',
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
      ];
    }
    return _breathRecords.map((record) {
      final time = record.recordTime;
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: kPillBg,
          child: Icon(Icons.self_improvement, color: kInk, size: 18),
        ),
        title: Text(
          '🕒 $time - ${widget.isEnglish ? '${record.min} minutes' : '${record.min} 分鐘'}',
          style: const TextStyle(color: kInk),
        ),
        subtitle: Text(
          record.feeling ??
              (widget.isEnglish ? 'No feeling recorded' : '無感受記錄'),
          style: TextStyle(color: kSubInk.withValues(alpha: 0.9)),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDiaryLocked) {
      return DiaryLockedScreen(
        diaryPassword: widget.diaryPassword ?? '',
        isEnglish: widget.isEnglish,
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        automaticallyImplyLeading: false, // ← 移除左上角返回與其功能
        title: Text(widget.isEnglish ? 'Diary Review' : '本子回顧'),
        titleTextStyle: const TextStyle(
          color: kInk,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: kInk),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: kInk),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchDiaryScreen(isEnglish: widget.isEnglish),
                ),
              );
            },
            tooltip: widget.isEnglish ? 'Search' : '搜尋',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_shouldAnimate)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: AnimatedBuilder(
                          animation: _fillCtrl,
                          builder: (_, _) {
                            final opacity =
                                1.0 - Curves.easeOut.transform(_fillCtrl.value);
                            final dy = 8 * _fillCtrl.value;
                            return Opacity(
                              opacity: opacity.clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(0, -dy),
                                child: Text(
                                  widget.isEnglish
                                      ? 'Saved to Diary!'
                                      : '已存入本子！',
                                  style: const TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: kInk,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _shouldAnimate = false;
                        });
                        _loadDiaryEntries(selectedDay);
                        _loadBreathRecords(selectedDay);
                      },
                      calendarFormat: CalendarFormat.month,
                      locale: widget.isEnglish ? 'en_US' : 'zh_TW',
                      calendarStyle: const CalendarStyle(
                        isTodayHighlighted: false,
                        defaultDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        weekendDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        outsideDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        rangeHighlightColor: Colors.transparent,
                        withinRangeDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        rangeStartDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        rangeEndDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle: const TextStyle(
                          color: kInk,
                          fontWeight: FontWeight.w600,
                        ),
                        formatButtonVisible: true,
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: kInk,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: kInk,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: kSubInk,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: kSubInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        todayBuilder: (context, date, _) =>
                            _buildDayContainer(date, isToday: true),
                        selectedBuilder: (context, date, _) =>
                            _buildDayContainer(date, isSelected: true),
                        defaultBuilder: (context, date, _) =>
                            _buildDayContainer(date),
                        outsideBuilder: (context, date, _) =>
                            _buildDayContainer(date),
                        disabledBuilder: (context, date, _) =>
                            _buildDayContainer(date),
                      ),
                    ),
                  ),
                  _buildLeafDivider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEnglish
                              ? 'Moment Feelings (${_diaryEntries.where((e) => e.type == "Moment").length} entries)'
                              : '當下感受（${_diaryEntries.where((e) => e.type == "Moment").length} 筆記錄）',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._buildMomentTiles(),
                        const SizedBox(height: 20),
                        Text(
                          widget.isEnglish ? 'Day Feelings' : '整天感受',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._buildDaySection(),
                        const SizedBox(height: 20),
                        Text(
                          widget.isEnglish
                              ? 'Breathing Records (${_breathRecords.length} entries)'
                              : '呼吸記錄（${_breathRecords.length} 筆記錄）',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._buildBreathSection(),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 220,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPillBg,
                                foregroundColor: kInk,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                widget.isEnglish ? 'Back to Home' : '回到主畫面',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
