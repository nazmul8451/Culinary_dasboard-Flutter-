import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';

enum SubscriptionStatus { active, expired, pastDue, canceled }

class SubscriptionModel {
  final String id;
  final String vendorId;
  final String vendorName;
  final double amount;
  final SubscriptionStatus status;
  final DateTime nextBillingDate;
  final DateTime? lastPaymentDate;

  SubscriptionModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    required this.status,
    required this.nextBillingDate,
    this.lastPaymentDate,
  });

  factory SubscriptionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return SubscriptionModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? 'Unknown Vendor',
      amount: (map['amount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      nextBillingDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextBillingDate'] ?? 0,
      ),
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'])
          : null,
    );
  }

  static SubscriptionStatus _parseStatus(dynamic val) {
    if (val == null) return SubscriptionStatus.active;
    final str = val
        .toString()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    if (str == 'pastdue') return SubscriptionStatus.pastDue;
    if (str == 'active') return SubscriptionStatus.active;
    if (str == 'canceled' || str == 'cancelled') {
      return SubscriptionStatus.canceled;
    }
    if (str == 'expired') return SubscriptionStatus.expired;
    return SubscriptionStatus.active;
  }
}

class SubscriptionService {
  static final DatabaseReference _subRef = RealtimeDatabaseService.ref(
    'subscriptions',
  );

  static Stream<List<SubscriptionModel>> getAllSubscriptions() {
    return _subRef.onValue.map((event) {
      final List<SubscriptionModel> subs = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            subs.add(SubscriptionModel.fromMap(key.toString(), value));
          }
        });
      }
      return subs;
    });
  }

  static Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final snapshot = await _subRef.get();
      int active = 0;
      int failed = 0;
      double monthlyRevenue = 0;

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            final status = value['status'];
            final amount = (value['amount'] ?? 0).toDouble();
            if (status == 'active') {
              active++;
              monthlyRevenue += amount;
            } else if (status == 'pastDue') {
              failed++;
            }
          }
        });
      }
      return {
        'activeCount': active,
        'failedCount': failed,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      return {'activeCount': 0, 'failedCount': 0, 'monthlyRevenue': 0.0};
    }
  }
}
