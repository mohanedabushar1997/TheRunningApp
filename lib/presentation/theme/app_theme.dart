import 'package:flutter/material.dart';
import 'package:running_app/presentation/theme/app_colors.dart'; // Import colors

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.light,
      // Override specific colors if needed
       // primary: AppColors.primaryColor,
       // secondary: AppColors.secondaryColor,
       // surface: AppColors.lightSurface,
       // background: AppColors.lightBackground,
       // error: AppColors.errorColor,
       // onPrimary: AppColors.onPrimary,
       // onSecondary: AppColors.onSecondary,
       // onSurface: AppColors.lightOnSurface,
       // onBackground: AppColors.lightOnSurface,
       // onError: AppColors.onError,
    ),
    // Define other theme properties like text theme, app bar theme, etc.
    textTheme: _buildTextTheme(ThemeData.light().textTheme), // Base on default light theme
    appBarTheme: AppBarTheme(
      elevation: 1,
      // backgroundColor: AppColors.primaryColor, // Example: Use primary color
      // foregroundColor: AppColors.onPrimary, // Example: White text on primary background
       backgroundColor: ThemeData.light().colorScheme.surface, // More standard M3 look
       foregroundColor: ThemeData.light().colorScheme.onSurface,
       surfaceTintColor: ThemeData.light().colorScheme.surfaceTint, // For scrolled under effect
       centerTitle: false,
    ),
     cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        // color: AppColors.lightSurface,
        margin: const EdgeInsets.symmetric(vertical: 4.0), // Default vertical margin for cards
     ),
     inputDecorationTheme: InputDecorationTheme(
       border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
       ),
        // filled: true, // Optional: Fill background
        // fillColor: Colors.grey.shade100,
     ),
      // Define other components theme...
      // elevatedButtonTheme: ...,
      // textButtonTheme: ...,
      // bottomNavigationBarTheme: ...
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor, // Use same seed for consistent hues
      brightness: Brightness.dark,
      // Override specific dark colors if needed
       // primary: AppColors.primaryColorDark ?? AppColors.primaryColor,
       // secondary: AppColors.secondaryColorDark ?? AppColors.secondaryColor,
       // surface: AppColors.darkSurface,
       // background: AppColors.darkBackground,
       // error: AppColors.errorColorDark ?? AppColors.errorColor,
    ),
    textTheme: _buildTextTheme(ThemeData.dark().textTheme), // Base on default dark theme
    appBarTheme: AppBarTheme(
       elevation: 1,
       backgroundColor: ThemeData.dark().colorScheme.surface, // Use M3 surface colors
       foregroundColor: ThemeData.dark().colorScheme.onSurface,
       surfaceTintColor: ThemeData.dark().colorScheme.surfaceTint,
       centerTitle: false,
    ),
     cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        // color: AppColors.darkSurface,
         margin: const EdgeInsets.symmetric(vertical: 4.0),
     ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8.0),
        ),
      ),
     // Define other dark theme components...
  );

   // --- Text Theme Customization (Example) ---
   // You can customize specific text styles here
   static TextTheme _buildTextTheme(TextTheme base) {
      return base.copyWith(
         // Example: Make headlines slightly bolder
         headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
         titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
         // Example: Adjust body text size or color
          // bodyMedium: base.bodyMedium?.copyWith(fontSize: 15.0),
      ).apply(
         // Apply global font family if desired
         // fontFamily: 'YourCustomFont', // TODO: Define font in pubspec.yaml
      );
   }

}