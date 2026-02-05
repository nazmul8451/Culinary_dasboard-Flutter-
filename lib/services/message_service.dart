import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';
import 'realtime_database_service.dart';

class MessageService {
  static final DatabaseReference _messagesRef = RealtimeDatabaseService.ref(
    'communications/messages',
  );
  static final DatabaseReference _broadcastsRef = RealtimeDatabaseService.ref(
    'communications/broadcasts',
  );

  /// Send a direct message to a specific user
  static Future<void> sendMessage(MessageModel message) async {
    try {
      final newMessageRef = _messagesRef.push();
      await newMessageRef.set(message.toMap());
      print('✅ Message sent to ${message.receiverId}');
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Get real-time chat thread between admin and a specific user
  static Stream<List<MessageModel>> getChatThread(String userId) {
    return _messagesRef.onValue.map((event) {
      final List<MessageModel> messages = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final msg = MessageModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          );

          print(
            '📩 Thread Msg: ID=${msg.id}, Sender=${msg.senderId}, Content="${msg.content}"',
          );

          // Filter for messages between Admin (senderId='admin') and the User
          if ((msg.senderId == 'admin' && msg.receiverId == userId) ||
              (msg.senderId == userId && msg.receiverId == 'admin')) {
            messages.add(msg);
          }
        });
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    }).asBroadcastStream();
  }

  /// Send a broadcast message to a group of users
  static Future<void> sendBroadcast(MessageModel broadcast) async {
    try {
      final newBroadcastRef = _broadcastsRef.push();
      await newBroadcastRef.set(broadcast.toMap());
      print('✅ Broadcast sent to ${broadcast.receiverId}');

      // In a real app, a Cloud Function would trigger Push/Email/SMS here
      // Based on broadcast.type
    } catch (e) {
      print('❌ Error sending broadcast: $e');
      rethrow;
    }
  }

  /// Get list of all broadcasts
  static Stream<List<MessageModel>> getAllBroadcasts() {
    return _broadcastsRef.onValue.map((event) {
      final List<MessageModel> broadcasts = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          broadcasts.add(
            MessageModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        });
      }
      broadcasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return broadcasts;
    }).asBroadcastStream();
  }

  /// Get unread message count for a specific user
  static Stream<int> getUnreadCount(String userId) {
    return _messagesRef.onValue.map((event) {
      int count = 0;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final map = Map<dynamic, dynamic>.from(value);
          if (map['senderId'] == userId &&
              map['receiverId'] == 'admin' &&
              map['status'] != 'read') {
            count++;
          }
        });
      }
      return count;
    }).asBroadcastStream();
  }

  /// Get total unread message count across all users
  static Stream<int> getTotalUnreadCount() {
    return _messagesRef.onValue.map((event) {
      int count = 0;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final map = Map<dynamic, dynamic>.from(value);
          if (map['senderId'] != 'admin' &&
              map['receiverId'] == 'admin' &&
              map['status'] != 'read') {
            count++;
          }
        });
      }
      return count;
    }).asBroadcastStream();
  }

  /// Mark all messages from a specific user as read
  static Future<void> markMessagesAsRead(String userId) async {
    try {
      final snapshot = await _messagesRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final Map<String, dynamic> updates = {};

        data.forEach((key, value) {
          final map = Map<dynamic, dynamic>.from(value);
          if (map['senderId'] == userId &&
              map['receiverId'] == 'admin' &&
              map['status'] != 'read') {
            updates['$key/status'] = 'read';
          }
        });

        if (updates.isNotEmpty) {
          await _messagesRef.update(updates);
          print('✅ Marked ${updates.length} messages from $userId as read');
        }
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Send individual Email/SMS/Push (Logs to database)
  static Future<void> sendExternal(MessageModel externalMsg) async {
    // Same as direct message but categorized by type
    await sendMessage(externalMsg);
  }
}
