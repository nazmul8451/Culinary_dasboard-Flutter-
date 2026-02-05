import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../core/constants/app_colors.dart';

class ChatDialog extends StatefulWidget {
  final UserModel user;
  const ChatDialog({super.key, required this.user});

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final TextEditingController _messageController = TextEditingController();

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
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isAdmin
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  color: isAdmin
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAdmin
                                      ? Colors.white70
                                      : Colors.black45,
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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text;
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
}
