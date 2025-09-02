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
  List<BreathRecord> _breathRecords = [];
  final ApiClient _apiClient = ApiClient();

  // ---（新增）搜尋用狀態---
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries(_selectedDay);
    _loadAllDayColors();
    _loadBreathRecords(_selectedDay);
  }

  @override
  void dispose() {
    _searchController.dispose(); //（新增）回收搜尋輸入框
    super.dispose();
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
      final dayColors = <DateTime, String>{};

      for (var entry in allEntries) {
        if (entry.type == 'Day' && entry.mixedColor != null) {
          final normalizedDate = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          dayColors[normalizedDate] = entry.mixedColor!;
        }
      }

      setState(() {
        _dayColors = dayColors;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading day colors: $e');
      }
    }
  }

  Future<void> _loadBreathRecords(DateTime date) async {
    try {
      final records = await _apiClient.getBreathRecordsByDate(date);
      if (kDebugMode) {
        print('Loaded breath records for $date: $records');
      }
      setState(() {
        _breathRecords = records;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading breath records: $e');
      }
    }
  }

  Color _getColorForDay(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final hex = _dayColors[normalizedDate];
    if (hex != null) {
      try {
        final colorCode = hex.replaceAll('#', '');

        if (colorCode.length == 6) {
          return Color(int.parse('0xFF$colorCode'));
        } else if (colorCode.length == 8) {
          return Color(int.parse('0x$colorCode'));
        }
      } catch (e) {
        if (kDebugMode) print('Invalid color code: $hex');
      }
    }
    return Colors.grey.shade300;
  }

  Widget _buildDayContainer(
    DateTime date, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final bgColor = _getColorForDay(date);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: isSelected ? Border.all(color: Colors.black, width: 2.0) : null,
        shape: BoxShape.circle,
      ),
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      child: Text('${date.day}', style: const TextStyle(color: Colors.black)),
    );
  }

  // =====================（新增）搜尋流程 =====================

  Future<void> _performSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await _apiClient.searchDiaryEntries(query: q);
      setState(() => _searchResults = results);
    } catch (e) {
      if (kDebugMode) print('Search failed: $e');
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _onTapSearchResult(Map<String, dynamic> e) async {
    // 先把日曆跳到該日期、載入那天資料
    try {
      final dateStr = (e['entry_date'] ?? '') as String;
      final timeStr = (e['entry_time'] ?? '00:00:00') as String;
      final dt = DateTime.parse('${dateStr}T$timeStr');

      setState(() {
        _selectedDay = dt;
        _focusedDay = dt;
      });
      await _loadDiaryEntries(dt);
      await _loadBreathRecords(dt);
    } catch (_) {
      // 若解析失敗仍可開詳情頁
    }

    // 依 entry_type 開對應頁
    final String type = (e['entry_type'] ?? '') as String;
    final bool isEnglish = (e['is_english'] ?? widget.isEnglish) == true;

    final List<dynamic> emos = (e['emotions'] ?? []) as List<dynamic>;
    final List<Map<String, dynamic>> emotions =
        emos
            .map<Map<String, dynamic>>(
              (x) => {
                'emotion': x['emotion'],
                'intensity':
                    (x['intensity'] is num)
                        ? (x['intensity'] as num).toDouble()
                        : double.tryParse('${x['intensity']}') ?? 0.0,
              },
            )
            .toList();

    final String? moodText = e['mood_text'] as String?;
    final String? details = e['details'] as String?;
    final String? mixedColor = e['mixed_color'] as String?;

    // ✅ 重點：在任何 Navigator / showDialog / ScaffoldMessenger 之前加這行
    if (!mounted) return;

    if (type == 'Moment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MomentFeelingsScreen(
                isEnglish: isEnglish,
                date: _selectedDay,
                isReadOnly: true,
                emotions: emotions,
                mixedColor: mixedColor,
                moodText: moodText,
                details: details,
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DayFeelingsScreen(
                isEnglish: isEnglish,
                date: _selectedDay,
                isReadOnly: true,
                emotions: emotions,
                mixedColor: mixedColor,
                moodText: moodText,
                details: details,
              ),
        ),
      );
    }
  }

  Future<void> _openSearchSheet() async {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });

    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 搜尋輸入框 + 按鈕
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              widget.isEnglish
                                  ? 'Search diary...'
                                  : '搜尋日記 / 當下感受...',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _performSearch,
                      child: Text(widget.isEnglish ? 'Search' : '搜尋'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 結果列表
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Searching...'),
                      ],
                    ),
                  )
                else if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      widget.isEnglish
                          ? 'No results yet. Try a keyword (e.g., “sleep”).'
                          : '尚無結果，試試輸入關鍵字（例如：「睡不著」）。',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = _searchResults[index];
                        final String type = (e['entry_type'] ?? '') as String;
                        final String date = (e['entry_date'] ?? '') as String;
                        final String time = (e['entry_time'] ?? '') as String;
                        final String title = (e['mood_text'] as String?) ?? '';
                        final List emos = (e['emotions'] ?? []) as List;

                        final emoLabel = emos
                            .map((x) => '${x['emotion']}')
                            .take(4)
                            .join(', ');

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(type == 'Moment' ? 'M' : 'D'),
                          ),
                          title: Text(
                            title.isEmpty
                                ? (widget.isEnglish ? '(No text)' : '（無文字）')
                                : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('$date $time · $emoLabel'),
                          onTap: () {
                            Navigator.pop(context); // 關閉面板
                            _onTapSearchResult(e);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================（原本 build 與 UI 保持不變，只在 AppBar 多一個搜尋鈕）===================

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
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Diary Review' : '本子回顧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearchSheet,
            tooltip: widget.isEnglish ? 'Search' : '搜尋',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
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
                _loadBreathRecords(selectedDay);
              },
              calendarFormat: CalendarFormat.month,
              locale: widget.isEnglish ? 'en_US' : 'zh_CN',
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(shape: BoxShape.circle),
              ),
              calendarBuilders: CalendarBuilders(
                todayBuilder:
                    (context, date, _) =>
                        _buildDayContainer(date, isToday: true),
                selectedBuilder:
                    (context, date, _) =>
                        _buildDayContainer(date, isSelected: true),
                defaultBuilder: (context, date, _) => _buildDayContainer(date),
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
                    const SizedBox(height: 20),
                    Text(
                      widget.isEnglish
                          ? 'Breathing Records (${_breathRecords.length} entries)'
                          : '呼吸記錄（${_breathRecords.length} 筆記錄）',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_breathRecords.isEmpty)
                      Text(
                        widget.isEnglish
                            ? 'No breathing records for this date.'
                            : '此日期無呼吸記錄。',
                      )
                    else
                      ..._breathRecords.map((record) {
                        final time = record.recordTime;
                        return ListTile(
                          title: Text(
                            '🕒 $time - ${widget.isEnglish ? '${record.min} minutes' : '${record.min} 分鐘'}',
                          ),
                          subtitle: Text(
                            record.feeling ??
                                (widget.isEnglish
                                    ? 'No feeling recorded'
                                    : '無感受記錄'),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
