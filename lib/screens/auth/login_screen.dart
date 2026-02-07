import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.put(AuthController());
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        Get.offAllNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
            ),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? screenWidth * 0.9 : 450,
                ),
                padding: EdgeInsets.all(
                  isMobile ? AppSizes.paddingLG : AppSizes.paddingXL,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Container(
                        padding: EdgeInsets.all(
                          isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: isMobile ? 48 : 64,
                          color: AppColors.primary,
                        ),
                      ).animateScaleIn(),

                      SizedBox(
                        height: isMobile
                            ? AppSizes.paddingMD
                            : AppSizes.paddingLG,
                      ),

                      // Title
                      Text(
                        'Admin Dashboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ).animateFadeInUp(delay: 100),

                      const SizedBox(height: AppSizes.paddingSM),

                      Text(
                        'Sign in to manage Culinary Tales',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                      ).animateFadeInUp(delay: 200),

                      SizedBox(
                        height: isMobile
                            ? AppSizes.paddingLG
                            : AppSizes.paddingXL,
                      ),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSM,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!GetUtils.isEmail(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ).animateFadeInUp(delay: 300),

                      const SizedBox(height: AppSizes.paddingMD),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSM,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ).animateFadeInUp(delay: 400),

                      const SizedBox(height: AppSizes.paddingLG),

                      // Error Message
                      Obx(() {
                        if (_authController.errorMessage.value.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSizes.paddingMD),
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingMD,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSM,
                              ),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: AppSizes.paddingSM),
                                Expanded(
                                  child: Text(
                                    _authController.errorMessage.value,
                                    style: GoogleFonts.inter(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Login Button
                      Obx(
                        () => ElevatedButton(
                          onPressed: _authController.isLoading.value
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingMD,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSM,
                              ),
                            ),
                            elevation: 2,
                          ),
                          child: _authController.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingMD),

                      // Footer
                      Text(
                        '© 2026 Culinary Tales. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
