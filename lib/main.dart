import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'services/realtime_database_service.dart';
import 'services/fcm_service.dart';
import 'controllers/dashboard_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/layout/dashboard_layout.dart';

void main() async {
  print('🚀 Starting Culinary Admin Dashboard...');
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Initialized');
  } catch (e) {
    print('❌ Firebase Initialization Error: $e');
  }

  // Initialize Realtime Database
  print('💾 Initializing Realtime Database...');
  await RealtimeDatabaseService.initialize();

  // Initialize FCM Service
  print('🔔 Initializing FCM...');
  try {
    await FcmService.initialize();
    print('✅ FCM Initialized');
  } catch (e) {
    print("❌ FCM Initialization Failed: $e");
  }

  // Initialize GetX controllers
  print('🎮 Initializing Controllers...');
  Get.put(AuthController());
  Get.put(DashboardController());

  print('🏁 Running App...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Culinary Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardLayout()),
      ],
    );
  }
}
