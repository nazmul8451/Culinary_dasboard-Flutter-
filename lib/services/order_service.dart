import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';

import 'realtime_database_service.dart';
import 'fcm_service.dart';
import 'payment_service.dart';

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

      // Add To History
      await _ordersRef.child(orderId).child('history').push().set({
        'status': status.name,
        'timestamp': ServerValue.timestamp,
        'message': 'Order status updated to ${status.name}',
      });

      // Fetch order details for notification
      final order = await getOrderById(orderId);
      if (order != null) {
        final statusText = status.name
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(0)}',
            )
            .toLowerCase();

        // Notify Buyer
        await FcmService.sendNotificationToUser(
          userId: order.buyerId,
          title: 'Order $statusText',
          body:
              'Your order #${orderId.substring(0, 5)}... has been updated to $statusText.',
          type: 'order_update',
          data: {'orderId': orderId},
        );

        // Notify Seller
        await FcmService.sendNotificationToUser(
          userId: order.sellerId,
          title: 'Order $statusText',
          body:
              'Order #${orderId.substring(0, 5)}... status changed to $statusText.',
          type: 'order_update',
          data: {'orderId': orderId},
        );
      }
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

      final order = await getOrderById(orderId);
      if (order != null) {
        // Notify both parties about financial update
        final title = status == EscrowStatus.released
            ? 'Funds Released'
            : 'Funds Update';
        final body = status == EscrowStatus.released
            ? 'Escrow funds for Order #${orderId.substring(0, 5)} have been released.'
            : 'Escrow status for Order #${orderId.substring(0, 5)} is now ${status.name}.';

        await FcmService.sendNotificationToUser(
          userId: order.buyerId,
          title: title,
          body: body,
          type: 'escrow_update',
          data: {'orderId': orderId},
        );

        await FcmService.sendNotificationToUser(
          userId: order.sellerId,
          title: title,
          body: body,
          type: 'escrow_update',
          data: {'orderId': orderId},
        );
      }
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

      final order = await getOrderById(orderId);
      if (order != null) {
        // Notify Buyer specifically about tracking
        await FcmService.sendNotificationToUser(
          userId: order.buyerId,
          title: 'Tracking Updated',
          body:
              'Tracking info added for your order. Provider: $provider, No: $trackingNumber',
          type: 'tracking_update',
          data: {'orderId': orderId},
        );
      }
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

      // Process Payment/Refund
      final orderSnapshot = await _ordersRef.child(orderId).get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map;
        final totalAmount = (orderData['totalAmount'] ?? 0).toDouble();

        if (refundBuyer) {
          await PaymentService.processRefund(
            orderId,
            totalAmount,
            resolutionNotes,
          );
        } else {
          await PaymentService.releaseEscrow(
            orderId,
            totalAmount,
            orderData['sellerId'],
          );
        }

        // Notify Parties
        await FcmService.sendNotificationToUser(
          userId: orderData['buyerId'],
          title: 'Dispute Resolved',
          body: refundBuyer
              ? 'Dispute resolved in your favor. Refund processed.'
              : 'Dispute resolved. Funds released to vendor.',
          type: 'dispute',
          data: {'orderId': orderId},
        );

        await FcmService.sendNotificationToUser(
          userId: orderData['sellerId'],
          title: 'Dispute Resolved',
          body: refundBuyer
              ? 'Dispute resolved in buyer favor. Funds refunded.'
              : 'Dispute resolved in your favor. Funds released.',
          type: 'dispute',
          data: {'orderId': orderId},
        );
      }

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
      double pendingRelease = 0;
      double adminCommission = 0;

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
              adminCommission +=
                  (amount * 0.10); // 10% commission on food amount
            } else if (escrow == 'held') {
              escrowHeld += total;
              if (status == 'delivered') {
                pendingRelease += total;
              }
            } else if (escrow == 'refunded') {
              refundedAmount += total;
            }
            // ... switch status block ...

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
        'pendingRelease': pendingRelease,
        'adminCommission': adminCommission,
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
        'pendingRelease': 0.0,
        'adminCommission': 0.0,
      };
    }
  }

  /// Get monthly revenue for the last 6 months
  static Future<List<double>> getMonthlyRevenue() async {
    try {
      final snapshot = await _ordersRef.get();
      final List<double> monthlyValues = List.filled(12, 0.0);

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && value['escrowStatus'] == 'released') {
            final date = _parseDateTime(value['createdAt']);
            final amount = (value['totalAmount'] ?? 0).toDouble();
            final deliveryFee = (value['deliveryFee'] ?? 0).toDouble();
            // Group by month (0-11)
            monthlyValues[date.month - 1] += (amount + deliveryFee);
          }
        });
      }

      // Get last 6 months in order
      final now = DateTime.now();
      final List<double> last6Months = [];
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        int monthIndex = monthDate.month - 1;
        if (monthIndex < 0) monthIndex += 12;
        last6Months.add(monthlyValues[monthIndex]);
      }
      return last6Months;
    } catch (e) {
      print('Error getting monthly revenue: $e');
      return List.filled(6, 0.0);
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Delete an order (Admin only)
  static Future<void> deleteOrder(String orderId) async {
    try {
      await RealtimeDatabaseService.ref('orders/$orderId').remove();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }
}
