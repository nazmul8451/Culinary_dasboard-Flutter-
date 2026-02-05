import 'package:firebase_database/firebase_database.dart';

/// Base service for Firebase Realtime Database operations
/// Provides common functionality for all database services
class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get database reference
  static DatabaseReference get database => _database.ref();

  /// Get reference to a specific path
  static DatabaseReference ref(String path) => _database.ref(path);

  /// Enable offline persistence
  static Future<void> enablePersistence() async {
    try {
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
    } catch (e) {
      print('Error enabling persistence: $e');
    }
  }

  /// Get connection state stream
  static Stream<bool> get connectionState {
    return _database.ref('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Initialize database with settings
  static Future<void> initialize() async {
    try {
      await enablePersistence();
      print('Realtime Database initialized successfully');
    } catch (e) {
      print('Error initializing Realtime Database: $e');
    }
  }
}
