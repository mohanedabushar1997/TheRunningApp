import 'package:flutter/material.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;

  const WorkoutCard({ required this.workout, this.onTap, super.key });

   IconData _getWorkoutIcon(WorkoutType type) {
       switch (type) {
         case WorkoutType.run: case WorkoutType.treadmill: return Icons.directions_run;
         case WorkoutType.walk: return Icons.directions_walk;
         case WorkoutType.cycle: return Icons.directions_bike;
       }
   }

  @override
  Widget build(BuildContext context) {
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String distanceStr = FormatUtils.formatDistance(workout.distance, useImperial);
    final String durationStr = FormatUtils.formatDuration(workout.durationInSeconds);
    final String dateStr = FormatUtils.formatDateTime(workout.date, format: 'EEE, MMM d');
    final String timeStr = FormatUtils.formatDateTime(workout.date, format: 'h:mm a');
    final String paceStr = FormatUtils.formatPace(workout.pace ?? workout.calculatedPaceSecondsPerKm, useImperial);


    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Row( children: [
                         Icon(_getWorkoutIcon(workout.workoutType), size: 18, color: colorScheme.secondary),
                         const SizedBox(width: 6),
                         Text(dateStr, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500)), ], ),
                    Text(timeStr, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)), ], ),
               const Divider(height: 16),
               Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   _buildMetric(context, 'Distance', distanceStr),
                   _buildMetric(context, 'Duration', durationStr),
                   _buildMetric(context, 'Avg Pace', paceStr), ], ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildMetric(BuildContext context, String label, String value) {
     return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)), ],
     );
   }
}
(Code continues in the next response due to length)






(Code continues in the next response due to length)



Show thinking
Okay, here is the final batch containing the last prioritized files.

This includes placeholders for the Training Repository, Splits View, common UI widgets, and Music Settings. Remember to implement the logic within the TODO comments.

This completes the code modification process based on your requests.

Final Batch (Last ~6 Files)