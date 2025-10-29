import 'package:flutter/material.dart';

class OilDetailScreen extends StatelessWidget {
  final Map<String, dynamic> oil;
  final bool isEnglish; // ✅ 由 SettingsScreen 控制的語言設定

  const OilDetailScreen({super.key, required this.oil, this.isEnglish = false});

  // ===== 顏色 =====
  static const Color kBg = Color(0xFFDDEBD7);
  static const Color kInk = Color(0xFF2E5F3A);
  static const Color kSub = Color(0xFF6B8A74);

  // ===== 中文名稱 -> id（當資料沒有 id 時反查用）=====
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

  // ===== id -> 英文名稱（英文模式顯示用）=====
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

  // ===== 詳細資料（中/英）=====
  // 結構：{ id: { 'zh': {'desc':..., 'benefits':...}, 'en': {...} } }
  static const Map<int, Map<String, Map<String, String>>> oilDetails = {
    1: {
      'zh': {
        'desc': '薰衣草擁有柔和清新的花香氣息…適合用於睡前放鬆、靜心冥想或紓壓沐浴。',
        'benefits': '改善焦慮、幫助入睡、舒緩肌肉痠痛、調理痘痘肌膚',
      },
      'en': {
        'desc':
            'Lavender has a gentle, fresh floral aroma—ideal for winding down before bed, meditation, or a stress-relieving bath.',
        'benefits':
            'Eases anxiety, supports sleep, soothes muscle soreness, balances acne-prone skin',
      },
    },
    2: {
      'zh': {
        'desc': '佛手柑散發出明亮、帶著淡淡甜味的柑橘香…適合早晨醒來或在壓力沉重的日子中使用。',
        'benefits': '改善焦慮與抑鬱、促進消化、舒緩腸胃脹氣、緊緻毛孔',
      },
      'en': {
        'desc':
            'Bergamot has a bright, lightly sweet citrus note—perfect for mornings or stressful days.',
        'benefits':
            'Reduces anxiety and low mood, supports digestion, soothes bloating, refines pores',
      },
    },
    3: {
      'zh': {
        'desc': '尤加利氣味清涼醒腦，如森林間的清晨空氣…常用於擴香器淨化環境或洗澡時加入幾滴喚醒身心。',
        'benefits': '暢通呼吸道、緩解咳嗽與鼻塞、放鬆肌肉、輔助瘦身',
      },
      'en': {
        'desc':
            'Eucalyptus smells cool and clarifying—great in diffusers to freshen air or in the shower to awaken body and mind.',
        'benefits':
            'Opens airways, eases cough/congestion, relaxes muscles, supports slimming routines',
      },
    },
    4: {
      'zh': {
        'desc': '帶有草本與木質的清新氣味，常被用來提振精神與提升專注力…',
        'benefits': '促進消化、緩解頭痛、改善痘痘、幫助雕塑體態',
      },
      'en': {
        'desc':
            'A fresh herbaceous-woody scent that lifts energy and sharpens focus.',
        'benefits':
            'Aids digestion, eases headaches, improves blemishes, supports body shaping',
      },
    },
    5: {
      'zh': {
        'desc': '帶有溫暖、樹脂般的神聖氣息，常用於冥想與靜心…對肌膚有修護與緊緻效果。',
        'benefits': '放鬆焦慮、舒緩緊張、促進皮膚修護、抗老化',
      },
      'en': {
        'desc':
            'Warm, resinous and sacred—often used for meditation; known for skin-comforting, firming qualities.',
        'benefits':
            'Relaxes anxiety, eases tension, supports skin repair, anti-aging care',
      },
    },
    6: {
      'zh': {
        'desc': '淡淡甜味與草本香氣，適合在需要自我照顧、療癒心靈的時刻…',
        'benefits': '舒緩經期不適、減輕焦慮與頭痛、穩定情緒壓力',
      },
      'en': {
        'desc':
            'Softly sweet and herbal—great for self-care and emotional soothing.',
        'benefits':
            'Eases menstrual discomfort, calms anxiety/headaches, stabilizes stress',
      },
    },
    7: {
      'zh': {
        'desc': '溫潤厚實的木質氣味，能帶來內在寧靜與沉穩，適合靜坐或睡前深層放鬆。',
        'benefits': '安撫情緒、促進睡眠、修護疤痕、細緻膚質',
      },
      'en': {
        'desc':
            'Rich, smooth woods that invite inner calm—perfect for deep relaxation or pre-sleep rituals.',
        'benefits':
            'Soothes emotions, supports sleep, aids scar care, refines skin texture',
      },
    },
    8: {
      'zh': {
        'desc': '溫和穩重的木質香氣，有助放鬆神經與情緒平衡，也常用於護膚與控油。',
        'benefits': '緩解焦慮、收斂毛孔、舒緩便秘與咳嗽',
      },
      'en': {
        'desc':
            'A gentle, grounding wood that balances nerves and emotions; also used in skin/sebum care.',
        'benefits':
            'Eases anxiety, tightens pores, soothes constipation and cough',
      },
    },
    9: {
      'zh': {
        'desc': '清新強烈的草本香氣，以潔淨與防護特性著稱，常見於居家清潔與肌膚保養。',
        'benefits': '舒緩咳嗽、改善消化不良、淨化空氣、控油抗痘',
      },
      'en': {
        'desc':
            'A crisp, powerful herbaceous scent famed for cleansing and protective qualities.',
        'benefits':
            'Eases cough, supports digestion, purifies air, controls oil and blemishes',
      },
    },
    10: {
      'zh': {
        'desc': '融合花香與青草的香氣，有助情緒平衡與肌膚調理，為日常注入溫柔與平靜。',
        'benefits': '舒緩焦慮與緊張、改善水腫、淡化黑眼圈與痘痘',
      },
      'en': {
        'desc':
            'Floral meets green—balances emotions and conditions the skin with a gentle calm.',
        'benefits':
            'Relieves anxiety/tension, reduces puffiness, softens dark circles/blemishes',
      },
    },
    11: {
      'zh': {
        'desc': '明亮的柑橘香氣，能迅速提振精神、淨化空氣，適合晨起或提神使用。',
        'benefits': '促進消化、改善毛孔與痘痘、幫助瘦身與利水',
      },
      'en': {
        'desc':
            'A bright citrus that quickly lifts energy and freshens air—great for mornings or pick-me-ups.',
        'benefits':
            'Supports digestion, refines pores/breakouts, aids slimming and water balance',
      },
    },
    12: {
      'zh': {
        'desc': '清新的草本香氣，適合思緒混亂或精神疲憊時使用，讓身心回歸平衡。',
        'benefits': '舒緩咳嗽與鼻塞、改善消化不良、減輕偏頭痛與緊張',
      },
      'en': {
        'desc':
            'Fresh and herbal—helpful when thoughts feel scattered or energy is low.',
        'benefits':
            'Eases cough/congestion, supports digestion, reduces migraine/tension',
      },
    },
    13: {
      'zh': {
        'desc': '溫暖辛香，具有激勵與提振的力量，適合運動後或疲勞時使用。',
        'benefits': '促進消化、改善胃口、舒緩肌肉痠痛、改善便秘與低血壓',
      },
      'en': {
        'desc': 'Warm and spicy—invigorating when tired; nice post-workout.',
        'benefits':
            'Aids digestion/appetite, relieves sore muscles, helps constipation/low BP',
      },
    },
    14: {
      'zh': {
        'desc': '濃郁溫暖、帶甜與木質調，能安定心神與提升專注。',
        'benefits': '緩解感冒不適、舒緩經痛與肌肉痛、改善痘痘',
      },
      'en': {
        'desc':
            'Rich, warm, slightly sweet-woody—steadies the mind and enhances focus.',
        'benefits':
            'Eases cold discomfort, relieves period/muscle pain, improves blemishes',
      },
    },
    15: {
      'zh': {
        'desc': '自然乾淨的木質香氣，協助情緒安撫與促進循環，帶來內在的平衡與穩定。',
        'benefits': '緩解經痛、幫助排水與減重',
      },
      'en': {
        'desc':
            'A clean natural wood that comforts emotions and supports circulation.',
        'benefits':
            'Relieves menstrual discomfort, supports drainage and weight goals',
      },
    },
    16: {
      'zh': {
        'desc': '甘甜柔和的草本香，常用於身體調理與促進代謝，餐後使用能讓身體更輕盈。',
        'benefits': '促進消化、舒緩便秘與經痛、幫助減肥與水腫',
      },
      'en': {
        'desc':
            'Sweet, gentle herb—used for body conditioning and metabolism; nice after meals.',
        'benefits':
            'Promotes digestion, eases constipation/period pain, helps slimming/water retention',
      },
    },
    17: {
      'zh': {
        'desc': '溫暖甜美的草本氣味，安撫煩躁心緒，適合放鬆儀式或睡前使用。',
        'benefits': '緩解焦慮、改善失眠、舒緩經痛與肌肉痠痛',
      },
      'en': {
        'desc':
            'Warm, gently sweet herb that settles restlessness—great for wind-down and bedtime.',
        'benefits':
            'Relieves anxiety, improves sleep, eases period/muscle pain',
      },
    },
    18: {
      'zh': {
        'desc': '濃郁柔美的花香，是愛與療癒的象徵，常用於情感支持與肌膚保養。',
        'benefits': '舒緩焦慮與失眠、改善經痛與便祕、促進膚質修護、消除黑眼圈',
      },
      'en': {
        'desc':
            'Rich, romantic floral—symbolic of love and healing; used for emotional care and skin pampering.',
        'benefits':
            'Soothes anxiety/insomnia, eases period pain/constipation, supports skin repair/dark circles',
      },
    },
    19: {
      'zh': {
        'desc': '深沉泥土香，被譽為「大地之油」，帶來安定與穩固，適合長期壓力與失眠。',
        'benefits': '舒緩焦慮與失眠、放鬆肌肉、調理痘痘',
      },
      'en': {
        'desc':
            'Deep, earthy—often called “the oil of the earth,” grounding for long-term stress and sleeplessness.',
        'benefits':
            'Relieves anxiety/insomnia, relaxes muscles, helps with breakouts',
      },
    },
    20: {
      'zh': {
        'desc': '濃郁甜美花香，喚醒感官與情緒，對油性肌膚與頭皮護理也很有效。',
        'benefits': '舒緩焦慮與抑鬱、改善毛孔與痘痘、幫助入眠與利水',
      },
      'en': {
        'desc':
            'Lush, sweet floral that awakens the senses; helpful for oily skin and scalp care.',
        'benefits':
            'Eases anxiety/low mood, improves pores/blemishes, supports sleep/water balance',
      },
    },
  };

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  @override
  Widget build(BuildContext context) {
    final String rawName =
        (oil['name'] ?? oil['oil'] ?? (isEnglish ? 'Essential Oil' : '精油'))
            .toString();

    // ✅ 先吃 oil_id，再退回 id，最後用中文名反查
    int? id = _toInt(oil['oil_id']) ?? _toInt(oil['id']) ?? _nameToId[rawName];

    final int price = _toInt(oil['price']) ?? 250;

    // 顯示名稱依語言決定
    final String displayName =
        isEnglish ? (_idToEnName[id ?? -1] ?? rawName) : rawName;

    // 圖片（若你用清圖，改成 'assets/oils_clean/$id.png'）
    final String image =
        (id != null && id > 0)
            ? 'assets/oils/$id.jpg'
            : 'assets/oils/placeholder.jpg';

    // ✅ 優先顯示後端帶來的描述（oil_desc）；沒有才退回本地表
    final String? oilDescFromBackend = (oil['oil_desc'] as String?)?.trim();

    // 避開 a?[] 語法：先取 map 再下標
    final String langKey = isEnglish ? 'en' : 'zh';
    final Map<String, Map<String, String>>? byLang =
        (id != null) ? oilDetails[id] : null;
    final Map<String, String>? detail = byLang?[langKey];

    final String? reason = (oil['reason'] as String?)?.trim();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kInk),
        title: Text(
          displayName,
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖片固定小高度，上方不撐版面
            Center(
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.asset(
                  image,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder:
                      (_, _, _) => const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: kSub,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 名稱 / 價格（文字放大、靠上）
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: kInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$$price',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kSub,
              ),
            ),

            // 推薦理由（來自上頁傳入的 oil['reason']）
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1E3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(18, 0, 0, 0),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.recommend, size: 18, color: kInk),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (isEnglish ? 'Recommended: ' : '推薦理由：') + reason,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: kInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 詳細描述 / 功效：✅ 先顯示後端 oil_desc；沒有再顯示內建表的 desc / benefits
            if (oilDescFromBackend != null &&
                oilDescFromBackend.isNotEmpty) ...[
              Text(
                oilDescFromBackend,
                style: const TextStyle(fontSize: 18, height: 1.5, color: kInk),
              ),
            ] else if (detail != null) ...[
              Text(
                detail['desc'] ?? '',
                style: const TextStyle(fontSize: 18, height: 1.5, color: kInk),
              ),
              const SizedBox(height: 10),
              Text(
                (isEnglish ? 'Benefits: ' : '功效：') + (detail['benefits'] ?? ''),
                style: const TextStyle(fontSize: 18, height: 1.5, color: kSub),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
