import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    this.textStyle,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedForegroundColor = colorScheme.onPrimary;
    final unselectedForegroundColor = colorScheme.onSurfaceVariant;
    final selectedBackgroundColor = colorScheme.primary;
    final unselectedBackgroundColor = colorScheme.surfaceContainerHighest; // Subtle background
    final defaultTextStyle = Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? selectedForegroundColor : unselectedForegroundColor,
      ),
      label: Text(label),
      labelStyle: (textStyle ?? defaultTextStyle).copyWith(
         color: isSelected ? selectedForegroundColor : colorScheme.onSurface,
         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: unselectedBackgroundColor,
      selectedColor: selectedBackgroundColor,
      // checkmarkColor: selectedForegroundColor, // No checkmark needed for FilterChip usually
      showCheckmark: false, // Hide checkmark
      side: isSelected
          ? null // No border when selected (using background color)
          : BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
       shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
       ),
       visualDensity: VisualDensity.compact,
    );
  }
}