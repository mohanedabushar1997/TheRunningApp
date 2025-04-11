import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onActionPressed; // Optional action (e.g., "View All")
  final String? actionText;

  const SectionTitle({
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 8.0, top: 8.0), // Default padding
    this.onActionPressed,
    this.actionText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
               fontWeight: FontWeight.w600,
               // color: colorScheme.onSurface,
            ),
          ),
          if (onActionPressed != null && actionText != null)
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                 padding: EdgeInsets.zero,
                 minimumSize: const Size(50, 30), // Ensure minimum tap area
                 alignment: Alignment.centerRight,
                 visualDensity: VisualDensity.compact,
              ),
              child: Text(
                 actionText!,
                 style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}