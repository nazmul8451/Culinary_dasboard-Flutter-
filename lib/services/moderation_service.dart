import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';

enum ModerationLogType { contactSharing, suspiciousDispute, fakeAccount, spam }

class ModerationLog {
  final String id;
  final String userId;
  final String userName;
  final ModerationLogType type;
  final String details;
  final DateTime timestamp;
  final String? relatedOrderId;

  ModerationLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.details,
    required this.timestamp,
    this.relatedOrderId,
  });

  factory ModerationLog.fromMap(String id, Map<dynamic, dynamic> map) {
    return ModerationLog(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      type: ModerationLogType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'spam'),
        orElse: () => ModerationLogType.spam,
      ),
      details: map['details'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      relatedOrderId: map['relatedOrderId'],
    );
  }
}

class ModerationService {
  static final DatabaseReference _logsRef = RealtimeDatabaseService.ref(
    'moderation_logs',
  );

  static Stream<List<ModerationLog>> getAllLogs() {
    return _logsRef.orderByChild('timestamp').onValue.map((event) {
      final List<ModerationLog> logs = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          logs.add(
            ModerationLog.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        });
        // Sort descending
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return logs;
    });
  }

  static Future<void> logViolation({
    required String userId,
    required String userName,
    required ModerationLogType type,
    required String details,
    String? orderId,
  }) async {
    await _logsRef.push().set({
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'details': details,
      'timestamp': ServerValue.timestamp,
      'relatedOrderId': orderId,
    });
  }
}
