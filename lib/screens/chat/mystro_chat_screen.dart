// lib/screens/chat/mystro_chat_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mystro_ai_service.dart';

class MystroChatScreen extends StatefulWidget {
  const MystroChatScreen({super.key});

  @override
  State<MystroChatScreen> createState() => _MystroChatScreenState();
}

class _MystroChatScreenState extends State<MystroChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isAi': true,
      'text': "Hi! I'm Mystro, your AI study companion. Ask me anything about "
          "your coursework, a concept you're stuck on, or how to plan a study session.",
      'time': '',
    },
  ];

  final List<String> _suggestions = [
    'Show me an example',
    'Make a flashcard',
    'Explain simply',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _timeNow() => TimeOfDay.now().format(context);

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear conversation?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: const Text(
          "This clears what you've talked about with Mystro so far. This can't be undone.",
          style: TextStyle(color: AppColors.slateGray),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _messages.clear();
        _messages.add({
          'isAi': true,
          'text': "Hi! I'm Mystro, your AI study companion. Ask me anything about "
              "your coursework, a concept you're stuck on, or how to plan a study session.",
          'time': '',
        });
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    // Snapshot history *before* appending the new user message.
    final history = List<Map<String, dynamic>>.from(_messages);

    setState(() {
      _messages.add({'isAi': false, 'text': text, 'time': _timeNow()});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await MystroAiService.sendMessage(userMessage: text, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add({'isAi': true, 'text': reply, 'time': _timeNow()});
        _isLoading = false;
      });
    } on MystroAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'isAi': true, 'text': e.message, 'time': _timeNow(), 'isError': true});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Add to conversation',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy)),
              const SizedBox(height: 16),
              _buildAttachmentOption(Icons.camera_alt_outlined,
                  'Take a photo', 'Capture something to analyze'),
              _buildAttachmentOption(Icons.image_outlined,
                  'Choose from gallery', 'Pick an image from your library'),
              _buildAttachmentOption(Icons.description_outlined,
                  'Upload document', 'PDF, Word, or notes file'),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: AppColors.teal, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: const SizedBox(
              width: 20,
              height: 12,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.teal, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
              fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.slateGray, fontSize: 13)),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.slateGray, size: 20),
      onTap: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: AppColors.teal, size: 16),
                SizedBox(width: 6),
                Text('Mystro',
                    style: TextStyle(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ],
            ),
            const Text('Your study companion',
                style: TextStyle(color: AppColors.slateGray, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'clear') _confirmClearChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                  SizedBox(width: 10),
                  Text('Clear conversation', style: TextStyle(color: AppColors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.teal.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: AppColors.teal.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Knows your profile: Visual learner · Reading Macroeconomics',
                    style: TextStyle(
                        color: AppColors.teal.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final msg = _messages[index];
                final isAi = msg['isAi'] as bool;
                final isError = msg['isError'] == true;
                final time = (msg['time'] as String?) ?? '';

                if (isAi) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: (isError ? AppColors.amber : AppColors.teal)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: Icon(
                              isError ? Icons.warning_amber_rounded : Icons.auto_awesome,
                              color: isError ? AppColors.amber : AppColors.teal,
                              size: 16),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isError
                                      ? AppColors.amberBackground
                                      : AppColors.white,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  border: Border.all(
                                      color: isError
                                          ? AppColors.amber.withValues(alpha: 0.4)
                                          : AppColors.border.withValues(alpha: 0.5)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.deepNavy
                                            .withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Text(msg['text'],
                                    style: const TextStyle(
                                        color: AppColors.deepNavy,
                                        fontSize: 14.5,
                                        height: 1.5)),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(time,
                                    style: const TextStyle(
                                        color: AppColors.slateGray,
                                        fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF13171F),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: Text(msg['text'],
                                    style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 14.5,
                                        height: 1.4)),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(time,
                                    style: const TextStyle(
                                        color: AppColors.slateGray,
                                        fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Suggestion Pills
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return OutlinedButton(
                  onPressed: _isLoading ? null : () => _sendMessage(_suggestions[index]),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(_suggestions[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(color: AppColors.white),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.deepNavy),
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask Mystro anything...',
                        hintStyle: TextStyle(color: AppColors.slateGray),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: AppColors.slateGray, size: 20),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}