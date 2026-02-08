import 'dart:async';
import '../models/user_model.dart';
import 'realtime_database_service.dart';

/// Service for managing user data from Realtime Database
class UserService {
  /// Get all users as a stream (combines buyer, seller, courier)
  static Stream<List<UserModel>> getAllUsers() {
    print('🔍 UserService.getAllUsers - Initializing combined stream');

    // Combine streams from all three user types
    final buyerStream = _getUsersFromNode('buyer', UserType.buyer);
    final sellerStream = _getUsersFromNode('seller', UserType.seller);
    final courierStream = _getUsersFromNode('courier', UserType.courier);

    return _combineStreams([
      buyerStream.map((u) => {UserType.buyer: u}).asBroadcastStream(),
      sellerStream.map((u) => {UserType.seller: u}).asBroadcastStream(),
      courierStream.map((u) => {UserType.courier: u}).asBroadcastStream(),
    ]);
  }

  static Stream<List<UserModel>> _combineStreams(
    List<Stream<Map<UserType, List<UserModel>>>> streams,
  ) {
    late StreamController<List<UserModel>> controller;
    final List<StreamSubscription> subscriptions = [];

    controller = StreamController<List<UserModel>>.broadcast(
      onListen: () {
        final Map<UserType, List<UserModel>> currentData = {};
        for (int i = 0; i < streams.length; i++) {
          final sub = streams[i].listen(
            (data) {
              currentData.addAll(data);
              final allUsers = <UserModel>[];
              currentData.forEach((key, value) => allUsers.addAll(value));
              if (!controller.isClosed) {
                controller.add(allUsers);
              }
            },
            onError: (e) {
              if (!controller.isClosed) {
                controller.addError(e);
              }
            },
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// Helper method to get users from a specific node
  static Stream<List<UserModel>> _getUsersFromNode(
    String nodeName,
    UserType userType,
  ) {
    final nodeRef = RealtimeDatabaseService.ref(nodeName);

    return nodeRef.onValue.map((event) {
      final List<UserModel> users = [];

      print('🔍 Fetching from $nodeName node');

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        print('Found ${data.length} users in $nodeName');

        data.forEach((key, value) {
          if (value is Map) {
            try {
              final userData = Map<dynamic, dynamic>.from(value);
              // Add userType field since it's not in the database
              userData['userType'] = userType.name;

              final user = UserModel.fromRealtimeDatabase(
                key.toString(),
                userData,
              );
              users.add(user);
              print('✅ Added ${userType.name}: ${user.name}');
            } catch (e) {
              print('❌ Error parsing $nodeName $key: $e');
            }
          }
        });
      }

      return users;
    }).asBroadcastStream();
  }

  /// Get users by type
  static Stream<List<UserModel>> getUsersByType(UserType type) {
    print('🔍 Getting users of type: ${type.name}');
    return _getUsersFromNode(type.name, type);
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final nodes = ['buyer', 'seller', 'courier'];
      for (final node in nodes) {
        final nodeRef = RealtimeDatabaseService.ref('$node/$userId');
        final snapshot = await nodeRef.get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          // Determine UserType based on node
          UserType type = UserType.buyer;
          if (node == 'seller') type = UserType.seller;
          if (node == 'courier') type = UserType.courier;
          data['userType'] = type.name;

          return UserModel.fromRealtimeDatabase(userId, data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Update user status
  static Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      // Try to update in all three nodes (only one will succeed)
      final nodes = ['buyer', 'seller', 'courier'];

      for (final node in nodes) {
        final nodeRef = RealtimeDatabaseService.ref('$node/$userId');
        final snapshot = await nodeRef.get();

        if (snapshot.exists) {
          await nodeRef.update({
            'status': status.name,
            'isBanned': status == UserStatus.banned,
          });
          print('✅ Updated status for user $userId in $node node');
          return;
        }
      }

      print('⚠️ User $userId not found in any node');
    } catch (e) {
      print('❌ Error updating user status: $e');
      rethrow;
    }
  }

  /// Update verification status with reason (for rejection)
  static Future<void> updateVerificationStatus(
    String userId,
    VerificationStatus status, {
    String? reason,
  }) async {
    try {
      final nodes = ['buyer', 'seller', 'courier'];
      for (final node in nodes) {
        final nodeRef = RealtimeDatabaseService.ref('$node/$userId');
        final snapshot = await nodeRef.get();
        if (snapshot.exists) {
          final Map<String, dynamic> updates = {
            'verificationStatus': status.name,
            'isVerified': status == VerificationStatus.verified,
          };

          if (reason != null) {
            updates['rejectionReason'] = reason;
          }

          // If approved, start trial period for sellers
          if (status == VerificationStatus.verified && node == 'seller') {
            updates['trialStartDate'] = DateTime.now().millisecondsSinceEpoch;
            updates['trialEndDate'] = DateTime.now()
                .add(const Duration(days: 14))
                .millisecondsSinceEpoch;
          }

          await nodeRef.update(updates);
          print('✅ Updated verification for user $userId in $node node');
          return;
        }
      }
      print('⚠️ User $userId not found for verification update');
    } catch (e) {
      print('❌ Error updating verification status: $e');
      rethrow;
    }
  }

  /// Update detailed verification status (ID/Facial)
  static Future<void> updateDetailedVerification(
    String userId, {
    VerificationStatus? idStatus,
    VerificationStatus? facialStatus,
  }) async {
    try {
      final nodes = ['buyer', 'seller', 'courier'];
      for (final node in nodes) {
        final nodeRef = RealtimeDatabaseService.ref('$node/$userId');
        final snapshot = await nodeRef.get();
        if (snapshot.exists) {
          final Map<String, dynamic> updates = {};
          if (idStatus != null) {
            updates['idVerificationStatus'] = idStatus.name;
          }
          if (facialStatus != null) {
            updates['facialVerificationStatus'] = facialStatus.name;
          }

          if (updates.isNotEmpty) {
            await nodeRef.update(updates);
            print('✅ Updated detailed verification for $userId in $node');
          }
          return;
        }
      }
    } catch (e) {
      print('❌ Error updating detailed verification: $e');
      rethrow;
    }
  }

  /// Update seller shipping rules
  static Future<void> updateShippingRules(
    String userId, {
    double? costPerKg,
    double? minShippingFee,
    Map<String, dynamic>? shippingRules,
  }) async {
    try {
      final nodeRef = RealtimeDatabaseService.ref('seller/$userId');
      final snapshot = await nodeRef.get();
      if (snapshot.exists) {
        final Map<String, dynamic> updates = {};
        if (costPerKg != null) updates['costPerKg'] = costPerKg;
        if (minShippingFee != null) updates['minShippingFee'] = minShippingFee;
        if (shippingRules != null) updates['shippingRules'] = shippingRules;

        if (updates.isNotEmpty) {
          await nodeRef.update(updates);
          print('✅ Updated shipping rules for seller $userId');
        }
      }
    } catch (e) {
      print('❌ Error updating shipping rules: $e');
      rethrow;
    }
  }

  /// Manually update trial status
  static Future<void> updateTrialStatus(
    String userId,
    DateTime startDate,
    int durationDays,
  ) async {
    try {
      final nodeRef = RealtimeDatabaseService.ref('seller/$userId');
      final snapshot = await nodeRef.get();
      if (snapshot.exists) {
        await nodeRef.update({
          'trialStartDate': startDate.millisecondsSinceEpoch,
          'trialEndDate': startDate
              .add(Duration(days: durationDays))
              .millisecondsSinceEpoch,
        });
        print('✅ Updated trial status for seller $userId');
      }
    } catch (e) {
      print('❌ Error updating trial status: $e');
      rethrow;
    }
  }

  /// Get user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      print('\n📊 Getting user statistics from separate nodes...');

      // Fetch from each node separately
      final buyerSnapshot = await RealtimeDatabaseService.ref('buyer').get();
      final sellerSnapshot = await RealtimeDatabaseService.ref('seller').get();
      final courierSnapshot = await RealtimeDatabaseService.ref(
        'courier',
      ).get();

      int buyers = 0;
      int sellers = 0;
      int couriers = 0;

      if (buyerSnapshot.exists && buyerSnapshot.value != null) {
        buyers = (buyerSnapshot.value as Map<dynamic, dynamic>).length;
        print('Buyers found: $buyers');
      }

      if (sellerSnapshot.exists && sellerSnapshot.value != null) {
        sellers = (sellerSnapshot.value as Map<dynamic, dynamic>).length;
        print('Sellers found: $sellers');
      }

      if (courierSnapshot.exists && courierSnapshot.value != null) {
        couriers = (courierSnapshot.value as Map<dynamic, dynamic>).length;
        print('Couriers found: $couriers');
      }

      final totalUsers = buyers + sellers + couriers;

      final stats = {
        'total': totalUsers,
        'buyers': buyers,
        'sellers': sellers,
        'couriers': couriers,
      };

      print('📈 Final statistics: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting user statistics: $e');
      return {'total': 0, 'buyers': 0, 'sellers': 0, 'couriers': 0};
    }
  }

  /// Update FCM token for a user
  static Future<void> updateFcmToken(String userId, String token) async {
    try {
      final nodes = ['buyer', 'seller', 'courier'];
      for (final node in nodes) {
        final nodeRef = RealtimeDatabaseService.ref('$node/$userId');
        final snapshot = await nodeRef.get();
        if (snapshot.exists) {
          await nodeRef.update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
          });
          print('✅ Updated FCM token for user $userId in $node node');
          return;
        }
      }
      print('⚠️ User $userId not found for FCM token update');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }
}
