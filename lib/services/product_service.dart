import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';
import 'realtime_database_service.dart';

/// Service for managing product data from Realtime Database
class ProductService {
  static final DatabaseReference _productsRef = RealtimeDatabaseService.ref(
    'products',
  );

  /// Get all products as a stream
  static Stream<List<ProductModel>> getAllProducts() {
    return _productsRef.onValue.map((event) {
      final List<ProductModel> products = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            products.add(
              ProductModel.fromRealtimeDatabase(
                key.toString(),
                Map<dynamic, dynamic>.from(value),
              ),
            );
          }
        });
      }
      return products;
    });
  }

  /// Get products by seller
  static Stream<List<ProductModel>> getProductsBySeller(String sellerId) {
    return _productsRef.orderByChild('sellerId').equalTo(sellerId).onValue.map((
      event,
    ) {
      final List<ProductModel> products = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            products.add(
              ProductModel.fromRealtimeDatabase(
                key.toString(),
                Map<dynamic, dynamic>.from(value),
              ),
            );
          }
        });
      }
      return products;
    });
  }

  /// Toggle product active status
  static Future<void> toggleProductStatus(
    String productId,
    bool isActive,
  ) async {
    try {
      await _productsRef.child(productId).update({'isActive': isActive});
    } catch (e) {
      print('Error toggling product status: $e');
      rethrow;
    }
  }

  /// Get product statistics
  static Future<Map<String, int>> getProductStatistics() async {
    try {
      final snapshot = await _productsRef.get();
      int totalProducts = 0;
      int activeProducts = 0;
      int inactiveProducts = 0;

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        totalProducts = data.length;

        data.forEach((key, value) {
          if (value is Map) {
            final isActive = value['isActive'] as bool? ?? true;
            if (isActive) {
              activeProducts++;
            } else {
              inactiveProducts++;
            }
          }
        });
      }

      return {
        'total': totalProducts,
        'active': activeProducts,
        'inactive': inactiveProducts,
      };
    } catch (e) {
      print('Error getting product statistics: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }
}
