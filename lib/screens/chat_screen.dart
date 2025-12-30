import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../core/theme_provider.dart';
import '../services/chat_service.dart';

class MarkdownParser {
  static List<TextSpan> parseMarkdownText(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      
      // Check if it's a bullet point (starts with * followed by space)
      if (line.startsWith('* ') && line.length > 2) {
        // Add bullet point symbol
        spans.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(fontWeight: FontWeight.w500),
        ));
        
        // Parse the bullet point content (remove the "* " prefix)
        final bulletContent = line.substring(2);
        spans.addAll(_parseInlineFormatting(bulletContent, baseStyle));
      } else {
        // Regular line (not bullet point)
        spans.addAll(_parseInlineFormatting(line, baseStyle));
      }
      
      // Add line break except for the last line
      if (lineIndex < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }
  
  static List<TextSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    
    // Process bold formatting first
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;
    
    for (final match in boldRegex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        spans.addAll(_parseItalicInText(beforeText, baseStyle));
      }
      
      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1)!,
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text after the last bold match
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      spans.addAll(_parseItalicInText(remainingText, baseStyle));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }
  
  static List<TextSpan> _parseItalicInText(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final italicRegex = RegExp(r'\*(?!\*)(.*?)\*(?!\*)');
    int lastIndex = 0;
    
    for (final match in italicRegex.allMatches(text)) {
      // Add text before the italic part
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      
      // Add the italic text (semi-bold)
      spans.add(TextSpan(
        text: match.group(1)!,
        style: baseStyle.copyWith(fontWeight: FontWeight.w600),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text after the last italic match
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }
}

class TypingIndicator extends StatefulWidget {
  final bool isDarkMode;

  const TypingIndicator({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[800]! : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animationValue = (_controller.value - index * 0.2) % 1.0;
        final scale = 0.5 + (animationValue * 0.5);
        final opacity = animationValue < 0.5 ? animationValue * 2 : (1 - animationValue) * 2;
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDarkMode;
  final int index;
  final List<Map<String, dynamic>> messages;
  final List<File>? imageFiles;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isDarkMode,
    required this.index,
    required this.messages,
    this.imageFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Date separator for new day messages
          if (_shouldShowDateSeparator(index))
            _buildDateSeparator(context, timestamp),
          
          Row(
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
                      // Display multiple images
                      if (imageFiles != null && imageFiles!.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: imageFiles!.take(3).map((imageFile) => Container(
                              width: (MediaQuery.of(context).size.width * 0.6 - 16) / 2,
                              height: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  imageFile,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      RichText(
                        text: TextSpan(
                          children: MarkdownParser.parseMarkdownText(
                            text,
                            TextStyle(
                              color: isUser 
                                  ? Colors.white 
                                  : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage['timestamp'].year,
      currentMessage['timestamp'].month,
      currentMessage['timestamp'].day,
    );
    
    final previousDate = DateTime(
      previousMessage['timestamp'].year,
      previousMessage['timestamp'].month,
      previousMessage['timestamp'].day,
    );
    
    return currentDate.isAfter(previousDate);
  }

  Widget _buildDateSeparator(BuildContext context, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(timestamp),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    }
    
    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return 'Yesterday';
    }
    
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;
  File? _selectedVideo;
  List<File> _selectedImages = [];
  File? _selectedPdf;
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

  Future<void> _pickCameraImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          // Add new image to existing images, max 3 total
          final newImages = List<File>.from(_selectedImages);
          newImages.add(File(pickedFile.path));
          _selectedImages = newImages.take(3).toList();
          _selectedVideo = null;
          _selectedPdf = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles.take(3).map((file) => File(file.path)).toList();
          _selectedVideo = null;
          _selectedPdf = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick images')),
      );
    }
  }



  void _clearAllFiles() {
    setState(() {
      _selectedImages = [];
    });
  }

  void _showFilePickerOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 80, // Add extra padding from bottom
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickCameraImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick Images (Max 3)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty || _isLoading) return;

    final userMessage = _messageController.text;
    final currentImages = List<File>.from(_selectedImages);
    
    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
        'imageFiles': currentImages,
      });
      _isLoading = true;
      _clearAllFiles();
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get current user ID (you might want to get this from your auth service)
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      final aiResponse = await _chatService.sendMessage(
        userMessage.isNotEmpty ? userMessage : "What's in this image?",
        userId,
        imageFiles: currentImages.isNotEmpty ? currentImages : null,
      );
      
      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': "Sorry, I'm having trouble connecting. Please try again.",
            'isUser': false,
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
                              index: index,
                              messages: _messages,
                              imageFiles: message['imageFiles'] as List<File>?,
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TypingIndicator(isDarkMode: isDarkMode),
                        ),
                    ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File previews
            if (_selectedImages.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_selectedImages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images (${_selectedImages.length})',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _selectedImages.take(3).map((image) => Container(
                              width: 60,
                              height: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _clearAllFiles,
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Multimodal file picker button
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _showFilePickerOptions,
                    icon: Icon(
                      Icons.attach_file,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _isLoading ? "Syndy is typing..." : "Type your message or attach files...",
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
                    color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(String type, String fileName, IconData icon, Color color) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  fileName,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

