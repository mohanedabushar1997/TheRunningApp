import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- App Logo/Icon ---
             Icon(
               Icons.directions_run, // Placeholder Icon
               size: screenWidth * 0.3,
               color: colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),

            // --- App Name & Tagline ---
            Text(
              'FitStride', // Your App Name
              style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                 ),
            ),
            const SizedBox(height: 8),
             Text(
               'Your stride, your pace.', // Your App Tagline
               style: textTheme.titleMedium?.copyWith(
                     color: colorScheme.onPrimary.withOpacity(0.85),
                     fontStyle: FontStyle.italic,
                  ),
             ),
              const SizedBox(height: 60), // Space before loading indicator

            // --- Loading Indicator ---
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 16),
             Text(
               'Loading...',
               style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.7)),
             ),
          ],
        ),
      ),
    );
  }
}