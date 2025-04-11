import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;

  const ErrorDisplayWidget({
    required this.errorMessage,
    this.onRetry,
    this.retryText = 'Retry',
    this.icon = Icons.error_outline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
               icon,
               size: 64,
               color: colorScheme.error.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
              style: textTheme.titleLarge?.copyWith(
                 color: colorScheme.error,
                 fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
             Text(
               errorMessage,
               style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer, // Use contrast color
               ),
               textAlign: TextAlign.center,
             ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                   backgroundColor: colorScheme.errorContainer,
                   foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}