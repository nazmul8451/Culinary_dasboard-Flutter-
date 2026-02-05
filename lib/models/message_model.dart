enum MessageType { chat, email, push, sms }

enum MessageStatus { sent, read, delivered, failed }

class MessageModel {
  final String id;
  final String senderId;
  final String
  receiverId; // Can be 'everyone', 'buyers', 'sellers', 'couriers' for broadcasts
  final String content;
  final String? title; // Useful for push and emails
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.title,
    required this.timestamp,
    required this.type,
    required this.status,
    this.metadata,
  });

  factory MessageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    // Check for various possible field names for message content
    final content = map['content'] ?? map['message'] ?? map['text'] ?? '';

    return MessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      content: content.toString(),
      title: map['title']?.toString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.chat,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'title': title,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name,
      'status': status.name,
      'metadata': metadata,
    };
  }
}
