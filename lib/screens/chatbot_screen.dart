import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ChatbotScreen extends StatefulWidget {
  final bool isEnglish;

  const ChatbotScreen({super.key, this.isEnglish = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final ApiClient apiClient = ApiClient();
  String? _userId;
  late final String greeting;
  Timer? _typingTimer;
  bool _isLoading = false;
  List<String> _conversations = [];
  String _currentConversation = 'default';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final hasRecommendation = now.minute % 2 == 1;
    greeting =
        hasRecommendation
            ? widget.isEnglish
                ? 'Hey~ I found a flavor just for you, wanna check it out? Or what do you want to chat about?'
                : '嘿~我找了一個專屬於你的味道，你要不要看看？還是你想聊聊什麼？'
            : widget.isEnglish
            ? 'Hello~ I\'m Smaily, what do you want to chat about?'
            : '您好~我是Smaily，你想要聊聊什麼嗎？';

    _messages.add({
      'role': 'bot',
      'content': greeting,
      'isTyping': false,
      'timestamp': now,
    });

    if (hasRecommendation) {
      _messages.add({
        'role': 'bot',
        'content': _buildRecommendationList(),
        'isRecommendation': true,
        'isTyping': false,
        'timestamp': now,
      });
    }

    _fetchAndStoreUserId();
    _loadConversations();
  }

  String _buildRecommendationList() {
    final recommendations = ['香草風味', '巧克力夢幻', '草莓甜心'];
    final prefix = widget.isEnglish ? 'Recommended flavors:' : '推薦口味：';
    return '$prefix\n${recommendations.map((item) => '- $item').join('\n')}';
  }

  Future<void> _fetchAndStoreUserId() async {
    try {
      final userId = await apiClient.getUserId();
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        setState(() {
          _userId = userId;
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'content':
                widget.isEnglish
                    ? 'Unable to retrieve user ID, please log in again.'
                    : '無法取得用戶ID，請重新登入。',
            'isTyping': false,
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content':
              widget.isEnglish
                  ? 'Error: Unable to retrieve user ID, please try again later.'
                  : '錯誤：無法取得用戶ID，請稍後再試。',
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadConversations() async {
    try {
      final data = await apiClient.getConversations();
      setState(() {
        _conversations = List<String>.from(data['conversations'] ?? []);
        _currentConversation = data['current'] ?? 'default';
      });
      await _loadChatHistory(_currentConversation);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content':
              widget.isEnglish
                  ? 'Error: Failed to load conversations.'
                  : '錯誤：無法載入對話列表。',
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadChatHistory(String conversation) async {
    try {
      final history = await apiClient.getChatHistory();
      setState(() {
        _messages.clear();
        _messages.add({
          'role': 'bot',
          'content': greeting,
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
        if (_messages.last['content'] != greeting) {
          _messages.add({
            'role': 'bot',
            'content': greeting,
            'isTyping': false,
            'timestamp': DateTime.now(),
          });
        }
        for (var msg in history) {
          _messages.add({
            'role': msg['role'] == 'user' ? 'user' : 'bot',
            'content': msg['content'],
            'isTyping': false,
            'timestamp': DateTime.now(),
          });
        }
      });
      _scrollToBottom();
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('No chat history') ||
          errorText.contains('empty') ||
          errorText.contains('not found')) {
        return;
      }

      if (kDebugMode) {
        print('載入聊天記錄失敗：$e');
      }
    }
  }

  Future<void> _switchConversation(String conversation) async {
    try {
      await apiClient.switchConversation(conversation);
      setState(() {
        _currentConversation = conversation;
      });
      await _loadChatHistory(conversation);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content':
              widget.isEnglish
                  ? 'Error: Failed to switch conversation.'
                  : '錯誤：無法切換對話。',
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 如果是 default，根據用戶的第一句話產生對話名稱
    if (_currentConversation == 'default') {
      final trimmed = text.trim();
      final preview = trimmed.length > 8 ? trimmed.substring(0, 8) : trimmed;
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final newConversationName =
          widget.isEnglish
              ? 'Chat: "$preview..." $time'
              : '對話：「$preview...」$time';
      await _switchConversation(newConversationName);
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'isTyping': false,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _isLoading = true;
      _messages.add({
        'role': 'bot',
        'content': '',
        'isLoading': true,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = _userId ?? prefs.getString('user_id');
      if (userId == null || userId == '0') {
        userId = await apiClient.getUserId();
        if (userId == null) {
          setState(() {
            _messages.removeWhere((msg) => msg['isLoading'] == true);
            _messages.add({
              'role': 'bot',
              'content':
                  widget.isEnglish
                      ? 'Unable to retrieve user ID, please log in again.'
                      : '無法取得用戶ID，請重新登入。',
              'isTyping': false,
              'timestamp': DateTime.now(),
            });
          });
          _scrollToBottom();
          return;
        }
        await prefs.setString('user_id', userId);
        setState(() {
          _userId = userId;
        });
      }

      final reply = await apiClient.sendChatMessage(text, int.parse(userId));
      setState(() {
        _messages.removeWhere((msg) => msg['isLoading'] == true);
        _messages.add({
          'role': 'bot',
          'content': '',
          'isTyping': true,
          'timestamp': DateTime.now(),
        });
      });
      _startTypingEffect(reply);
      setState(() {
        _isLoading = false;
      });

      await _loadConversations();
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg['isLoading'] == true);
        _messages.add({
          'role': 'bot',
          'content':
              widget.isEnglish
                  ? '😢 An error occurred, please try again later.'
                  : '😢 發生錯誤，請稍後再試。',
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  void _startTypingEffect(String text) {
    int index = 0;
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < text.length) {
        setState(() {
          _messages.last['content'] = text.substring(0, index + 1);
        });
        index++;
        _scrollToBottom();
      } else {
        setState(() {
          _messages.last['isTyping'] = false;
        });
        timer.cancel();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final isLoading = message['isLoading'] == true;
    final isTyping = message['isTyping'] == true;
    final isRecommendation = message['isRecommendation'] == true;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isUser ? Colors.blue[100] : Colors.grey[200];
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
      bottomRight:
          isUser ? const Radius.circular(0) : const Radius.circular(12),
    );

    final timestamp = message['timestamp'] as DateTime?;
    final formattedTime =
        timestamp != null
            ? DateFormat(
              widget.isEnglish ? 'hh:mm a' : 'HH:mm',
            ).format(timestamp)
            : '';

    if (isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(12, 0, 0, 0),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(12, 0, 0, 0),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommendation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    (message['content'] as String)
                        .split('\n')
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final line = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child:
                                index == 0
                                    ? Text(
                                      line,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : Text(
                                      line,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                          );
                        })
                        .toList(),
              )
            else
              Text(
                message['content'] ?? '',
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            if (isTyping)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Smaily AI' : '情緒對話 AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await apiClient.resetConversation();
                await _loadChatHistory(_currentConversation);
              } catch (e) {
                setState(() {
                  _messages.add({
                    'role': 'bot',
                    'content':
                        widget.isEnglish
                            ? 'Error: Failed to reset conversation.'
                            : '錯誤：無法重設對話。',
                    'isTyping': false,
                    'timestamp': DateTime.now(),
                  });
                });
                _scrollToBottom();
              }
            },
            tooltip: widget.isEnglish ? 'Reset Conversation' : '重設對話',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                final summary = await apiClient.finalizeConversation();
                setState(() {
                  _messages.add({
                    'role': 'bot',
                    'content':
                        widget.isEnglish
                            ? 'Conversation saved. Summary: $summary'
                            : '對話已儲存。摘要：$summary',
                    'isTyping': false,
                    'timestamp': DateTime.now(),
                  });
                });
                _scrollToBottom();
                await _loadConversations();
              } catch (e) {
                setState(() {
                  _messages.add({
                    'role': 'bot',
                    'content':
                        widget.isEnglish
                            ? 'Error: Failed to save conversation.'
                            : '錯誤：無法儲存對話。',
                    'isTyping': false,
                    'timestamp': DateTime.now(),
                  });
                });
                _scrollToBottom();
              }
            },
            tooltip: widget.isEnglish ? 'Save Conversation' : '儲存對話',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                widget.isEnglish ? 'Conversations' : '對話列表',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ..._conversations.map((conversation) {
              return ListTile(
                title: Text(conversation),
                selected: conversation == _currentConversation,
                onTap: () {
                  _switchConversation(conversation);
                  Navigator.pop(context);
                },
              );
            }),
            ListTile(
              title: Text(widget.isEnglish ? 'New Conversation' : '新建對話'),
              leading: const Icon(Icons.add),
              onTap: () {
                final newConversation =
                    'untitled_${DateTime.now().millisecondsSinceEpoch}';
                _switchConversation(newConversation);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/picture/bg.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: Colors.white.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText:
                                widget.isEnglish
                                    ? 'Enter message...'
                                    : '輸入訊息...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
