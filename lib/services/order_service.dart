import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import 'realtime_database_service.dart';

/// Service for managing order data from Realtime Database
class OrderService {
  static final DatabaseReference _ordersRef = RealtimeDatabaseService.ref(
    'orders',
  );

  /// Get all orders as a stream
  static Stream<List<OrderModel>> getAllOrders() {
    return _ordersRef.orderByChild('createdAt').onValue.map((event) {
      final List<OrderModel> orders = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            orders.add(
              OrderModel.fromRealtimeDatabase(
                key.toString(),
                Map<dynamic, dynamic>.from(value),
              ),
            );
          }
        });
        // Sort by createdAt descending
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return orders;
    }).asBroadcastStream();
  }

  /// Get orders by status
  static Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _ordersRef.orderByChild('status').equalTo(status.name).onValue.map((
      event,
    ) {
      final List<OrderModel> orders = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            orders.add(
              OrderModel.fromRealtimeDatabase(
                key.toString(),
                Map<dynamic, dynamic>.from(value),
              ),
            );
          }
        });
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return orders;
    }).asBroadcastStream();
  }

  /// Get order by ID
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final snapshot = await _ordersRef.child(orderId).get();
      if (snapshot.exists && snapshot.value != null) {
        return OrderModel.fromRealtimeDatabase(
          orderId,
          Map<dynamic, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Update order status
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await _ordersRef.child(orderId).update({
        'status': status.name,
        if (status == OrderStatus.delivered)
          'deliveredAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Update escrow status
  static Future<void> updateEscrowStatus(
    String orderId,
    EscrowStatus status,
  ) async {
    try {
      await _ordersRef.child(orderId).update({'escrowStatus': status.name});
    } catch (e) {
      print('Error updating escrow status: $e');
      rethrow;
    }
  }

  /// Update tracking information
  static Future<void> updateTrackingInfo(
    String orderId, {
    required String trackingNumber,
    required String provider,
  }) async {
    try {
      await _ordersRef.child(orderId).update({
        'trackingNumber': trackingNumber,
        'trackingProvider': provider,
      });
    } catch (e) {
      print('Error updating tracking info: $e');
      rethrow;
    }
  }

  /// Resolve a dispute
  static Future<void> resolveDispute(
    String orderId, {
    required bool refundBuyer,
    required String resolutionNotes,
  }) async {
    try {
      final updates = {
        'hasDispute': false,
        'disputeResolutionNotes': resolutionNotes,
        'escrowStatus': refundBuyer
            ? EscrowStatus.refunded.name
            : EscrowStatus.released.name,
        'status': refundBuyer
            ? OrderStatus.cancelled.name
            : OrderStatus.delivered.name,
      };
      await _ordersRef.child(orderId).update(updates);
    } catch (e) {
      print('Error resolving dispute: $e');
      rethrow;
    }
  }

  /// Get order statistics
  static Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final snapshot = await _ordersRef.get();
      int totalOrders = 0;
      int pending = 0;
      int confirmed = 0;
      int preparing = 0;
      int onTheWay = 0;
      int delivered = 0;
      int cancelled = 0;
      double releasedRevenue = 0;
      double escrowHeld = 0;
      double refundedAmount = 0;

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        totalOrders = data.length;

        data.forEach((key, value) {
          if (value is Map) {
            final status = value['status']?.toString();
            final escrow = value['escrowStatus']?.toString();
            final amount = (value['totalAmount'] ?? 0).toDouble();
            final deliveryFee = (value['deliveryFee'] ?? 0).toDouble();
            final total = amount + deliveryFee;

            if (escrow == 'released') {
              releasedRevenue += total;
            } else if (escrow == 'held') {
              escrowHeld += total;
            } else if (escrow == 'refunded') {
              refundedAmount += total;
            }

            switch (status) {
              case 'pending':
                pending++;
                break;
              case 'confirmed':
                confirmed++;
                break;
              case 'preparing':
                preparing++;
                break;
              case 'onTheWay':
                onTheWay++;
                break;
              case 'delivered':
                delivered++;
                break;
              case 'cancelled':
                cancelled++;
                break;
            }
          }
        });
      }

      return {
        'total': totalOrders,
        'pending': pending,
        'confirmed': confirmed,
        'preparing': preparing,
        'onTheWay': onTheWay,
        'delivered': delivered,
        'cancelled': cancelled,
        'releasedRevenue': releasedRevenue,
        'escrowHeld': escrowHeld,
        'refundedAmount': refundedAmount,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'onTheWay': 0,
        'delivered': 0,
        'cancelled': 0,
        'releasedRevenue': 0.0,
        'escrowHeld': 0.0,
        'refundedAmount': 0.0,
      };
    }
  }
}
