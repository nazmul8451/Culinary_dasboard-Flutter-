import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';

enum TicketStatus { open, pending, resolved }

enum TicketCategory { payment, order, dispute, technical, other }

class TicketModel {
  final String id;
  final String userId;
  final String subject;
  final TicketCategory category;
  final String message;
  final TicketStatus status;
  final DateTime createdAt;
  final List<TicketReply> replies;

  TicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.replies = const [],
  });

  factory TicketModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TicketModel(
      id: id,
      userId: map['userId'] ?? '',
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
      replies: map['replies'] != null
          ? (map['replies'] as Map).entries
                .map((e) => TicketReply.fromMap(e.key, e.value))
                .toList()
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
  }) async {
    final replyRef = _ticketsRef.child(ticketId).child('replies').push();
    await replyRef.set({
      'senderId': senderId,
      'message': message,
      'createdAt': ServerValue.timestamp,
      'isAdmin': isAdmin,
    });

    // Auto set to pending if admin replies
    if (isAdmin) {
      await updateTicketStatus(ticketId, TicketStatus.pending);
    }
  }
}
