import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final double iconSize;
  final VoidCallback? onRetry; // Optional action button
  final String retryText;

  const EmptyStateWidget({
    required this.message,
    this.icon,
    this.iconSize = 64.0,
    this.onRetry,
    this.retryText = 'Retry',
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
            if (icon != null)
              Icon(
                 icon,
                 size: iconSize,
                 color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}