import 'dart:convert';
import 'package:http/http.dart' as http;

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
        (!mixedColor.startsWith('#') || mixedColor.length != 9)) {
      mixedColor = null;
    }

    return DiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['entry_date']),
      time: json['entry_time'],
      type: json['entry_type'],
      emotions: List<Map<String, dynamic>>.from(jsonDecode(json['emotions'])),
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
      'mixedColor': mixedColor,
      'moodText': moodText,
      'details': details,
      'isEnglish': isEnglish,
    };
  }
}

class ApiClient {
  static const String baseUrl = 'http://localhost:5000'; // 本機
  // 如果在模擬器上運行，使用 10.0.2.2
  // static const String baseUrl = 'http://10.0.2.2:5000';
  // 如果在真機上運行，使用你的局域網 IP（例如 192.168.x.x）
  // static const String baseUrl = 'http://192.168.x.x:5000';

  Future<void> saveDiaryEntry({
    required DateTime date,
    required String type,
    required List<Map<String, dynamic>> emotions,
    required String? mixedColor,
    String? moodText,
    String? details,
    required bool isEnglish,
  }) async {
    final body = {
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
      throw Exception('Failed to save diary entry: ${response.body}');
    }
  }

  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    final formattedDate = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/get_diary_entries/$formattedDate'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load diary entries: ${response.body}');
    }
  }

  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_all_diary_entries'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load all diary entries: ${response.body}');
    }
  }
}
