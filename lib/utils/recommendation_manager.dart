import 'package:flutter/foundation.dart';
import 'api_client.dart';

enum RecoStatus { idle, loading, ready, notApplicable, error }

class RecommendationState {
  final RecoStatus status;
  final Map<String, dynamic>? oil;
  final String? error;

  const RecommendationState({required this.status, this.oil, this.error});
}

class RecommendationManager {
  RecommendationManager._();
  static final RecommendationManager instance = RecommendationManager._();

  final ApiClient _api = ApiClient();
  final ValueNotifier<RecommendationState> state = ValueNotifier(
    const RecommendationState(status: RecoStatus.idle),
  );

  bool _running = false;

  Future<void> kickoffAfterLogin() async {
    await _runRecommendation(reason: 'login', force: false);
  }

  Future<void> maybeRefreshAfterDaySaved(DateTime savedDate) async {
    final now = DateTime.now();
    if (_sameDay(savedDate, now)) {
      await _runRecommendation(reason: 'daySaved', force: true);
    } else {
      debugPrint('[Reco] daySaved=$savedDate 不是今天，不觸發');
    }
  }

  void resetOnLogout() {
    state.value = const RecommendationState(status: RecoStatus.idle);
  }

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
    state.value = const RecommendationState(status: RecoStatus.loading);
    debugPrint('[Reco] >>> 開始（$reason）');

    try {
      final hasTodayDay = await _hasTodayDayFeeling();
      debugPrint('[Reco] 今天有 Day? $hasTodayDay');

      if (!hasTodayDay) {
        state.value = const RecommendationState(
          status: RecoStatus.notApplicable,
        );
        debugPrint('[Reco] <<< 結束（$reason）：notApplicable');
        return;
      }

      // 真的要跑推薦
      final recoRaw = await _api.recommendTodayOil();
      debugPrint('[Reco] 推薦結果：$recoRaw');

      state.value = RecommendationState(
        status: RecoStatus.ready,
        oil: {
          'id': recoRaw['oil_id'],
          'name': recoRaw['oil'] ?? '',
          'price': recoRaw['price'] ?? 0,
          'reason': recoRaw['reason'] ?? '',
        },
      );
      debugPrint('[Reco] <<< 結束（$reason）：ready');
    } catch (e, st) {
      debugPrint('[Reco] 失敗：$e\n$st');
      state.value = RecommendationState(
        status: RecoStatus.error,
        error: e.toString(),
      );
    } finally {
      _running = false;
    }
  }

  Future<bool> _hasTodayDayFeeling() async {
    try {
      // ✅ 用「查今天資料」的 API，避免時區與大量資料存取
      final today = DateTime.now();
      final entries = await _api.getDiaryEntriesByDate(today);
      // 你的 DiaryEntry 有 type 欄位時：
      final hasDay = entries.any((e) => e.type == 'Day');
      // 如果你的後端今天只會回「整日資料」而沒有 type 欄位，也可改成：final hasDay = entries.isNotEmpty;
      return hasDay;
    } catch (e) {
      debugPrint('[Reco] 檢查今天 Day 失敗：$e');
      return false;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
