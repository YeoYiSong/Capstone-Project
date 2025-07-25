import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/config.dart';

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
    String? mixedColor = json['mixed_color'] as String?;
    if (mixedColor != null &&
        (!mixedColor.startsWith('#') ||
            (mixedColor.length != 7 && mixedColor.length != 9))) {
      mixedColor = null;
    }

    final createAt = DateTime.parse(json['create_at']);
    return DiaryEntry(
      id: json['id'],
      date: createAt,
      time: createAt.toIso8601String().split('T')[1].substring(0, 8),
      type: json['entry_type'],
      emotions: List<Map<String, dynamic>>.from(json['emotions']),
      mixedColor: mixedColor,
      moodText: json['mood_text'],
      details: json['details'],
      isEnglish: json['is_english'] == true,
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
  final String baseUrl = getBaseUrl();
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

    final response = await http.post(
      Uri.parse('$baseUrl/get_user_id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_uid': user.uid}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user_id'].toString();
    } else {
      developer.log(
        'Failed to get user_id: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('無法獲取用戶ID');
    }
  }

  Future<void> saveDiaryEntry({
    required DateTime date,
    required String type,
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

    final body = {
      'user_id': userId,
      'date': date.toIso8601String(),
      'type': type,
      'emotions': emotions,
      'mixed_color': mixedColor,
      'mood_text': moodText,
      'details': details,
      'is_english': isEnglish,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/save_diary_entry'),
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
  }

  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final formattedDate = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/get_diary_entries/$formattedDate?user_id=$userId'),
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
  }

  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.get(
      Uri.parse('$baseUrl/get_all_diary_entries?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } else {
      developer.log(
        'getAllDiaryEntries failed: ${response.body} (Status: ${response.statusCode})',
        name: 'ApiClient',
      );
      throw Exception('無法載入所有日記條目：${response.body}');
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
        Uri.parse('$baseUrl/breath_record'),
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
      developer.log('API 請求錯誤: $e', name: 'ApiClient', error: e);
      rethrow;
    }
  }

  Future<List<BreathRecord>> getBreathRecordsByDate(DateTime date) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final formattedDate = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/breath_record/$formattedDate?user_id=$userId'),
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
  }

  Future<List<BreathRecord>> getBreathRecordsByUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/breath_record/user/$userId'),
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
  }

  Stream<String> chat(String message, String language, int userId) async* {
    if (userId == 0) {
      final newUserId = await getUserId();
      if (newUserId == null) {
        throw Exception('無法獲取用戶ID，請重新登入');
      }
      userId = int.parse(newUserId);
    }

    final request =
        http.Request('POST', Uri.parse('$baseUrl/chat'))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({
            'message': message,
            'user_id': userId,
            'language': language,
          });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      final stream = streamedResponse.stream.transform(utf8.decoder);
      await for (var chunk in stream) {
        yield chunk;
      }
    } else {
      final errorBody = await streamedResponse.stream.bytesToString();
      developer.log('chat failed: $errorBody', name: 'ApiClient');
      throw Exception('傳送聊天訊息失敗：$errorBody');
    }
  }

  Future<String> sendChatMessage(String message, int userId) async {
    if (userId == 0) {
      final newUserId = await getUserId();
      if (newUserId == null) {
        throw Exception('無法獲取用戶ID，請重新登入');
      }
      userId = int.parse(newUserId);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'user_id': userId}),
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      developer.log(
        'sendChatMessage failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('傳送聊天訊息失敗：${response.body}');
    }
  }

  Future<void> switchConversation(String conversationName) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.post(
      Uri.parse('$baseUrl/switch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversation': conversationName, 'user_id': userId}),
    );

    if (response.statusCode != 200) {
      developer.log(
        'switchConversation failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('切換對話失敗：${response.body}');
    }
  }

  Future<void> resetConversation() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.post(
      Uri.parse('$baseUrl/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      developer.log(
        'resetConversation failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('重設對話失敗：${response.body}');
    }
  }

  Future<void> deleteConversation(String conversationName) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.post(
      Uri.parse('$baseUrl/delete_conversation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversation': conversationName, 'user_id': userId}),
    );

    if (response.statusCode != 200) {
      developer.log(
        'deleteConversation failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('刪除對話失敗：${response.body}');
    }
  }

  Future<void> renameConversation(String oldName, String newName) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.post(
      Uri.parse('$baseUrl/rename_conversation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'old_conversation': oldName,
        'new_conversation': newName,
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      developer.log(
        'renameConversation failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('重命名對話失敗：${response.body}');
    }
  }

  Future<Map<String, dynamic>> getConversations() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.get(
      Uri.parse('$baseUrl/conversations?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      developer.log(
        'getConversations failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('取得對話列表失敗：${response.body}');
    }
  }

  Future<List<Map<String, String>>> getChatHistory() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.get(
      Uri.parse('$baseUrl/history?user_id=$userId'),
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
      return history;
    } else {
      developer.log(
        'getChatHistory failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('取得聊天記錄失敗：${response.body}');
    }
  }

  Future<String> finalizeConversation() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('用戶未登入');

    final response = await http.post(
      Uri.parse('$baseUrl/finalize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['summary'] ?? '';
    } else {
      developer.log(
        'finalizeConversation failed: ${response.body}',
        name: 'ApiClient',
      );
      throw Exception('產生對話摘要失敗：${response.body}');
    }
  }
}
