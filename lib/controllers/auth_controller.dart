import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/realtime_database_service.dart';
import 'dart:async';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<User?> _user = Rx<User?>(null);
  User? get user => _user.value;
  bool get isLoggedIn => _user.value != null;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _adminListener;

  // Super admin email that bypasses database whitelist
  static const String _superAdminEmail = 'rimon124567@gmail.com';

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_auth.authStateChanges());
    // Listen for user changes to verify admin status
    ever(_user, _handleAdminVerification);
  }

  @override
  void onClose() {
    _adminListener?.cancel();
    super.onClose();
  }

  void _handleAdminVerification(User? user) {
    if (user == null) {
      _adminListener?.cancel();
      _adminListener = null;
      return;
    }

    // Bypass check for super admin
    if (user.email?.toLowerCase() == _superAdminEmail.toLowerCase()) {
      _adminListener?.cancel();
      _adminListener = null;
      print(
        '👑 Super Admin detected (${user.email}). Bypassing whitelist check.',
      );
      return;
    }
    print('🔍 Verifying admin access for: ${user.email}');

    // Start listening to the admins node to ensure this user is still authorized
    _adminListener?.cancel();
    _adminListener = RealtimeDatabaseService.ref('admins').onValue.listen((
      event,
    ) {
      if (event.snapshot.value == null) {
        // No admins defined at all? This shouldn't happen if user is logged in
        // as an admin, but for safety, logout if whitelist is empty.
        _forceLogout('Unauthorized access.');
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      bool isAuthorized = false;

      data.forEach((key, value) {
        if (value is Map) {
          final adminEmail = value['email']?.toString().toLowerCase();
          if (adminEmail == user.email?.toLowerCase()) {
            isAuthorized = true;
          }
        }
      });

      if (!isAuthorized) {
        print('⛔ Authorization failed for: ${user.email}. Access revoked.');
        _forceLogout('Your admin access has been revoked.');
      } else {
        print('✅ Authorized: ${user.email} is in whitelist.');
      }
    });
  }

  void _forceLogout(String message) {
    _adminListener?.cancel();
    _adminListener = null;
    logout();
    Get.offAllNamed('/login');
    Get.snackbar(
      'Access Denied',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Early check for non-super admins if database is reachable
      if (email.toLowerCase() != _superAdminEmail.toLowerCase()) {
        final snapshot = await RealtimeDatabaseService.ref('admins').get();
        bool found = false;
        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            if (value is Map &&
                value['email']?.toString().toLowerCase() ==
                    email.toLowerCase()) {
              found = true;
            }
          });
        }

        if (!found) {
          await logout();
          errorMessage.value = 'You are not authorized as an admin.';
          return false;
        }
      }

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'No admin found with this email.';
          break;
        case 'wrong-password':
          errorMessage.value = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage.value = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage.value = 'This account has been disabled.';
          break;
        default:
          errorMessage.value = 'Login failed: ${e.message}';
      }
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      errorMessage.value = 'Logout failed.';
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Failed to send reset email.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
