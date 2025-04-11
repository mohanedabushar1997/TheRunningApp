import 'package:flutter/material.dart';

// Displays key metrics during an active workout
class WorkoutMetricsPanel extends StatelessWidget {
  final String duration;
  final String distance;
  final String pace;
  final String calories;
  final String? heartRate; // Optional HR display
  final String? targetPace; // Optional target pace display

  const WorkoutMetricsPanel({
    required this.duration,
    required this.distance,
    required this.pace,
    required this.calories,
    this.heartRate,
    this.targetPace,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Primary metrics (e.g., Duration, Distance, Pace)
    final List<Widget> primaryMetrics = [
       _buildMetric(context, "Duration", duration, isPrimary: true),
       _buildMetric(context, "Distance", distance, isPrimary: true),
       _buildMetric(context, "Avg Pace", pace, isPrimary: true),
    ];

    // Secondary metrics (Calories, HR)
    final List<Widget> secondaryMetrics = [
       _buildMetric(context, "Calories", calories, isPrimary: false, icon: Icons.local_fire_department_outlined),
       if (heartRate != null && heartRate != '--')
          _buildMetric(context, "Heart Rate", "$heartRate bpm", isPrimary: false, icon: Icons.favorite_border),
    ];

    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Adjusted padding
       color: colorScheme.surface, // Use surface color
       // Use Material for elevation/shadow simulation if desired
       // elevation: 1,
       // shadowColor: Colors.black.withOpacity(0.1),
       child: Column(
          children: [
             // --- Primary Metrics Row ---
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Align labels top
                children: primaryMetrics.map((metric) => Expanded(child: Center(child: metric))).toList(),
             ),
              // --- Secondary Metrics Row ---
              if (secondaryMetrics.isNotEmpty) ...[
                 const SizedBox(height: 8), // Reduced space
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: secondaryMetrics,
                 ),
              ],
              // TODO: Add target pace/zone display if available
              // if (targetPace != null) ... [ SizedBox(height: 4), Text(targetPace!, style: textTheme.labelSmall?.copyWith(color: colorScheme.secondary)) ]
          ],
       ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, {required bool isPrimary, IconData? icon}) {
     final textTheme = Theme.of(context).textTheme;
     final colorScheme = Theme.of(context).colorScheme;

     final labelStyle = textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withOpacity(0.9),
        fontSize: isPrimary ? 11 : 10, // Slightly smaller labels
     );
     final valueStyle = isPrimary
          ? textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.1) // Tighter line height
          : textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500); // Smaller secondary value

     return Column(
       crossAxisAlignment: isPrimary ? CrossAxisAlignment.center : CrossAxisAlignment.center, // Center align secondary too
       mainAxisSize: MainAxisSize.min,
       children: [
         Row( // Icon and Label row
            mainAxisSize: MainAxisSize.min,
            children: [
               if (icon != null) ...[ Icon(icon, size: 14, color: labelStyle?.color), const SizedBox(width: 3), ],
               Text(label.toUpperCase(), style: labelStyle),
            ],
         ),
         if (isPrimary) const SizedBox(height: 3) else const SizedBox(height: 2),
         Text(
            value,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.fade, // Fade if too long
            softWrap: false,
         ),
       ],
     );
  }
}