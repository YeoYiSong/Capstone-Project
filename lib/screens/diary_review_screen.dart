import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'diary_locked_screen.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';
import '../utils/api_client.dart';

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

class DiaryReviewScreenState extends State<DiaryReviewScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<DiaryEntry> _diaryEntries = [];
  Map<DateTime, String> _dayColors = {};
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries(_selectedDay);
    _loadAllDayColors();
  }

  Future<void> _loadDiaryEntries(DateTime date) async {
    try {
      final entries = await _apiClient.getDiaryEntriesByDate(date);
      if (kDebugMode) {
        print('Loaded entries for $date: $entries');
      }
      setState(() {
        _diaryEntries = entries;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading diary entries: $e');
      }
    }
  }

  Future<void> _loadAllDayColors() async {
    try {
      final allEntries = await _apiClient.getAllDiaryEntries();
      if (kDebugMode) {
        print('All Entries Count: ${allEntries.length}');
        for (var entry in allEntries) {
          print(
            'Entry: id=${entry.id}, date=${entry.date}, type=${entry.type}, mixedColor=${entry.mixedColor}',
          );
        }
      }
      final dayColors = <DateTime, String>{};
      for (var entry in allEntries) {
        if (entry.type == 'Day' && entry.mixedColor != null) {
          if (kDebugMode) {
            print('Day Entry: ${entry.date}, Color: ${entry.mixedColor}');
          }
          dayColors[DateTime(
                entry.date.year,
                entry.date.month,
                entry.date.day,
              )] =
              entry.mixedColor!;
        }
      }
      if (kDebugMode) {
        print('Day Colors: $dayColors');
      }
      setState(() {
        _dayColors = dayColors;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all diary entries: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDiaryLocked) {
      return DiaryLockedScreen(
        diaryPassword: widget.diaryPassword!,
        isEnglish: widget.isEnglish,
      );
    }

    final momentEntries =
        _diaryEntries.where((entry) => entry.type == 'Moment').toList();
    final dayEntry = _diaryEntries.firstWhere(
      (entry) => entry.type == 'Day',
      orElse:
          () => DiaryEntry(
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEnglish ? 'Diary Review' : '本子回顧')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadDiaryEntries(selectedDay);
            },
            calendarFormat: CalendarFormat.month,
            locale: widget.isEnglish ? 'en_US' : 'zh_CN',
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, date, events) {
                return _buildDayContainer(date, isToday: true);
              },
              selectedBuilder: (context, date, events) {
                return _buildDayContainer(date, isSelected: true);
              },
              defaultBuilder: (context, date, events) {
                return _buildDayContainer(date);
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish
                        ? 'Moment Feelings (${momentEntries.length} entries)'
                        : '當下感受（${momentEntries.length} 筆記錄）',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (momentEntries.isEmpty)
                    Text(
                      widget.isEnglish
                          ? 'No moment entries for this date.'
                          : '此日期無當下感受記錄。',
                    )
                  else
                    ...momentEntries.map((entry) {
                      return ListTile(
                        title: Text(
                          '${entry.time} ${entry.emotions.map((e) => e['emotion']).join(', ')}',
                        ),
                        subtitle: Text(
                          entry.moodText ??
                              (widget.isEnglish ? 'No text' : '無文字'),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MomentFeelingsScreen(
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
                    }),
                  const SizedBox(height: 20),
                  Text(
                    widget.isEnglish ? 'Day Feelings' : '整天感受',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (dayEntry.id == -1)
                    Text(
                      widget.isEnglish
                          ? 'No day entry for this date.'
                          : '此日期無整天感受記錄。',
                    )
                  else
                    ListTile(
                      title: Text(
                        dayEntry.emotions.map((e) => e['emotion']).join(', '),
                      ),
                      subtitle: Text(
                        dayEntry.moodText ??
                            (widget.isEnglish ? 'No text' : '無文字'),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DayFeelingsScreen(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContainer(
    DateTime date, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final dayColor = _dayColors[DateTime(date.year, date.month, date.day)];
    final color =
        dayColor != null
            ? Color(int.parse(dayColor.replaceFirst('#', '0xFF')))
            : null;
    if (kDebugMode) {
      print('Date: $date, DayColor: $dayColor, Parsed Color: $color');
    }
    Color finalColor =
        color ??
        (isSelected
            ? Colors.blue.withValues(alpha: 0.8)
            : isToday
            ? Colors.blue.withValues(alpha: 0.3)
            : Colors.transparent);
    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: finalColor),
      child: Text(
        date.day.toString(),
        style: TextStyle(
          color: finalColor == Colors.transparent ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
