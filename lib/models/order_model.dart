import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

enum EscrowStatus { held, released, refunded }

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? courierId;
  final String buyerName;
  final String sellerName;
  final String? courierName;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final OrderStatus status;
  final EscrowStatus escrowStatus;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? notes;
  final bool hasDispute;
  final String? trackingNumber;
  final String? trackingProvider;
  final String? disputeDetails;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.courierId,
    required this.buyerName,
    required this.sellerName,
    this.courierName,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    required this.escrowStatus,
    required this.deliveryAddress,
    required this.createdAt,
    this.deliveredAt,
    this.notes,
    this.hasDispute = false,
    this.trackingNumber,
    this.trackingProvider,
    this.disputeDetails,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      courierId: data['courierId'],
      buyerName: data['buyerName'] ?? '',
      sellerName: data['sellerName'] ?? '',
      courierName: data['courierName'],
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      status: _parseOrderStatus(data['status']),
      escrowStatus: _parseEscrowStatus(data['escrowStatus']),
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      hasDispute: data['hasDispute'] ?? false,
      trackingNumber: data['trackingNumber'],
      trackingProvider: data['trackingProvider'],
      disputeDetails: data['disputeDetails'],
    );
  }

  factory OrderModel.fromRealtimeDatabase(
    String id,
    Map<dynamic, dynamic> data,
  ) {
    return OrderModel(
      id: id,
      buyerId: data['buyerId']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      courierId: data['courierId']?.toString(),
      buyerName: data['buyerName']?.toString() ?? '',
      sellerName: data['sellerName']?.toString() ?? '',
      courierName: data['courierName']?.toString(),
      items: data['items'] != null
          ? (data['items'] as List)
                .map(
                  (item) =>
                      OrderItem.fromMap(Map<String, dynamic>.from(item as Map)),
                )
                .toList()
          : [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      status: _parseOrderStatus(data['status']),
      escrowStatus: _parseEscrowStatus(data['escrowStatus']),
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      deliveredAt: _parseDateTime(data['deliveredAt'], isOptional: true),
      notes: data['notes']?.toString(),
      hasDispute: data['hasDispute'] as bool? ?? false,
      trackingNumber: data['trackingNumber']?.toString(),
      trackingProvider: data['trackingProvider']?.toString(),
      disputeDetails: data['disputeDetails']?.toString(),
    );
  }

  static DateTime _parseDateTime(dynamic value, {bool isOptional = false}) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static OrderStatus _parseOrderStatus(dynamic value) {
    if (value is String) {
      return OrderStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
    }
    return OrderStatus.pending;
  }

  static EscrowStatus _parseEscrowStatus(dynamic value) {
    if (value is String) {
      return EscrowStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => EscrowStatus.held,
      );
    }
    return EscrowStatus.held;
  }

  double get grandTotal => totalAmount + deliveryFee;
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  double get totalPrice => price * quantity;
}
