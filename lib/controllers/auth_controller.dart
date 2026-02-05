import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<User?> _user = Rx<User?>(null);
  User? get user => _user.value;
  bool get isLoggedIn => _user.value != null;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_auth.authStateChanges());
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInWithEmailAndPassword(email: email, password: password);

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
