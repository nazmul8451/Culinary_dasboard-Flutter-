import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';

enum NotificationType { message, order, support, security }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.message,
      ),
      isRead: map['isRead'] ?? false,
      relatedId: map['relatedId'],
    );
  }
}

class NotificationService {
  static final DatabaseReference _notificationsRef =
      RealtimeDatabaseService.ref('admin_notifications');

  static Future<void> addNotification(NotificationModel notification) async {
    await _notificationsRef.push().set(notification.toMap());
  }

  static Stream<List<NotificationModel>> getNotifications() {
    return _notificationsRef.onValue.map((event) {
      final List<NotificationModel> notifications = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          notifications.add(
            NotificationModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        });
      }
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  static Stream<int> getUnreadCount() {
    return _notificationsRef.onValue.map((event) {
      int count = 0;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (!(value['isRead'] ?? false)) {
            count++;
          }
        });
      }
      return count;
    });
  }

  static Future<void> markAllAsRead() async {
    final snapshot = await _notificationsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, dynamic> updates = {};
      data.forEach((key, value) {
        if (!(value['isRead'] ?? false)) {
          updates['$key/isRead'] = true;
        }
      });
      if (updates.isNotEmpty) {
        await _notificationsRef.update(updates);
      }
    }
  }
}
