import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// ===== 全域調色盤（與你原本一致） =====
const Color kBg = Color(0xFFDDEBD7); // 全頁底色
const Color kInk = Color(0xFF2E5F3A); // 深綠主字/圖示
const Color kBotBubble = Color(0xFFE7F1E3); // 機器人泡泡
const Color kMeBubble = Color(0xFFB7C8B1); // 自己泡泡
const Color kInputBg = Color(0xFFE7F1E3); // 輸入框底
const Color kSendFg = Colors.white; // 送出鈕字/圖
const Color kShadow = Color.fromARGB(18, 0, 0, 0);

class ChatbotScreen extends StatefulWidget {
  final bool isEnglish;

  const ChatbotScreen({super.key, this.isEnglish = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final ApiClient apiClient = ApiClient();
  late final String greeting;
  Timer? _typingTimer;
  bool _isLoading = false;
  List<String> _conversations = [];
  String _currentConversation = 'untitled_';

  // ===== 頂部下拉選單動畫控制 =====
  late final AnimationController _menuController;
  late final Animation<Offset> _menuOffset;
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    if (_isMenuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

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

    // 初始化頂部面板動畫：從上方滑入
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _menuController.dispose();
    super.dispose();
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

      final stream =
          widget.isEnglish
              ? apiClient.chatEN(text, _currentConversation)
              : apiClient.chat(text, _currentConversation);

      await for (final chunk in stream) {
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
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ===== 氣泡 =====
  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final isLoading = message['isLoading'] == true;
    final isTyping = message['isTyping'] == true;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isUser ? kMeBubble : kBotBubble;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(14),
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
            color: kBotBubble,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: kInk),
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
          boxShadow: const [
            BoxShadow(color: kShadow, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : kInk,
                fontSize: 16,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color:
                        isUser ? Colors.white70 : kInk.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                if (isTyping) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kInk,
                    ),
                  ),
                ],
              ],
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
      key: _scaffoldKey,
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          widget.isEnglish ? _currentConversation : _currentConversation,
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: widget.isEnglish ? 'Back' : '返回',
            onPressed: () => Navigator.maybePop(context),
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
        actions: [
          IconButton(
            tooltip: widget.isEnglish ? 'Conversation list' : '對話選單',
            onPressed: _toggleMenu, // ← 改成觸發頂部面板
            icon: const Icon(Icons.list_alt_rounded, color: kInk),
          ),
          const SizedBox(width: 6),
        ],
      ),

      // ===== 把主畫面與下拉面板疊在一起 =====
      body: Stack(
        children: [
          // 主畫面（聊天）
          SafeArea(
            child: Column(
              children: [
                // 訊息列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),

                // 輸入區
                Container(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: 12,
                  ),
                  color: kBg,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: kInputBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: kShadow,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText:
                                  widget.isEnglish
                                      ? 'Enter message...'
                                      : '輸入訊息...',
                              hintStyle: TextStyle(
                                color: kInk.withValues(alpha: 0.55),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(color: kInk, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kInk,
                            foregroundColor: kSendFg,
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                            elevation: 2,
                          ),
                          child: const Icon(Icons.arrow_forward, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 半透明遮罩：開啟選單時可點擊關閉
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black26),
              ),
            ),

          // 頂部下拉選單面板
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SlideTransition(
                position: _menuOffset,
                child: _TopMenuPanel(
                  title: widget.isEnglish ? 'Conversation Menu' : '對話選單',
                  conversations: _conversations,
                  current: _currentConversation,
                  onClose: _toggleMenu,
                  onSelect: (c) async {
                    await _switchConversation(c);
                    _toggleMenu();
                  },
                  onNew: () {
                    _switchConversation('untitled_');
                    setState(() {
                      _messages.clear();
                      _messages.add({
                        'role': 'bot',
                        'content': greeting,
                        'isTyping': false,
                        'timestamp': DateTime.now(),
                      });
                    });
                    _toggleMenu();
                  },
                  onDelete: () {
                    if (_conversations.isNotEmpty &&
                        _currentConversation != 'untitled_') {
                      _deleteConversation(_currentConversation);
                      _toggleMenu();
                    } else {
                      showSnackBarSafe(
                        widget.isEnglish
                            ? 'Cannot delete untitled_ conversation.'
                            : '無法刪除預設對話。',
                      );
                    }
                  },
                ),
              ),
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

// ===== 頂部下拉選單元件（沿用原 endDrawer 內容） =====
class _TopMenuPanel extends StatelessWidget {
  final String title;
  final List<String> conversations;
  final String current;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final VoidCallback onDelete;

  const _TopMenuPanel({
    required this.title,
    required this.conversations,
    required this.current,
    required this.onClose,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.70;

    return Material(
      color: kInk,
      elevation: 8,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 標題列
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // 對話列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                itemBuilder: (context, i) {
                  final c = conversations[i];
                  final selected = c == current;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      c,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: selected ? 1.0 : 0.86,
                        ),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing:
                        selected
                            ? const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            )
                            : null,
                    onTap: () => onSelect(c),
                  );
                },
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // 動作列
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onNew,
                      icon: const Icon(Icons.add),
                      label: const Text('新建'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('刪除'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
