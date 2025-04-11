import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath; // Path to asset image

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0), // Adjusted padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Image ---
           Expanded(
             flex: 5, // Give image ample space
             child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Image.asset(
                   imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                       // Nicer placeholder for missing image asset
                       return LayoutBuilder(builder: (context, constraints) {
                           return Container(
                              width: constraints.maxWidth * 0.6,
                              height: constraints.maxWidth * 0.6,
                              decoration: BoxDecoration(
                                 color: Colors.grey.shade200,
                                 borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.image_not_supported_outlined, size: constraints.maxWidth * 0.2, color: Colors.grey.shade400),
                           );
                       });
                    },
                 )
             ),
           ),

          // --- Text Content ---
           Expanded( // Allow text to take remaining space
             flex: 3,
             child: Column(
                children: [
                   Text(
                     title,
                     style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 16.0),
                   Text(
                     description,
                     style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                         height: 1.4,
                     ),
                     textAlign: TextAlign.center,
                   ),
                ],
             ),
           ),
        ],
      ),
    );
  }
}