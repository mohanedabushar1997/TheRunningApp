import 'package:flutter/material.dart';

/// A card widget that displays a workout stat with a label and value
/// Used in the active workout screen to show key metrics
class WorkoutStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const WorkoutStatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stat icon
        Icon(
          icon,
          size: 20,
          color: theme.primaryColor,
        ),
        
        const SizedBox(height: 4.0),
        
        // Stat value
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Stat label
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
