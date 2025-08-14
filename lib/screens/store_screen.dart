import 'package:flutter/material.dart';
import '../utils/api_client.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ApiClient apiClient = ApiClient();

  /// 推薦油品：統一成 {id, name, price, ...} 結構，方便直接丟給 Grid
  Map<String, dynamic>? recommendedOil;
  List<dynamic> allOils = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  Map<String, dynamic>? _findOilById(List<dynamic> oils, int? id) {
    if (id == null) return null;
    for (final o in oils) {
      final oid = _toInt(o['id']);
      if (oid == id) return o as Map<String, dynamic>;
    }
    return null;
  }

  /// 若真的只有名字沒有 id（備援用，不一定會用到）
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

  Future<void> _loadStoreData() async {
    try {
      // 1) 拿到今天的 AI 推薦（含 oil_id / oil / reason …）
      final recoRaw = await apiClient.recommendTodayOil();

      // 2) 拿到所有精油（資料庫：id, name, price, meaning, effect, …）
      final all = await apiClient.getAllOils();

      // 3) 用 oil_id 對應到同一筆油品，讓推薦卡片也有 {id, name, price...}
      final recoId = _toInt(recoRaw['oil_id']);
      Map<String, dynamic>? recoFull = _findOilById(all, recoId);

      // 如果資料庫找不到，但 API 有名稱，就用名稱推測 id（備援）
      if (recoFull == null) {
        final fallbackId =
            _nameToId[recoRaw['oil'] ?? ''] ?? recoId; // 仍以 id 優先
        recoFull = {
          'id': fallbackId,
          'name': recoRaw['oil'] ?? '',
          'price': recoRaw['price'] ?? 0,
          'reason': recoRaw['reason'] ?? '',
        };
      } else {
        // 把 AI 的推薦理由也塞進來顯示（可選）
        recoFull['reason'] = recoRaw['reason'] ?? '';
      }

      setState(() {
        recommendedOil = recoFull;
        allOils = all;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('商店資料載入失敗：$e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E8), // 淡橘背景
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0E8),
        elevation: 0,
        title: const Text(
          '商店',
          style: TextStyle(color: Colors.deepOrange, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '那些你會喜歡的',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (recommendedOil != null)
                      _buildOilGrid([recommendedOil!]),

                    const SizedBox(height: 20),
                    const Text(
                      '也許你也會喜歡',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOilGrid(allOils),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.orange.shade200,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
        ],
      ),
    );
  }

  /// 橫向滑動、雙列網格（看起來像圖示那樣，同畫面兩張卡，往右滑有更多）
  Widget _buildOilGrid(List<dynamic> oils) {
    const double viewHeight = 280; // 兩列的總高度
    return SizedBox(
      height: viewHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal, // ← 橫向滑動
        primary: false,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
        itemCount: oils.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // ← 兩列
          mainAxisSpacing: 12, // 左右卡片間距
          crossAxisSpacing: 12, // 上下卡片間距
          childAspectRatio: 0.72, // 卡片寬高比（可微調）
        ),
        itemBuilder: (context, index) {
          final Map<String, dynamic> oil = oils[index] as Map<String, dynamic>;
          final int? id = _toInt(oil['id']) ?? _nameToId[oil['name'] ?? ''];
          final String name = (oil['name'] ?? oil['oil'] ?? '精油').toString();
          final int price = _toInt(oil['price']) ?? 250;
          final String imageAsset =
              (id != null && id > 0)
                  ? 'assets/oils/$id.jpg'
                  : 'assets/oils/placeholder.jpg';
          final String? reason = oil['reason']?.toString();

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD7B5),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  Text(
                    ' \$$price',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '推薦理由：$reason',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
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
