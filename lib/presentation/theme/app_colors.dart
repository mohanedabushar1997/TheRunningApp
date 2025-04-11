import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // --- Primary & Secondary Colors ---
  // Define your main brand colors
  // Use hex values (e.g., 0xFF followed by RRGGBB)
  static const Color primaryColor = Color(0xFF2E7D32); // Example: A green shade
  static const Color secondaryColor = Color(0xFFFF8F00); // Example: An amber shade

  // Optional: Define variants for dark theme if needed
  // static const Color primaryColorDark = Color(0xFF66BB6A); // Lighter green for dark theme
  // static const Color secondaryColorDark = Color(0xFFFFB74D); // Lighter amber for dark theme

  // --- Surface & Background Colors (Optional Overrides) ---
  // Usually derived from seed color in ColorScheme.fromSeed, but can be overridden
  // Light Theme
  static const Color lightSurface = Colors.white;
  static const Color lightBackground = Color(0xFFF8F9FA); // Slightly off-white
  static const Color lightOnSurface = Colors.black87;

  // Dark Theme
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark grey
  static const Color darkBackground = Color(0xFF121212); // Very dark grey (standard Material dark)
  static const Color darkOnSurface = Colors.white;

  // --- Text & Icon Colors (Optional Overrides) ---
  // Defined by ColorScheme's 'on...' properties (onPrimary, onSecondary, onSurface, etc.)
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onError = Colors.white;

  // --- Other Colors ---
  static const Color errorColor = Color(0xFFD32F2F); // Standard Material error red
  static const Color errorColorDark = Color(0xFFE57373); // Lighter red for dark theme

  static const Color successColor = Color(0xFF388E3C); // Green for success messages
  static const Color warningColor = Color(0xFFFFA000); // Amber for warnings

  // Specific UI element colors (examples)
  static const Color chartLineColor = primaryColor;
  static const Color mapRouteColor = primaryColor;
  static const Color favoriteColor = Colors.redAccent;
}