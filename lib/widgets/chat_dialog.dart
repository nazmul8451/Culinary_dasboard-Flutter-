import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../core/constants/app_colors.dart';
import '../../services/moderation_service.dart';

class ChatDialog extends StatefulWidget {
  final UserModel user;
  const ChatDialog({super.key, required this.user});

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final TextEditingController _messageController = TextEditingController();

  static final _phoneRegex = RegExp(
    r'(\+?\d{1,4}[\s-]?)?\(?\d{3}\)?[\s-]?\d{3,4}[\s-]?\d{4}',
  );
  static final _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
  );
  static final _urlRegex = RegExp(r'(https?://|www\.)[^\s]+');

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    MessageService.markMessagesAsRead(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chat with ${widget.user.name}'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: MessageService.getChatThread(widget.user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isAdmin = msg.senderId == 'admin';
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.primary
                                : Colors.grey[100],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isAdmin ? 16 : 0),
                              bottomRight: Radius.circular(isAdmin ? 0 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isAdmin
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content,
                                style: GoogleFonts.inter(
                                  color: isAdmin
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAdmin
                                      ? Colors.white.withOpacity(0.7)
                                      : AppColors.textSecondary.withOpacity(
                                          0.7,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Check for violations
    final violations = _detectContactSharing(content);
    if (violations.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Security Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This message contains contact information:'),
              const SizedBox(height: 8),
              Text(
                violations.join(', '),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sharing contact information outside the platform is logged for security review. Continue?',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Send Anyway'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      // Log violation
      await ModerationService.logViolation(
        userId: 'admin',
        userName: 'Administrator',
        type: ModerationLogType.contactSharing,
        details: 'Admin sent: ${violations.join(', ')} in message: "$content"',
      );
    }

    _messageController.clear(); // Clear immediately for better UX

    final msg = MessageModel(
      id: '',
      senderId: 'admin',
      receiverId: widget.user.id,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.chat,
      status: MessageStatus.sent,
    );

    try {
      await MessageService.sendMessage(msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<String> _detectContactSharing(String message) {
    final violations = <String>[];
    if (_phoneRegex.hasMatch(message)) violations.add('Phone Number');
    if (_emailRegex.hasMatch(message)) violations.add('Email Address');
    if (_urlRegex.hasMatch(message)) violations.add('Website URL');
    return violations;
  }
}
