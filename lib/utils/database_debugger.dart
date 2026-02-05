import 'package:firebase_database/firebase_database.dart';
import '../services/realtime_database_service.dart';

/// Debug utility to check Firebase Realtime Database structure
class DatabaseDebugger {
  static Future<void> checkDatabaseStructure() async {
    print('=== Checking Firebase Realtime Database Structure ===');

    // Check users
    final usersRef = RealtimeDatabaseService.ref('users');
    final usersSnapshot = await usersRef.get();

    if (usersSnapshot.exists) {
      print('\n✅ Users node exists');
      final usersData = usersSnapshot.value;
      print('Users data type: ${usersData.runtimeType}');

      if (usersData is Map) {
        print('Total users: ${usersData.length}');

        // Print first user structure
        final firstUserKey = usersData.keys.first;
        final firstUser = usersData[firstUserKey];
        print('\nFirst user structure:');
        print('Key: $firstUserKey');
        print('Data: $firstUser');

        if (firstUser is Map) {
          print('\nUser fields:');
          firstUser.forEach((key, value) {
            print('  $key: $value (${value.runtimeType})');
          });
        }
      }
    } else {
      print('\n❌ Users node does NOT exist');
    }

    // Check orders
    final ordersRef = RealtimeDatabaseService.ref('orders');
    final ordersSnapshot = await ordersRef.get();

    if (ordersSnapshot.exists) {
      print('\n✅ Orders node exists');
      final ordersData = ordersSnapshot.value;
      print('Orders data type: ${ordersData.runtimeType}');

      if (ordersData is Map) {
        print('Total orders: ${ordersData.length}');

        // Print first order structure
        final firstOrderKey = ordersData.keys.first;
        final firstOrder = ordersData[firstOrderKey];
        print('\nFirst order structure:');
        print('Key: $firstOrderKey');

        if (firstOrder is Map) {
          print('\nOrder fields:');
          firstOrder.forEach((key, value) {
            print('  $key: $value (${value.runtimeType})');
          });
        }
      }
    } else {
      print('\n❌ Orders node does NOT exist');
    }

    // Check products
    final productsRef = RealtimeDatabaseService.ref('products');
    final productsSnapshot = await productsRef.get();

    if (productsSnapshot.exists) {
      print('\n✅ Products node exists');
      final productsData = productsSnapshot.value;
      print('Products data type: ${productsData.runtimeType}');

      if (productsData is Map) {
        print('Total products: ${productsData.length}');
      }
    } else {
      print('\n❌ Products node does NOT exist');
    }

    print('\n=== Database Structure Check Complete ===');
  }

  static Future<void> checkRootStructure() async {
    print('\n=== Checking Root Structure ===');
    final rootRef = RealtimeDatabaseService.database;
    final rootSnapshot = await rootRef.get();

    if (rootSnapshot.exists) {
      final rootData = rootSnapshot.value;
      if (rootData is Map) {
        print('Root nodes:');
        rootData.keys.forEach((key) {
          print('  - $key');
        });
      }
    } else {
      print('❌ No data at root level');
    }
  }
}
