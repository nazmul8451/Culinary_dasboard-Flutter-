import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

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
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? notes;
  final bool hasDispute;

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
    required this.deliveryAddress,
    required this.createdAt,
    this.deliveredAt,
    this.notes,
    this.hasDispute = false,
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
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      hasDispute: data['hasDispute'] ?? false,
    );
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
