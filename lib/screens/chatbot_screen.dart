import 'dart:async';
import 'package:flutter/material.dart';
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
  late final String greeting;
  Timer? _typingTimer;
  bool _isLoading = false;
  List<String> _conversations = [];
  String _currentConversation = 'untitled_';

  @override
  void initState() {
    super.initState();
    greeting =
        widget.isEnglish
            ? 'Hello~ I\'m Smaily, what do you want to chat about?'
            : '您好~我是Smaily，你想要聊聊什麼嗎？';

    _currentConversation = 'untitled_';
    _messages.add({
      'role': 'bot',
      'content': greeting,
      'isTyping': false,
      'timestamp': DateTime.now(),
    });

    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await apiClient.getConversations();
      setState(() {
        _conversations = List<String>.from(data['conversations'] ?? []);
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
      final history = await apiClient.getChatHistory(conversation);
      setState(() {
        _messages.clear();

        if (history.isEmpty) {
          _messages.add({
            'role': 'bot',
            'content': greeting,
            'isTyping': false,
            'timestamp': DateTime.now(),
          });
        } else {
          final firstContent = history.first['content']?.toString().trim();
          final isGreetingAlready = firstContent == greeting;

          if (!isGreetingAlready) {
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
        }
      });

      _scrollToBottom();
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('No chat history') ||
          errorText.contains('empty') ||
          errorText.contains('not found')) {
        setState(() {
          _messages.clear();
          if (conversation == 'untitled_') {
            _messages.add({
              'role': 'bot',
              'content': greeting,
              'isTyping': false,
              'timestamp': DateTime.now(),
            });
          }
        });
        return;
      }
      setState(() {
        _messages.add({
          'role': 'bot',
          'content':
              widget.isEnglish
                  ? 'Error: Failed to load chat history.'
                  : '錯誤：無法載入聊天記錄。',
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
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
      StringBuffer responseBuffer = StringBuffer();

      await for (var chunk in apiClient.chat(text, _currentConversation)) {
        if (kDebugMode) {
          print('[收到 chunk]: $chunk');
        }

        if (chunk.startsWith('CONVERSATION_NAME:')) {
          final newConversationName =
              chunk.replaceFirst('CONVERSATION_NAME:', '').trim();

          if (mounted && newConversationName != _currentConversation) {
            setState(() {
              _currentConversation = newConversationName;
              if (!_conversations.contains(newConversationName)) {
                _conversations.add(newConversationName);
              }
            });
          }
        } else if (chunk.isNotEmpty) {
          responseBuffer.write(chunk);
          if (mounted) {
            setState(() {
              if (_messages.isNotEmpty) {
                _messages.last['content'] = responseBuffer.toString();
                _messages.last['isTyping'] = true;
              }
            });
            _scrollToBottom();
          }
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      if (mounted) {
        setState(() {
          _messages.last['isLoading'] = false;
          _messages.last['isTyping'] = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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
    void showSnackBarSafe(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEnglish
              ? ' $_currentConversation'
              : ' $_currentConversation',
        ),
        actions: [],
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
                setState(() {
                  _switchConversation('untitled_');
                  _messages.clear();
                  _messages.add({
                    'role': 'bot',
                    'content': greeting,
                    'isTyping': false,
                    'timestamp': DateTime.now(),
                  });
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(widget.isEnglish ? 'Delete Conversation' : '刪除對話'),
              leading: const Icon(Icons.delete),
              onTap: () {
                if (_conversations.isNotEmpty &&
                    _currentConversation != 'untitled_') {
                  _deleteConversation(_currentConversation);
                  Navigator.pop(context);
                } else {
                  showSnackBarSafe(
                    widget.isEnglish
                        ? 'Cannot delete untitled_ conversation.'
                        : '無法刪除預設對話。',
                  );
                }
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
                  color: Colors.white.withAlpha(204),
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

  Future<void> _deleteConversation(String conversation) async {
    try {
      await apiClient.deleteConversation(conversation);
      setState(() {
        _conversations.remove(conversation);
        if (_currentConversation == conversation) {
          _currentConversation = 'untitled_';
        }
        _messages.clear();
        _messages.add({
          'role': 'bot',
          'content': greeting,
          'isTyping': false,
          'timestamp': DateTime.now(),
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Conversation deleted successfully.'
                : '對話已成功刪除。',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Error: Failed to delete conversation.'
                : '錯誤：無法刪除對話。',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
