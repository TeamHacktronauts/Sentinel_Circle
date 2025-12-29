import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDarkMode;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/sentinel_bot.png',
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor
                    : isDarkMode ? Colors.grey[800]! : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white 
                          : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white70 
                          : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: isDarkMode ? Colors.white : Colors.grey[700],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Hello! I'm Syndy, your AI safety assistant. How can I help you today?",
      'isUser': false,
      'timestamp': DateTime.now(),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    final userMessage = _messageController.text;
    _messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': _getAIResponse(userMessage),
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });

    _scrollToBottom();
  }

  String _getAIResponse(String userMessage) {
    // Simple AI response logic - can be enhanced with actual AI integration
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('help') || lowerMessage.contains('emergency')) {
      return "I understand you need help. If this is an emergency, please contact local authorities immediately. I can also guide you to our safety features.";
    } else if (lowerMessage.contains('unsafe') || lowerMessage.contains('danger')) {
      return "Your safety is important. You can use the 'I Feel Unsafe' button on the home screen to get immediate help. Would you like me to guide you there?";
    } else if (lowerMessage.contains('report')) {
      return "You can report safety concerns using the 'Report a Safety Concern' button on the home screen. This helps keep our community safe.";
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return "Hello! I'm here to help you with any safety concerns or questions. What would you like to know?";
    } else {
      return "I'm here to help with safety-related questions. You can ask me about emergency procedures, reporting concerns, or using our safety features.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/icons/sentinel_bot.png',
                  height: 32,
                  width: 32,
                ),
                const SizedBox(width: 8),
                const Text("Chat with Syndy"),
              ],
            ),
            backgroundColor: const Color(0xFF5E72E4),
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[900]!,
                        Colors.grey[850]!,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF5E72E4).withOpacity(0.1),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessage(
                        text: message['text'] as String,
                        isUser: message['isUser'] as bool,
                        timestamp: message['timestamp'] as DateTime,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
                ),
                _buildMessageInput(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeProvider themeProvider) {
    final isDarkMode = themeProvider.isDarkMode;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

