// lib/utils/recommendation_manager.dart
import 'dart:async' show Timer, unawaited;
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 推薦狀態
enum RecoStatus { idle, loading, ready, notApplicable, error }

/// 推薦狀態封裝（今天最多 2 筆）
class RecommendationState {
  final RecoStatus status;

  /// 今天全部推薦（最多 2 筆）。每筆結構：
  /// { id, name, price, reason, oil_desc?, source: null, created_at? }
  final List<Map<String, dynamic>> items;
  final String? error;

  /// 視覺進度（0.0 ~ 1.0）；僅在 loading/ready 期間可能有值
  final double? progress;

  const RecommendationState({
    required this.status,
    this.items = const [],
    this.error,
    this.progress,
  });

  RecommendationState copyWith({
    RecoStatus? status,
    List<Map<String, dynamic>>? items,
    String? error,
    double? progress,
  }) {
    return RecommendationState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
      progress: progress,
    );
  }
}

/// 單例：管理精油推薦（後端負責去重與持久；前端負責觸發與取用）
class RecommendationManager {
  RecommendationManager._();
  static final RecommendationManager instance = RecommendationManager._();

  final ApiClient _api = ApiClient();

  /// 提供給 UI 監聽（注意：日記存檔後的「觸發」不會改這個狀態，以免干擾畫面）
  final ValueNotifier<RecommendationState> state =
      ValueNotifier<RecommendationState>(
        const RecommendationState(status: RecoStatus.idle),
      );

  bool _running = false;
  Timer? _progressTimer;

  /// —— 保障機制狀態（避免狂打 & 當天最多嘗試 2 次）——
  bool _ensuring = false;
  DateTime? _lastEnsureDate; // 只記「天」即可
  int _ensureAttempts = 0; // 當天已嘗試次數（上限 2）

  /// 登入後若要「真的取回今天的推薦來顯示」，才呼叫它（不影響 UI）
  Future<void> kickoffAfterLogin() async {
    await _runRecommendation(reason: 'login_pull', force: false);
  }

  /// ✅ 任何日記（Day/Now）儲存後：只觸發，不等待；並做「有日記無推薦」的保險檢查
  void refreshAfterEntrySaved({
    required DateTime savedDate,
    required bool isDay, // 僅用於標註來源，實際觸發不阻塞
  }) {
    if (!_sameDay(savedDate, DateTime.now())) {
      debugPrint('[Reco] entrySaved=$savedDate 不是今天，略過觸發');
      return;
    }

    // final src = isDay ? 'day' : 'now'; // <-- 不再需要

    // 1) 直接 fire-and-forget 觸發（不管成功與否；不阻塞）
    unawaited(
      _api
          .recommendTodayOil() // <-- 修改：移除 source
          .timeout(const Duration(seconds: 3))
          .then(
            (_) => debugPrint('[Reco] 已觸發 recommend_today_oil'),
          ) // <-- 修改：移除 source
          .catchError((e, _) {
            debugPrint('[Reco] 觸發失敗（忽略以免卡 UI）：$e');
          }),
    );

    // 2) 再做「今天有日記但沒有推薦」的保障，避免首次冷啟動失敗後就永遠沒推薦
    ensureTodayRecoIfNeeded();
  }

  /// —— 保障機制：只要「今天有任一日記」且「今天推薦為空」，就觸發推薦 —— ///
  ///
  /// 邏輯：
  /// 1) 讀今天推薦清單；若已有（>0）→ 結束。
  /// 2) 檢查今天是否有 Day 或 Now 任一日記；若都沒有 → 結束。
  /// 3) 有日記但無推薦 → fire-and-forget 觸發一次。
  /// 4) 若當次觸發之後 8 秒仍無推薦，且當天嘗試次數 < 2 → 補觸發一次（最後一次）。
  void ensureTodayRecoIfNeeded() {
    // 當天次數上限 2
    final todayKey = DateTime.now();
    if (_lastEnsureDate == null || !_sameDay(_lastEnsureDate!, todayKey)) {
      _lastEnsureDate = todayKey;
      _ensureAttempts = 0;
    }
    if (_ensureAttempts >= 2) {
      debugPrint('[Reco][ensure] 今日已達嘗試上限，略過');
      return;
    }
    if (_ensuring) {
      debugPrint('[Reco][ensure] 保障檢查進行中，略過');
      return;
    }

    _ensuring = true;
    _ensureAttempts += 1;
    debugPrint('[Reco][ensure] 啟動第 $_ensureAttempts 次保障檢查');

    // 完整流程走一次，但整體不阻塞 UI
    unawaited(
      _ensureFlowOnce().whenComplete(() {
        _ensuring = false;
      }),
    );
  }

  Future<void> _ensureFlowOnce() async {
    try {
      // Step 1: 讀今天推薦（短超時）
      final recos = await _safeGetTodayRecos();
      if (recos.isNotEmpty) {
        debugPrint('[Reco][ensure] 今天已有推薦 ${recos.length} 筆，結束');
        return;
      }

      // Step 2: 檢查今天是否有任一日記（Day 或 Now）
      final now = DateTime.now();
      final hasDay = await _safeHasDiaryForDate(date: now, type: 'Day');
      final hasNow = await _safeHasDiaryForDate(date: now, type: 'Now');
      if (!hasDay && !hasNow) {
        debugPrint('[Reco][ensure] 今天沒有日記，結束');
        return;
      }

      // Step 3: 有日記但無推薦 → 觸發一次 (後端會合併 day/now)
      if (hasDay || hasNow) {
        // <-- 修改
        debugPrint('[Reco][ensure] 偵測到日記，觸發推薦');
        _fireRecommend(); // <-- 修改
      }

      // Step 4: 8 秒後再看一次，若仍無推薦且當天嘗試未達上限，補觸發一次
      Future.delayed(const Duration(seconds: 8), () async {
        final recos2 = await _safeGetTodayRecos();
        if (recos2.isNotEmpty) {
          debugPrint('[Reco][ensure] 延遲檢查：已有推薦 ${recos2.length} 筆，完成');
          return;
        }
        // 再補一次（如果還有額度）
        if (_ensureAttempts < 2) {
          _ensureAttempts += 1;
          debugPrint('[Reco][ensure] 延遲檢查後仍無推薦，進行第 $_ensureAttempts 次補觸發');
          if (hasDay || hasNow) _fireRecommend(); // <-- 修改：統一觸發
        } else {
          debugPrint('[Reco][ensure] 延遲檢查仍無推薦，但已達嘗試上限');
        }
      });
    } catch (e, st) {
      debugPrint('[Reco][ensure] 發生例外：$e\n$st');
      // 保障流程錯誤也不影響 UI
    }
  }

  // Fire-and-forget 觸發（短超時＋吞錯），不回寫 state
  void _fireRecommend() {
    // <-- 修改：移除 source 參數
    unawaited(
      _api
          .recommendTodayOil() // <-- 修改：移除 source
          .timeout(const Duration(seconds: 3))
          .then((_) => debugPrint('[Reco] fire recommend')) // <-- 修改
          .catchError((e, _) {
            debugPrint('[Reco] fire recommend 失敗（忽略）：$e');
          }),
    );
  }

  // 安全包一層，抓今天推薦清單
  Future<List<dynamic>> _safeGetTodayRecos() async {
    try {
      final list = await _api.getTodayOilRecos().timeout(
        const Duration(seconds: 3),
      );
      return list; // ✅ 不再檢查型別
    } catch (e) {
      debugPrint('[Reco] 讀取今日推薦失敗（當作無）：$e');
      return <dynamic>[]; // 發生錯誤回傳空陣列
    }
  }

  // 安全包一層，查指定日期/類型是否有日記
  Future<bool> _safeHasDiaryForDate({
    required DateTime date,
    required String type, // 'Day' 或 'Now'
  }) async {
    try {
      // 你現有 DayFeelingsScreen 有用過這個 API（type: 'Day'）
      final ok = await _api
          .hasDiaryForDate(date: date, type: type)
          .timeout(const Duration(seconds: 3));
      return ok == true;
    } catch (e) {
      debugPrint('[Reco] 檢查 hasDiaryForDate($type) 失敗：$e');
      return false;
    }
  }

  /// （可選）真的去抓「今天的推薦」並回填狀態（例如商店頁/推薦頁需要顯示時）
  Future<void> _runRecommendation({
    required String reason,
    required bool force,
  }) async {
    if (_running) {
      debugPrint('[Reco] 略過（$reason）：已在執行中');
      return;
    }
    final s = state.value.status;
    if (!force && (s == RecoStatus.loading || s == RecoStatus.ready)) {
      debugPrint('[Reco] 略過（$reason）：狀態=$s');
      return;
    }

    _running = true;
    state.value = const RecommendationState(
      status: RecoStatus.loading,
      progress: 0.0,
    );
    _startProgressTicker();
    debugPrint('[Reco] >>> 開始抓取（$reason）');

    try {
      final list = await _api.getTodayOilRecos(); // 後端回清單
      final items = list.map<Map<String, dynamic>>((e) {
        return {
          'id': _toInt(e['oil_id']) ?? _toInt(e['id']) ?? 0,
          'name': (e['oil'] ?? e['name'] ?? '').toString(),
          'price': _toInt(e['price']) ?? 0,
          'reason': (e['reason'] ?? '').toString(),
          if (e['oil_desc'] is String && (e['oil_desc'] as String).isNotEmpty)
            'oil_desc': e['oil_desc'],
          if (e['source'] != null)
            'source': e['source'].toString(), // 雖然新邏輯是 NULL，但保留相容
          if (e['created_at'] != null) 'created_at': e['created_at'].toString(),
        };
      }).toList();

      _stopProgress(to100: true);

      if (items.isEmpty) {
        state.value = const RecommendationState(
          status: RecoStatus.notApplicable,
          items: [],
          progress: null,
        );
        debugPrint('[Reco] <<< 結束（$reason）：notApplicable（今天沒有推薦）');
      } else {
        final capped = items.take(2).toList(); // <-- 修改：新邏輯最多 2 筆
        state.value = RecommendationState(
          status: RecoStatus.ready,
          items: capped,
          progress: 1.0,
        );
        debugPrint('[Reco] <<< 結束（$reason）：ready（共 ${capped.length} 筆）');
      }
    } catch (e, st) {
      debugPrint('[Reco] 抓取失敗：$e\n$st');
      _stopProgress();
      state.value = RecommendationState(
        status: RecoStatus.error,
        error: e.toString(),
        items: const [],
        progress: null,
      );
    } finally {
      _running = false;
    }
  }

  // =================== 視覺進度：0 → 0.95（僅在主動抓結果時用） ===================

  void _startProgressTicker() {
    _progressTimer?.cancel();

    // 每 300ms 往上加一點，到 0.95 為止，等後端回來再補到 1.0
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      final cur = state.value.progress ?? 0.0;
      if (state.value.status != RecoStatus.loading) {
        t.cancel();
        return;
      }
      final next = (cur + 0.04).clamp(0.0, 0.95);
      state.value = state.value.copyWith(progress: next);
      if (next >= 0.95) t.cancel();
    });
  }

  /// 停止進度；[to100] 為 true 會把進度顯示為 1.0
  void _stopProgress({bool to100 = false}) {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (state.value.status == RecoStatus.loading) {
      state.value = state.value.copyWith(progress: to100 ? 1.0 : null);
    }
  }

  // =================== 工具 ===================

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  /// 清除推薦，回到 notApplicable（不影響伺服器資料）
  void clear() {
    _stopProgress();
    state.value = const RecommendationState(status: RecoStatus.notApplicable);
  }
}
