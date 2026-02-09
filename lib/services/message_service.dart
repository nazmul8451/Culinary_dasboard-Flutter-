import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';
import 'realtime_database_service.dart';
import 'notification_service.dart';
import 'moderation_service.dart';
import 'fcm_service.dart';
import 'user_service.dart';
import '../models/user_model.dart';

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

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
      // Validate content before sending
      final validation = await _validateContent(
        message.content,
        message.senderId,
        'Direct Message',
      );

      if (!validation.isValid) {
        throw SecurityException(validation.error!);
      }

      final newMessageRef = _messagesRef.push();
      await newMessageRef.set(message.toMap());

      // Log notification for incoming messages
      if (message.senderId != 'admin' && message.receiverId == 'admin') {
        await NotificationService.addNotification(
          NotificationModel(
            id: '',
            title: 'New Message',
            body:
                'You received a message from ${message.senderId}: ${message.content}',
            timestamp: DateTime.now(),
            type: NotificationType.message,
            relatedId: message.senderId,
          ),
        );
      }
      print('✅ Message processed for ${message.receiverId}');
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
      // Validate broadcast content
      final validation = await _validateContent(
        broadcast.content,
        'admin',
        'Broadcast towards ${broadcast.receiverId}',
      );

      if (!validation.isValid) {
        throw SecurityException(validation.error!);
      }

      final newBroadcastRef = _broadcastsRef.push();
      await newBroadcastRef.set(broadcast.toMap());

      // Log the broadcast in admin notifications
      await NotificationService.addNotification(
        NotificationModel(
          id: '',
          title: 'Broadcast Sent',
          body:
              'Sent ${broadcast.type.name} to ${broadcast.receiverId}: ${broadcast.content}',
          timestamp: DateTime.now(),
          type: NotificationType.message,
        ),
      );

      print('✅ Broadcast sent to ${broadcast.receiverId}');

      // Trigger Push Notification if channel is push
      if (broadcast.type == MessageType.push) {
        final target = broadcast.receiverId.toLowerCase();

        if (target == 'everyone' ||
            target == 'buyer' ||
            target == 'seller' ||
            target == 'courier') {
          // Broadcast expansion: Fetch users and send individually
          final users = await UserService.getAllUsersOnce();
          for (final user in users) {
            bool isTarget =
                (target == 'everyone') ||
                (target == 'buyer' && user.userType == UserType.buyer) ||
                (target == 'seller' && user.userType == UserType.seller) ||
                (target == 'courier' && user.userType == UserType.courier);

            if (isTarget &&
                user.fcmToken != null &&
                user.fcmToken!.isNotEmpty) {
              await FcmService.sendNotificationToUser(
                userId: user.id,
                title: broadcast.title ?? 'Broadcast from Admin',
                body: broadcast.content,
                type: 'broadcast',
                data: {'broadcastId': newBroadcastRef.key, 'senderId': 'admin'},
              );
            }
          }
        } else {
          // Single user notification (original logic)
          await FcmService.sendNotificationToUser(
            userId: broadcast.receiverId,
            title: broadcast.title ?? 'Message from Admin',
            body: broadcast.content,
            type: 'broadcast',
            data: {'broadcastId': newBroadcastRef.key},
          );
        }
      }
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

  /// Get a map of UserId -> LastMessageTimestamp for sorting
  static Stream<Map<String, DateTime>> getLastMessageTimes() {
    return _messagesRef.onValue.map((event) {
      final Map<String, DateTime> lastTimes = {};
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            final msg = MessageModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            );

            String? otherUserId;
            if (msg.senderId == 'admin') {
              otherUserId = msg.receiverId;
            } else if (msg.receiverId == 'admin') {
              otherUserId = msg.senderId;
            }

            if (otherUserId != null) {
              if (!lastTimes.containsKey(otherUserId) ||
                  msg.timestamp.isAfter(lastTimes[otherUserId]!)) {
                lastTimes[otherUserId] = msg.timestamp;
              }
            }
          } catch (e) {
            // ignore malformed messages
          }
        });
      }
      return lastTimes;
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

  /// Validate content for sensitive information
  static Future<ContentValidationResult> _validateContent(
    String content,
    String userId,
    String context,
  ) async {
    // Regex patterns
    final phoneRegex = RegExp(
      r'\b[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}\b',
    );
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b');
    final urlRegex = RegExp(
      r'(http|https):\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(\/\S*)?',
    );

    String? violationDetails;
    ModerationLogType? violationType;

    if (phoneRegex.hasMatch(content)) {
      violationDetails = 'Phone number detected in message: $content';
      violationType = ModerationLogType.contactSharing;
    } else if (emailRegex.hasMatch(content)) {
      violationDetails = 'Email detected in message: $content';
      violationType = ModerationLogType.contactSharing;
    } else if (urlRegex.hasMatch(content)) {
      violationDetails = 'URL detected in message: $content';
      violationType = ModerationLogType.contactSharing;
    }

    if (violationType != null) {
      // Log the violation
      await ModerationService.logViolation(
        userId: userId,
        userName:
            'User ID: $userId', // ideally fetch name but ID is sufficient for log
        type: violationType,
        details: '$context: $violationDetails',
      );

      return ContentValidationResult(
        isValid: false,
        error: 'Message blocked: Sharing contact info is not allowed.',
      );
    }

    return ContentValidationResult(isValid: true);
  }
}

class ContentValidationResult {
  final bool isValid;
  final String? error;

  ContentValidationResult({required this.isValid, this.error});
}
