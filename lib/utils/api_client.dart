import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/config.dart';
import 'package:flutter/foundation.dart';
import 'dart:async' show unawaited;

class DiaryEntry {
  final int id;
  final DateTime date;
  final String time;
  final String type;
  final List<Map<String, dynamic>> emotions;
  final String? mixedColor;
  final String? moodText;
  final String? details;
  final bool isEnglish;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.emotions,
    this.mixedColor,
    this.moodText,
    this.details,
    required this.isEnglish,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['entry_date'];
    final timeStr = json['entry_time'];
    final createAt = DateTime.parse('$dateStr $timeStr');

    return DiaryEntry(
      id: json['id'],
      date: createAt,
      time: timeStr,
      type: json['entry_type'],
      emotions: List<Map<String, dynamic>>.from(json['emotions']),
      mixedColor: json['mixed_color'],
      moodText: json['mood_text'],
      details: json['details'],
      isEnglish: json['is_english'] == true || json['is_english'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type,
      'emotions': emotions,
      'mixed_color': mixedColor,
      'mood_text': moodText,
      'details': details,
      'is_english': isEnglish,
    };
  }
}

class BreathRecord {
  final int id;
  final int userId;
  final int duration;
  final int min;
  final String? feeling;
  final String type;
  final DateTime createAt;
  final String recordTime;

  BreathRecord({
    required this.id,
    required this.userId,
    required this.duration,
    required this.min,
    this.feeling,
    required this.type,
    required this.createAt,
    required this.recordTime,
  });

  factory BreathRecord.fromJson(Map<String, dynamic> json) {
    return BreathRecord(
      id: json['id'],
      userId: json['user_id'],
      duration: json['duration'],
      min: json['min'],
      feeling: json['feeling'],
      type: json['type'],
      createAt: DateTime.parse(json['create_at']),
      recordTime:
          json['record_time'] ??
          DateTime.parse(
            json['create_at'],
          ).toIso8601String().split('T')[1].substring(0, 8),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'duration': duration,
      'min': min,
      'feeling': feeling,
      'type': type,
    };
  }
}

class ApiClient {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    developer.log(
      'API Client initialized with baseUrl: ${getBaseUrl()}',
      name: 'ApiClient',
    );
  }

  Future<String?> getUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'ApiClient');
      return null;
    }

    final currentBaseUrl = getBaseUrl();
    developer.log(
      'Computed baseUrl from getBaseUrl(): $currentBaseUrl',
      name: 'ApiClient',
    );
    developer.log(
      'Attempting to fetch user ID with full URI: $currentBaseUrl/get_user_id',
      name: 'ApiClient',
    );
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/get_user_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': user.uid}),
      );

      developer.log(
        'API response status: ${response.statusCode}, body: ${response.body}',
        name: 'ApiClient',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('User ID fetched: ${data['user_id']}', name: 'ApiClient');
        return data['user_id'].toString();
      } else {
        developer.log(
          'Failed to get user_id: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('無法獲取用戶ID：${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching user ID: $e', name: 'ApiClient', error: e);
      throw Exception('無法獲取用戶ID：$e');
    }
  }

  /// 儲存日記：成功後自動觸發推薦 (/recommend_today_oil?user_id=..&source=day|now)
  Future<void> saveDiaryEntry({
    required DateTime date,
    required String type, // 'Day' or 'Now' 都可，會自動轉
    required List<Map<String, dynamic>> emotions,
    required String? mixedColor,
    required String moodText,
    required String details,
    required bool isEnglish,
    double? joy,
    double? sadness,
    double? anger,
    double? positive,
    double? anxiety,
    double? exhaust,
  }) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    // 後端只認 'Day' / 'Moment'，這裡把 'Now' 正規化為 'Moment'
    final lower = type.toLowerCase();
    final normalizedType = (lower == 'day') ? 'Day' : 'Moment';
    // 推薦用的 source：day / now
    final source = (lower == 'day') ? 'day' : 'now';

    final body = {
      'user_id': userId,
      'date': date.toIso8601String(),
      'type': normalizedType, // <== 關鍵：送 Day / Moment
      'emotions': emotions,
      'mixed_color': mixedColor,
      'mood_text': moodText,
      'details': details,
      'is_english': isEnglish,
    };

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/save_diary_entry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        developer.log(
          'saveDiaryEntry failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('儲存日記條目失敗：${response.body}');
      }
      developer.log('Diary entry saved successfully', name: 'ApiClient');

      // === 成功後觸發三格推薦（不阻斷原流程，失敗只記錄） ===
      unawaited(
        recommendTodayOil(source: source)
            .timeout(const Duration(seconds: 2)) // 短超時，避免網路慢拖住 isolate
            .then((reco) {
              developer.log(
                'Triggered recommend_today_oil after save ($source): $reco',
                name: 'ApiClient',
              );
            })
            .catchError((e, _) {
              // 後端可能在資料不足時回 400；這裡只記錄，不影響主流程
              developer.log(
                'Trigger recommend_today_oil failed (ignored): $e',
                name: 'ApiClient',
                error: e,
              );
            }),
      );
    } catch (e) {
      developer.log(
        'Error saving diary entry: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('儲存日記條目失敗：$e');
    }
  }

  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final formattedDate = date.toIso8601String().split('T')[0];
    try {
      final response = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_diary_entries/$formattedDate?user_id=$userId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DiaryEntry.fromJson(json)).toList();
      } else {
        developer.log(
          'getDiaryEntriesByDate failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('無法載入日記條目：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching diary entries: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('無法載入日記條目：$e');
    }
  }

  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/get_all_diary_entries?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log(
          'All diary entries fetched successfully',
          name: 'ApiClient',
        );
        return data.map((json) => DiaryEntry.fromJson(json)).toList();
      } else {
        developer.log(
          'getAllDiaryEntries failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('無法載入所有日記條目：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching all diary entries: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('無法載入所有日記條目：$e');
    }
  }

  Future<void> saveBreathRecord({
    required String userId,
    required int duration,
    required int min,
    String? feeling,
    String type = '引導',
  }) async {
    final body = {
      'user_id': userId,
      'duration': duration,
      'min': min,
      'feeling': feeling,
      'type': type,
    };
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/breath_record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        developer.log(
          'saveBreathRecord failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('儲存呼吸記錄失敗：${response.body}');
      }
      developer.log(
        'Breath record saved successfully: $body',
        name: 'ApiClient',
      );
    } catch (e) {
      developer.log(
        'Error saving breath record: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('儲存呼吸記錄失敗：$e');
    }
  }

  Future<List<BreathRecord>> getBreathRecordsByDate(DateTime date) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final formattedDate = date.toIso8601String().split('T')[0];
    try {
      final response = await http.get(
        Uri.parse(
          '${getBaseUrl()}/breath_record/$formattedDate?user_id=$userId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BreathRecord.fromJson(json)).toList();
      } else {
        developer.log(
          'getBreathRecordsByDate failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('無法載入呼吸記錄：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching breath records: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('無法載入呼吸記錄：$e');
    }
  }

  Future<List<BreathRecord>> getBreathRecordsByUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/breath_record/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BreathRecord.fromJson(json)).toList();
      } else {
        developer.log(
          'getBreathRecordsByUser failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('無法載入用戶呼吸記錄：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching user breath records: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('無法載入用戶呼吸記錄：$e');
    }
  }

  Future<void> updateBreathFeeling({
    required int recordId,
    required String feeling,
  }) async {
    final body = {'id': recordId, 'feeling': feeling};
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/breath_record/feeling'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        developer.log(
          'updateBreathFeeling failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('更新呼吸記錄感覺失敗：${response.body}');
      }
      developer.log(
        'Breath record feeling updated successfully',
        name: 'ApiClient',
      );
    } catch (e) {
      developer.log(
        'Error updating breath feeling: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('更新呼吸記錄感覺失敗：$e');
    }
  }

  Stream<String> chat(String message, String conversation) async* {
    final userId = await getUserId();
    if (userId == null) {
      developer.log('No user logged in for chat', name: 'ApiClient');
      throw Exception('無法傳送聊天訊息：用戶未登入');
    }

    final request = http.Request('POST', Uri.parse('${getBaseUrl()}/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'message': message,
        'user_id': userId,
        'conversation': conversation,
      });

    try {
      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        final stream = streamedResponse.stream.transform(utf8.decoder);
        await for (var chunk in stream) {
          if (kDebugMode) {
            print('[chunk] $chunk');
          }
          yield chunk;
        }
        developer.log('Chat message streamed successfully', name: 'ApiClient');
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        developer.log(
          'chat failed: $errorBody (Status: ${streamedResponse.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('傳送聊天訊息失敗：$errorBody');
      }
    } catch (e) {
      developer.log('Error in chat stream: $e', name: 'ApiClient', error: e);
      throw Exception('傳送聊天訊息失敗：$e');
    }
  }

  // 在 ApiClient 裡加上英文聊天串流（和 chat 一樣，但打 /chatEN）
  Stream<String> chatEN(String message, String conversation) async* {
    final userId = await getUserId();
    if (userId == null) {
      developer.log('No user logged in for chatEN', name: 'ApiClient');
      throw Exception('無法傳送英文聊天訊息：用戶未登入');
    }

    final request = http.Request('POST', Uri.parse('${getBaseUrl()}/chatEN'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'message': message,
        'user_id': userId,
        'conversation': conversation,
      });

    try {
      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        final stream = streamedResponse.stream.transform(utf8.decoder);
        await for (final chunk in stream) {
          if (kDebugMode) {
            print('[chunk EN] $chunk');
          }
          yield chunk;
        }
        developer.log('ChatEN streamed successfully', name: 'ApiClient');
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        developer.log(
          'chatEN failed: $errorBody (Status: ${streamedResponse.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('傳送英文聊天訊息失敗：$errorBody');
      }
    } catch (e) {
      developer.log('Error in chatEN stream: $e', name: 'ApiClient', error: e);
      throw Exception('傳送英文聊天訊息失敗：$e');
    }
  }

  Future<void> switchConversation(String conversationName) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/switch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversation': conversationName, 'user_id': userId}),
      );

      if (response.statusCode != 200) {
        developer.log(
          'switchConversation failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('切換對話失敗：${response.body}');
      }
      developer.log(
        'Conversation switched to $conversationName',
        name: 'ApiClient',
      );
    } catch (e) {
      developer.log(
        'Error switching conversation: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('切換對話失敗：$e');
    }
  }

  Future<void> resetConversation() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        developer.log(
          'resetConversation failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('重設對話失敗：${response.body}');
      }
      developer.log('Conversation reset successfully', name: 'ApiClient');
    } catch (e) {
      developer.log(
        'Error resetting conversation: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('重設對話失敗：$e');
    }
  }

  Future<Map<String, dynamic>> getConversations() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/conversations?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        developer.log('Conversations fetched successfully', name: 'ApiClient');
        return jsonDecode(response.body);
      } else {
        developer.log(
          'getConversations failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('取得對話列表失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching conversations: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('取得對話列表失敗：$e');
    }
  }

  Future<List<Map<String, String>>> getChatHistory(String conversation) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.get(
        Uri.parse(
          '${getBaseUrl()}/history?user_id=$userId&conversation=$conversation',
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final history = List<Map<String, String>>.from(
          (json['history'] as List).map(
            (e) => {
              'role': e['role']?.toString() ?? '',
              'content': e['content']?.toString() ?? '',
              'create_at': e['create_at']?.toString() ?? '',
            },
          ),
        );
        developer.log('Chat history fetched successfully', name: 'ApiClient');
        return history;
      } else {
        developer.log(
          'getChatHistory failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('取得聊天記錄失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching chat history: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('取得聊天記錄失敗：$e');
    }
  }

  Future<bool> hasDiaryForDate({
    required DateTime date,
    required String type, // 參數保留以相容呼叫端，但實際不再送到後端
  }) async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('UNAUTHENTICATED');
    }

    final iso =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse('${getBaseUrl()}/diary/exists').replace(
      queryParameters: {
        'date': iso,
        'user_id': userId, // <<<<<< 關鍵：一定要帶
      },
    );

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['exists'] == true;
    }

    // 其他狀態視為錯誤，交給呼叫端決定是否鎖住
    throw Exception('exists check failed: ${res.statusCode} ${res.body}');
  }

  /// 搜尋日記與瞬間 (/search_diary_entries)
  Future<List<Map<String, dynamic>>> searchDiaryEntries({
    required String query,
    String? userId,
  }) async {
    if (query.trim().isEmpty) {
      throw ArgumentError('query 不可為空字串');
    }

    // 優先使用傳入的 userId，沒有的話就呼叫 getUserId()
    String? finalUserId = userId;
    if (finalUserId == null || finalUserId.isEmpty) {
      finalUserId = await getUserId();
    }

    final baseUrl = getBaseUrl();
    final uri = Uri.parse('$baseUrl/search_diary_entries').replace(
      queryParameters: {
        'query': query.trim(),
        if (finalUserId != null && finalUserId.isNotEmpty)
          'user_id': finalUserId,
      },
    );

    try {
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          return data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          throw Exception('回傳格式錯誤: $data');
        }
      } else {
        throw Exception('搜尋失敗 (HTTP ${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      throw Exception('searchDiaryEntries 失敗: $e');
    }
  }

  Future<void> renameConversation(String oldName, String newName) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/update_conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_name': oldName,
          'new_name': newName,
        }),
      );

      if (response.statusCode != 200) {
        developer.log(
          'renameConversation failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('重新命名對話失敗：${response.body}');
      }

      developer.log('Conversation renamed to $newName', name: 'ApiClient');
    } catch (e) {
      developer.log(
        'Error renaming conversation: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('重新命名對話失敗：$e');
    }
  }

  Future<void> deleteConversation(String conversation) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');
    if (conversation == 'untitled_') {
      throw Exception('無法刪除預設對話');
    }

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversation': conversation, 'user_id': userId}),
      );

      if (response.statusCode != 200) {
        developer.log(
          'deleteConversation failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('刪除對話失敗：${response.body}');
      }

      developer.log('Conversation deleted successfully', name: 'ApiClient');
    } catch (e) {
      developer.log(
        'Error deleting conversation: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('刪除對話失敗：$e');
    }
  }

  Future<Map<String, dynamic>> finalizeConversation(String conversation) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/finalize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'conversation': conversation}),
      );

      if (response.statusCode == 200) {
        developer.log('Conversation finalized successfully', name: 'ApiClient');
        return jsonDecode(response.body);
      } else {
        developer.log(
          'finalizeConversation failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('產生對話摘要失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error finalizing conversation: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('產生對話摘要失敗：$e');
    }
  }

  Future<Map<String, dynamic>> analyzeTodayAll() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/analyze_today_all?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        developer.log(
          'Today\'s analysis fetched successfully',
          name: 'ApiClient',
        );
        return jsonDecode(response.body);
      } else {
        developer.log(
          'analyzeTodayAll failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('取得今日情緒摘要失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error analyzing today\'s data: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('取得今日情緒摘要失敗：$e');
    }
  }

  Future<List<dynamic>> getAllOils() async {
    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/get_all_oils'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('取得精油清單失敗：${response.body}');
      }
    } catch (e) {
      throw Exception('取得精油清單錯誤：$e');
    }
  }

  /// 單筆推薦（今天摘要），支援帶上 source=day/now，並回傳該次推薦結果
  Future<Map<String, dynamic>> recommendTodayOil({String? source}) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final uri = Uri.parse('${getBaseUrl()}/recommend_today_oil').replace(
        queryParameters: {
          'user_id': userId,
          if (source != null && source.isNotEmpty) 'source': source,
        },
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        developer.log(
          'Today\'s oil recommendation fetched successfully',
          name: 'ApiClient',
        );
        return jsonDecode(response.body);
      } else {
        developer.log(
          'recommendTodayOil failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('取得今日精油推薦失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error recommending today\'s oil: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('取得今日精油推薦失敗：$e');
    }
  }

  /// 取得今天所有已存的推薦清單（多筆）
  Future<List<Map<String, dynamic>>> getTodayOilRecos() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    try {
      final uri = Uri.parse(
        '${getBaseUrl()}/today_oil_recos',
      ).replace(queryParameters: {'user_id': userId});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          throw Exception('回傳格式錯誤: $data');
        }
      } else {
        developer.log(
          'getTodayOilRecos failed: ${response.body} (Status: ${response.statusCode})',
          name: 'ApiClient',
        );
        throw Exception('取得今日推薦清單失敗：${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error getting today oil recos: $e',
        name: 'ApiClient',
        error: e,
      );
      throw Exception('取得今日推薦清單失敗：$e');
    }
  }
}
