import 'package:flutter/material.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/utils/format_utils.dart'; // Import formatter

class RecentActivityCard extends StatelessWidget {
  final Workout workout;
  final bool useImperial;
  final VoidCallback? onTap; // Callback for when the card is tapped

  const RecentActivityCard({
    required this.workout,
    required this.useImperial,
    this.onTap,
    super.key,
  });

  IconData _getWorkoutIcon(WorkoutType type) {
     switch (type) {
       case WorkoutType.run:
       case WorkoutType.treadmill: // Use same icon for treadmill?
         return Icons.directions_run;
       case WorkoutType.walk:
         return Icons.directions_walk;
       case WorkoutType.cycle:
         return Icons.directions_bike;
       default:
         return Icons.fitness_center; // Default icon
     }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Format the values using FormatUtils
    final String distanceStr = FormatUtils.formatDistance(workout.distance, useImperial);
    final String durationStr = FormatUtils.formatDuration(workout.durationInSeconds);
    final String dateStr = FormatUtils.formatRelativeDate(workout.date); // Use relative date
    final String workoutTypeStr = FormatUtils.formatWorkoutType(workout.workoutType);

    return Card(
       elevation: 1.5,
       // clipBehavior: Clip.antiAlias, // Optional: adds rounded corners to InkWell ripple
       child: InkWell(
          onTap: onTap, // Allow tapping the whole card
          borderRadius: BorderRadius.circular(12.0), // Match Card's default border radius
          child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // --- Top Row: Icon, Type, Date ---
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                            children: [
                               Icon(_getWorkoutIcon(workout.workoutType), size: 20, color: colorScheme.primary),
                               const SizedBox(width: 8),
                               Text(workoutTypeStr, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                         ),
                         Text(dateStr, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                   ),
                   const SizedBox(height: 12),
                   // --- Middle Row: Key Metrics ---
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         _buildMetric(context, 'Distance', distanceStr),
                         _buildMetric(context, 'Duration', durationStr),
                          // Optionally show Pace
                          if (workout.pace != null)
                             _buildMetric(context, 'Avg Pace', FormatUtils.formatPace(workout.pace, useImperial)),
                         // Optionally show Calories
                         // _buildMetric(context, 'Calories', FormatUtils.formatCalories(workout.caloriesBurned)),
                      ],
                   ),
                    // TODO: Add elevation gain/loss if significant?
                    // TODO: Add heart rate data if available?
                ],
             ),
          ),
       ),
    );
  }

  // Helper to build styled metric display
  Widget _buildMetric(BuildContext context, String label, String value) {
     final textTheme = Theme.of(context).textTheme;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Text(label, style: textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
       ],
     );
  }
}