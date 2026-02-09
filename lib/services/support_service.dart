import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';
import 'fcm_service.dart';

enum TicketStatus { open, pending, resolved }

enum TicketCategory { payment, order, dispute, technical, other }

class TicketModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String subject;
  final TicketCategory category;
  final String message;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessageBy; // 'admin' or 'user'
  final List<TicketReply> replies;
  final List<String> attachments;

  TicketModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.subject,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageBy = 'user',
    this.replies = const [],
    this.attachments = const [],
  });

  factory TicketModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TicketModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'],
      userEmail: map['userEmail'],
      subject: map['subject'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'other'),
        orElse: () => TicketCategory.other,
      ),
      message: map['message'] ?? '',
      status: TicketStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'open'),
        orElse: () => TicketStatus.open,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? map['createdAt'] ?? 0,
      ),
      lastMessageBy: map['lastMessageBy'] ?? 'user',
      replies: map['replies'] != null
          ? (map['replies'] as Map).entries
                .map((e) => TicketReply.fromMap(e.key, e.value))
                .toList()
          : [],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : [],
    );
  }
}

class TicketReply {
  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isAdmin;

  TicketReply({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isAdmin,
  });

  factory TicketReply.fromMap(String id, Map<dynamic, dynamic> map) {
    return TicketReply(
      id: id,
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

class SupportService {
  static final DatabaseReference _ticketsRef = RealtimeDatabaseService.ref(
    'support_tickets',
  );

  static Stream<List<TicketModel>> getAllTickets() {
    return _ticketsRef.onValue.map((event) {
      final List<TicketModel> tickets = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          tickets.add(
            TicketModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        });
      }
      return tickets;
    }).asBroadcastStream();
  }

  static Stream<int> getNewTicketsCount() {
    print('ℹ️ Subscribing to support ticket unread count...');
    return _ticketsRef.onValue.map((event) {
      int count = 0;
      if (event.snapshot.value != null) {
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            if (value is Map) {
              final ticketData = Map<dynamic, dynamic>.from(value);
              // Robust status check
              final status = ticketData['status']?.toString() ?? 'open';
              // Check if the last msg was from user or if it's a brand new ticket without lastMessageBy
              final lastMessageBy =
                  ticketData['lastMessageBy']?.toString() ?? 'user';

              if (status != 'resolved' && lastMessageBy == 'user') {
                count++;
              }
            }
          });
        } catch (e) {
          print('❌ Error counting new tickets: $e');
        }
      }
      print('📊 New Tickets Count: $count');
      return count;
    });
  }

  static Future<void> updateTicketStatus(
    String ticketId,
    TicketStatus status,
  ) async {
    await _ticketsRef.child(ticketId).update({'status': status.name});
  }

  static Future<void> addReply(
    String ticketId,
    String message, {
    required bool isAdmin,
    required String senderId,
    String? recipientId, // For notification
    String? ticketSubject,
  }) async {
    final replyRef = _ticketsRef.child(ticketId).child('replies').push();
    await replyRef.set({
      'senderId': senderId,
      'message': message,
      'createdAt': ServerValue.timestamp,
      'isAdmin': isAdmin,
    });

    // Update ticket metadata
    print(
      '📝 Updating ticket metadata for $ticketId (lastMessageBy: ${isAdmin ? 'admin' : 'user'})',
    );
    await _ticketsRef.child(ticketId).update({
      'updatedAt': ServerValue.timestamp,
      'lastMessageBy': isAdmin ? 'admin' : 'user',
    });

    // Auto set to pending if admin replies
    if (isAdmin) {
      await updateTicketStatus(ticketId, TicketStatus.pending);

      // Trigger Notification to User
      if (recipientId != null && recipientId.isNotEmpty) {
        print('🚀 Sending reply notification to user: $recipientId');
        await FcmService.sendNotificationToUser(
          userId: recipientId,
          title: 'Support Update',
          body: 'New reply for: ${ticketSubject ?? "Your support ticket"}',
          type: 'support_reply',
          data: {'ticketId': ticketId},
        );
      } else {
        print('⚠️ Skipping user notification: recipientId is empty or null');
      }
    } else {
      // User replied -> Notify Admin
      print('🚀 Sending reply notification to admin (broadcast)');
      await FcmService.sendNotificationToUser(
        userId: 'admin_broadcast',
        title: 'New Support Message',
        body: 'User replied to: ${ticketSubject ?? "Support ticket"}',
        type: 'support_reply_admin',
        data: {'ticketId': ticketId},
      );
    }
  }
}
