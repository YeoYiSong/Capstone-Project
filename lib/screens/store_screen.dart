import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/recommendation_manager.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ApiClient apiClient = ApiClient();

  // ====== 綠色系 Palette（依你的圖） ======
  static const Color kBg = Color(0xFFDDEBD7); // 全頁淡綠
  static const Color kInk = Color(0xFF2E5F3A); // 深綠主字/圖示
  static const Color kSubInk = Color(0xFF5E7F6A); // 次要綠（價格/次文字）
  static const Color kCard = Color(0xFFE7F1E3); // 卡片淡綠
  static const Color kShadow = Color.fromARGB(12, 0, 0, 0);

  List<dynamic> allOils = [];
  bool isLoadingAll = true;

  @override
  void initState() {
    super.initState();
    _loadAllOils();
  }

  // ---------- utils ----------
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

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

  List<Map<String, dynamic>> _fallbackOils() {
    return _nameToId.entries
        .take(8)
        .map((e) => {'id': e.value, 'name': e.key, 'price': 250})
        .toList();
  }

  Future<void> _loadAllOils() async {
    try {
      final List<dynamic> all = await apiClient.getAllOils(); // 明確指定 List
      if (!mounted) return;
      setState(() {
        // 若 API 回傳空陣列，也使用 fallback，確保下方區塊有內容
        allOils = all.isNotEmpty ? all : _fallbackOils();
        isLoadingAll = false;
      });
    } catch (_) {
      if (!mounted) return;
      // 失敗也要顯示 fallback，確保底部不空白
      setState(() {
        allOils = _fallbackOils();
        isLoadingAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          '商店',
          style: TextStyle(
            color: kInk,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: '返回',
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
        iconTheme: const IconThemeData(color: kInk),
      ),
      body:
          isLoadingAll
              ? const Center(child: CircularProgressIndicator(color: kInk))
              : ValueListenableBuilder<RecommendationState>(
                valueListenable: RecommendationManager.instance.state,
                builder: (context, reco, _) {
                  final Map<String, dynamic>? recommendedOil =
                      (reco.status == RecoStatus.ready) ? reco.oil : null;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== 上：那些你會喜歡的 =====
                        const _SectionTitle('那些你會喜歡的'),
                        const SizedBox(height: 10),

                        if (reco.status == RecoStatus.ready &&
                            recommendedOil != null)
                          _buildOilGrid([_mergeWithAllInfo(recommendedOil)])
                        else if (reco.status == RecoStatus.loading)
                          const _PendingHint(text: '還在幫你找著推薦哦')
                        else if (reco.status == RecoStatus.notApplicable)
                          const _PendingHint(text: '記錄一天的心情後，我就能推薦囉')
                        else if (reco.status == RecoStatus.error)
                          const _PendingHint(text: '取得推薦時發生小問題，稍後再試看看')
                        else
                          const SizedBox.shrink(),

                        const SizedBox(height: 18),

                        // ===== 下：也許你也會喜歡（一定顯示）=====
                        const _SectionTitle('也許你也會喜歡'),
                        const SizedBox(height: 10),
                        _buildOilGrid(allOils),
                      ],
                    ),
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kBg,
        selectedItemColor: kInk,
        unselectedItemColor: kSubInk.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
        ],
      ),
    );
  }

  /// 補齊推薦卡的圖片與價格（用 allOils 對照）；保留推薦的 reason
  Map<String, dynamic> _mergeWithAllInfo(Map<String, dynamic> reco) {
    final id = _toInt(reco['id']) ?? _nameToId[(reco['name'] ?? '').toString()];
    if (id == null) return reco;
    final match = allOils.cast<Map<String, dynamic>>().firstWhere(
      (e) => _toInt(e['id']) == id,
      orElse: () => <String, dynamic>{},
    );
    // 先鋪上 allOils 的圖/價格，再用 reco 覆寫必要欄位，確保 reason 不會被蓋掉
    return {
      ...match,
      ...reco,
      'id': id,
      if (reco['reason'] != null) 'reason': reco['reason'],
    };
  }

  /// 橫向滑動、雙列網格（綠色卡片樣式）
  Widget _buildOilGrid(List<dynamic> oils) {
    const double viewHeight = 280; // 兩列總高度
    return SizedBox(
      height: viewHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        primary: false,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
        itemCount: oils.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final Map<String, dynamic> oil = oils[index] as Map<String, dynamic>;
          final id = _toInt(oil['id']) ?? _nameToId[oil['name'] ?? ''];
          final name = (oil['name'] ?? oil['oil'] ?? '精油').toString();
          final price = _toInt(oil['price']) ?? 250;
          final imageAsset =
              (id != null && id > 0)
                  ? 'assets/oils/$id.jpg'
                  : 'assets/oils/placeholder.jpg';
          final String? reason = oil['reason']?.toString();

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: kShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            color: kSubInk,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                  Text(
                    ' \$$price',
                    style: const TextStyle(
                      color: kSubInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '推薦理由：$reason',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: kSubInk.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===== 標題樣式 =====
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _StoreScreenState.kInk,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
  }
}

/// 沒有 AI 推薦/尚未計算時的提示列
class _PendingHint extends StatelessWidget {
  final String text;
  const _PendingHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _StoreScreenState.kCard,
        borderRadius: BorderRadius.circular(14),
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
            Icons.hourglass_top,
            color: _StoreScreenState.kInk,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, // ✅ 使用外部傳入的字
              style: const TextStyle(
                color: _StoreScreenState.kInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
