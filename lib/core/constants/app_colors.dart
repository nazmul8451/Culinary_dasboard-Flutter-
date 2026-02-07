import 'package:flutter/material.dart';

/// App-wide color constants for Culinary Admin Dashboard
class AppColors {
  // Primary Colors (Orange theme matching mobile app)
  static const Color primary = Color(0xFFE84E31);
  static const Color primaryLight = Color(0xFFF18C7B);
  static const Color primaryDark = Color(0xFFB53D26);

  // Secondary Colors
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Background Colors
  static const Color background = Color(
    0xFFF8F9FA,
  ); // Softer, more professional background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(
    0xFFF1F3F5,
  ); // Slightly darker surface for contrast
  static const Color cardShadow = Color(0x0A000000); // Very soft shadow
  static const Color cardShadowSubtle = Color(
    0x05000000,
  ); // Extremely subtle shadow

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Drawer/Sidebar Colors (Premium Light Theme)
  static const Color drawerBackground = Color(0xFFFFFFFF);
  static const Color drawerTextUnselected = Color(0xFF424242);
  static const Color drawerIconUnselected = Color(0xFF757575);
  static const Color drawerHover = Color(0xFFF5F5F5);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFFE84E31),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE84E31), Color(0xFFF18C7B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
