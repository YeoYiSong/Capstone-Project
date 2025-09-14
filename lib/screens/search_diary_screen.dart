import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_client.dart';
import 'moment_feelings_screen.dart';
import 'day_feelings_screen.dart';

// ===== Palette（延續 DiaryReview 的綠色系） =====
const Color _kBg = Color(0xFFDDEBD7);
const Color _kInk = Color(0xFF2E5F3A);
const Color _kSubInk = Color(0xFF5E7F6A);
const Color _kCard = Color(0xFFB7C8B1); // 膠囊/結果卡片綠

class SearchDiaryScreen extends StatefulWidget {
  final bool isEnglish;

  const SearchDiaryScreen({super.key, this.isEnglish = false});

  @override
  State<SearchDiaryScreen> createState() => _SearchDiaryScreenState();
}

class _SearchDiaryScreenState extends State<SearchDiaryScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _controller = TextEditingController();

  bool _isSearching = false;
  String _keyword = '';
  List<Map<String, dynamic>> _results = []; // 搜尋結果
  bool get _showResults => _results.isNotEmpty || _isSearching;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.isEnglish ? 'Search' : '搜尋',
          style: const TextStyle(color: _kInk, fontWeight: FontWeight.w700),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: widget.isEnglish ? 'Back' : '返回',
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kInk, width: 1.4),
              ),
              child: const Icon(Icons.arrow_back, color: _kInk, size: 18),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _showResults ? _buildResults() : _buildInput(context),
      ),
    );
  }

  // =============== 左圖：輸入頁面（依你的排版） ===============
  Widget _buildInput(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double pillWidth = w * 0.68; // 接近示意圖寬度
    const double pillHeight = 120;

    return SingleChildScrollView(
      key: const ValueKey('input'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 問句（置中）
          Text(
            widget.isEnglish ? 'What would you like to recall?' : '有什麼事情想回顧？',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // 大膠囊輸入框（置中、固定大小）
          Center(
            child: Container(
              width: pillWidth,
              height: pillHeight,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(pillHeight / 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(24, 0, 0, 0),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white, // 文字白色更清楚
                  fontSize: 20,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.isEnglish ? 'Keyword' : '關鍵字',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 20,
                  ),
                ),
                onSubmitted: (_) => _doSearch(),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 小膠囊箭頭按鈕（置中）
          Center(
            child: SizedBox(
              width: 78,
              height: 42,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _doSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCard,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 1.5,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.arrow_forward, size: 20),
              ),
            ),
          ),

          // 底部留白（可換插畫）
          const SizedBox(height: 80),
          Text(
            widget.isEnglish ? 'Search your diary' : '在本子中搜尋',
            style: TextStyle(color: _kSubInk.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =============== 右圖：結果頁面 ===============
  Widget _buildResults() {
    final best = _results.isNotEmpty ? _results.first : null;
    final others =
        _results.length > 1 ? _results.sublist(1) : <Map<String, dynamic>>[];

    return ListView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // 標題列 + 重新搜尋小按鈕
        Row(
          children: [
            Expanded(
              child: Text(
                widget.isEnglish ? 'Search' : '搜尋',
                style: const TextStyle(
                  color: _kInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            IconButton(
              tooltip: widget.isEnglish ? 'Search again' : '重新搜尋',
              onPressed: () {
                setState(() {
                  _results = [];
                  _isSearching = false;
                });
              },
              icon: const Icon(Icons.edit, color: _kInk),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.isEnglish ? 'No results for now.' : '目前沒有找到相關結果。',
              style: TextStyle(color: _kSubInk.withValues(alpha: 0.9)),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          // 最佳結果
          Text(
            (widget.isEnglish ? 'Best match: ' : '最佳結果：') + _keyword,
            style: const TextStyle(
              color: _kInk,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (best != null)
            _ResultCard(
              entry: best,
              isEnglish: widget.isEnglish,
              onTap: _openEntry,
            ),
          const SizedBox(height: 22),

          // 其他結果
          Text(
            (widget.isEnglish ? 'Other results: ' : '其他結果：') + _keyword,
            style: const TextStyle(
              color: _kInk,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          for (final e in others)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ResultCard(
                entry: e,
                isEnglish: widget.isEnglish,
                onTap: _openEntry,
              ),
            ),
        ],
      ],
    );
  }

  // =============== 搜尋邏輯 ===============
  Future<void> _doSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _keyword = q;
      _isSearching = true;
      _results = [];
    });
    try {
      final rs = await _api.searchDiaryEntries(query: q);
      setState(() => _results = rs);
    } catch (e) {
      setState(() => _results = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // =============== 打開結果 ===============
  Future<void> _openEntry(Map<String, dynamic> e) async {
    try {
      final dateStr = (e['entry_date'] ?? '') as String;
      final timeStr = (e['entry_time'] ?? '00:00:00') as String;
      final dt = DateTime.parse('${dateStr}T$timeStr');

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

      if (!mounted) return;

      if (type == 'Moment') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MomentFeelingsScreen(
                  isEnglish: isEnglish,
                  date: dt,
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
                (_) => DayFeelingsScreen(
                  isEnglish: isEnglish,
                  date: dt,
                  isReadOnly: true,
                  emotions: emotions,
                  mixedColor: mixedColor,
                  moodText: moodText,
                  details: details,
                ),
          ),
        );
      }
    } catch (_) {}
  }
}

// ====== 單個結果卡片（右圖的綠色圓角卡） ======
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isEnglish;
  final void Function(Map<String, dynamic>) onTap;

  const _ResultCard({
    required this.entry,
    required this.isEnglish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String date = (entry['entry_date'] ?? '') as String;
    final DateTime dt = DateTime.tryParse(date) ?? DateTime.now();
    final String mon =
        DateFormat(
          isEnglish ? 'MMM' : 'MMM',
          isEnglish ? 'en_US' : 'zh_TW',
        ).format(dt).toUpperCase();
    final String day = DateFormat('d').format(dt);

    final String text =
        (entry['mood_text'] as String?) ?? (isEnglish ? '(No text)' : '（無文字）');
    final String details = (entry['details'] as String?) ?? '';

    return InkWell(
      onTap: () => onTap(entry),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(22, 0, 0, 0),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圓角日期徽章
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF9DB59A),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('yyyy').format(dt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    mon,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    day.padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 文字內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      details,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
