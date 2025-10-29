import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/recommendation_manager.dart';
import 'oil_detail_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.isEnglish});

  /// 由 SettingsScreen 控制的語言設定（true = 英文, false = 中文）
  final bool isEnglish;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ApiClient apiClient = ApiClient();

  // ====== 綠色系 Palette ======
  static const Color kBg = Color(0xFFDDEBD7); // 全頁淡綠
  static const Color kInk = Color(0xFF2E5F3A); // 深綠主字/圖示
  static const Color kSubInk = Color(0xFF6B8A74); // 次綠（價格/次文字）
  static const Color kCard = Color(0xFFE7F1E3); // 卡片淡綠
  static const Color kShadow = Color.fromARGB(18, 0, 0, 0);

  List<dynamic> allOils = [];
  bool isLoadingAll = true;

  // ====== 新增：今天已儲存的推薦清單 ======
  List<Map<String, dynamic>> todayRecos = [];
  bool _loadingRecos = true;

  // 監聽推薦狀態，當 ready 時刷新 todayRecos
  RecoStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _loadAllOils();
    _loadTodayRecos();

    // 監聽 RecommendationManager 狀態；當新推薦完成時，重撈列表
    RecommendationManager.instance.state.addListener(_onRecoStateChange);
    _lastStatus = RecommendationManager.instance.state.value.status;
  }

  @override
  void dispose() {
    RecommendationManager.instance.state.removeListener(_onRecoStateChange);
    super.dispose();
  }

  void _onRecoStateChange() {
    final cur = RecommendationManager.instance.state.value.status;
    // 只有從非 ready -> ready 時才刷新（避免不必要的重撈）
    if (_lastStatus != RecoStatus.ready && cur == RecoStatus.ready) {
      _loadTodayRecos();
    }
    _lastStatus = cur;
  }

  // ===== 工具 =====
  String _t(String zh, String en) => widget.isEnglish ? en : zh;

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  // 中文名稱 -> id（API 若只回中文名可反查）
  static const Map<String, int> _nameToId = {
    '薰衣草精油': 1,
    '佛手柑精油': 2,
    '尤加利精油': 3,
    '迷迭香精油': 4,
    '乳香精油': 5,
    '快樂鼠尾草精油': 6,
    '檀香精油': 7,
    '雪松精油': 8,
    '茶樹精油': 9,
    '天竺葵精油': 10,
    '檸檬精油': 11,
    '羅勒精油': 12,
    '黑胡椒精油': 13,
    '丁香精油': 14,
    '絲柏精油': 15,
    '茴香精油': 16,
    '馬鬱蘭精油': 17,
    '玫瑰精油': 18,
    '岩蘭草精油': 19,
    '伊蘭伊蘭精油': 20,
  };

  // id -> 英文名稱（英文模式顯示用）
  static const Map<int, String> _idToEnName = {
    1: 'Lavender Essential Oil',
    2: 'Bergamot Essential Oil',
    3: 'Eucalyptus Essential Oil',
    4: 'Rosemary Essential Oil',
    5: 'Frankincense Essential Oil',
    6: 'Clary Sage Essential Oil',
    7: 'Sandalwood Essential Oil',
    8: 'Cedarwood Essential Oil',
    9: 'Tea Tree Essential Oil',
    10: 'Geranium Essential Oil',
    11: 'Lemon Essential Oil',
    12: 'Basil Essential Oil',
    13: 'Black Pepper Essential Oil',
    14: 'Clove Essential Oil',
    15: 'Cypress Essential Oil',
    16: 'Fennel Essential Oil',
    17: 'Marjoram Essential Oil',
    18: 'Rose Essential Oil',
    19: 'Vetiver Essential Oil',
    20: 'Ylang Ylang Essential Oil',
  };

  List<Map<String, dynamic>> _fallbackOils() {
    return _nameToId.entries
        .take(8)
        .map((e) => {'id': e.value, 'name': e.key, 'price': 250})
        .toList();
  }

  Future<void> _loadAllOils() async {
    try {
      final List<dynamic> all = await apiClient.getAllOils();
      if (!mounted) return;
      setState(() {
        allOils = all.isNotEmpty ? all : _fallbackOils();
        isLoadingAll = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        allOils = _fallbackOils();
        isLoadingAll = false;
      });
    }
  }

  // ====== 新增：撈今天所有已儲存的推薦 ======
  Future<void> _loadTodayRecos() async {
    setState(() {
      _loadingRecos = true;
    });
    try {
      final list = await apiClient.getTodayOilRecos(); // 後端傳回多筆
      if (!mounted) return;
      // 只保留必要欄位，統一 key，避免前端取值混亂
      final normalized =
          list.map<Map<String, dynamic>>((e) {
            return {
              'id': _toInt(e['oil_id']) ?? _toInt(e['id']) ?? 0,
              'name': (e['oil'] ?? e['name'] ?? '').toString(),
              'price': _toInt(e['price']) ?? 0,
              'reason': (e['reason'] ?? '').toString(),
              // 其他欄位保留給細節頁可用
              'oil_desc': e['oil_desc'],
              'source': e['source'],
              'created_at': e['created_at'],
            };
          }).toList();
      setState(() {
        todayRecos = normalized;
        _loadingRecos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        todayRecos = [];
        _loadingRecos = false;
      });
    }
  }

  String _displayName(Map<String, dynamic> oil) {
    // 支援 id / oil_id、name / oil
    final int? id =
        _toInt(oil['id']) ??
        _toInt(oil['oil_id']) ??
        _nameToId[(oil['name'] ?? oil['oil'] ?? '').toString()];
    final String zhName = (oil['name'] ?? oil['oil'] ?? '精油').toString();
    if (widget.isEnglish) {
      return (id != null) ? (_idToEnName[id] ?? zhName) : zhName;
    }
    return zhName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          _t('商店', 'Store'),
          style: const TextStyle(
            color: kInk,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: _t('返回', 'Back'),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: kInk, width: 1.6),
              ),
              child: const Icon(Icons.arrow_back, color: kInk, size: 18),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body:
          isLoadingAll
              ? const Center(child: CircularProgressIndicator(color: kInk))
              : ValueListenableBuilder<RecommendationState>(
                valueListenable: RecommendationManager.instance.state,
                builder: (context, reco, _) {
                  // 0.0~1.0；null 代表不定長動畫
                  final double? progress = reco.progress?.clamp(0.0, 1.0);

                  // 「那些你會喜歡的」：使用今天已儲存的推薦清單
                  final List<Map<String, dynamic>> topSectionItems =
                      todayRecos.map(_mergeWithAllInfo).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(_t('那些你會喜歡的', 'Recommended for you')),
                        const SizedBox(height: 12),

                        // ====== 推薦區塊（支援中英）======
                        if (topSectionItems.isNotEmpty)
                          _buildOilGridVertical(topSectionItems)
                        else if (_loadingRecos ||
                            reco.status == RecoStatus.loading)
                          _RecoLoadingCard(
                            title: _t(
                              '還在幫你找著推薦哦',
                              'Finding recommendations for you…',
                            ),
                            subtitle: _t(
                              '分析你的感受與精油香調中…',
                              'Analyzing your mood and aroma profiles…',
                            ),
                            progress: progress,
                            isEnglish: widget.isEnglish,
                          )
                        else if (reco.status == RecoStatus.notApplicable)
                          _PendingHint(
                            text: _t(
                              '記錄一天的心情後，我就能推薦囉',
                              'Log your mood for a day and I can recommend!',
                            ),
                            isEnglish: widget.isEnglish,
                          )
                        else if (reco.status == RecoStatus.error)
                          _PendingHint(
                            text: _t(
                              '取得推薦時發生小問題，稍後再試看看',
                              'We hit a small issue getting recommendations. Please try again later.',
                            ),
                            isEnglish: widget.isEnglish,
                          )
                        else
                          const SizedBox.shrink(),

                        const SizedBox(height: 22),
                        _SectionTitle(_t('也許你也會喜歡', 'You might also like')),
                        const SizedBox(height: 12),
                        _buildOilGridVertical(allOils),
                      ],
                    ),
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kBg,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: kInk,
        unselectedItemColor: kSubInk.withValues(alpha: 0.55),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: ''),
        ],
      ),
    );
  }

  Map<String, dynamic> _mergeWithAllInfo(Map<String, dynamic> reco) {
    // 支援 id / oil_id 與 name / oil
    final id =
        _toInt(reco['id']) ??
        _toInt(reco['oil_id']) ??
        _nameToId[(reco['name'] ?? reco['oil'] ?? '').toString()];
    if (id == null) return reco;

    final match = allOils.cast<Map<String, dynamic>>().firstWhere(
      (e) => _toInt(e['id']) == id,
      orElse: () => <String, dynamic>{},
    );

    // 用 allOils 補齊圖片/價格，再用 reco 覆寫必要欄位，保留 reason 給詳細頁使用
    return {
      ...match,
      ...reco,
      'id': id,
      'name': reco['name'] ?? reco['oil'] ?? match['name'] ?? '',
      if (reco['reason'] != null) 'reason': reco['reason'],
    };
  }

  Widget _buildOilGridVertical(List<dynamic> oils) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: oils.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) {
        final Map<String, dynamic> oil = oils[index] as Map<String, dynamic>;
        final int? id =
            _toInt(oil['id']) ??
            _toInt(oil['oil_id']) ??
            _nameToId[oil['name'] ?? oil['oil'] ?? ''];
        final String name = _displayName(oil);
        final int price = _toInt(oil['price']) ?? 250;

        // 若已清過素材，改成 'assets/oils_clean/$id.png'
        final String imageAsset =
            (id != null && id > 0)
                ? 'assets/oils/$id.jpg'
                : 'assets/oils/placeholder.jpg';

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => OilDetailScreen(
                      oil: oil,
                      isEnglish: widget.isEnglish, // ✅ 跟著設定帶進詳細頁
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: kShadow, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, _, _) => const Icon(
                            Icons.image_not_supported,
                            color: kSubInk,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                    ),
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        color: kSubInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                // 推薦理由顯示移到 OilDetailScreen
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _StoreScreenState.kInk,
        fontSize: 28,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );
  }
}

/// 有進度條的 Loading 卡片（AI 推薦進行中）
/// 注意：文字由外部傳入，這裡也支援英文百分比字尾
class _RecoLoadingCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double? progress; // 0.0~1.0；null -> 不定長動畫
  final bool isEnglish;

  const _RecoLoadingCard({
    required this.title,
    this.subtitle,
    this.progress,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    final double? p = progress?.clamp(0.0, 1.0);
    final int percent = ((p ?? 0) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _StoreScreenState.kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: _StoreScreenState.kShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top,
                color: _StoreScreenState.kInk,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _StoreScreenState.kInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (p != null)
                Text(
                  isEnglish ? '$percent%' : '$percent%',
                  style: TextStyle(
                    color: _StoreScreenState.kSubInk.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                color: _StoreScreenState.kSubInk.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              color: _StoreScreenState.kInk,
              backgroundColor: const Color(0xFFCEE3D2),
              value: p, // 有值：決定型；null：不定長動畫
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingHint extends StatelessWidget {
  final String text;
  final bool isEnglish;
  const _PendingHint({required this.text, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _StoreScreenState.kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: _StoreScreenState.kShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: _StoreScreenState.kInk,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _StoreScreenState.kInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
