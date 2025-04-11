import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/workout_provider.dart';
import '../data/models/workout.dart';
import '../utils/format_utils.dart';

/// Widget that displays workout metrics during an active workout
///
/// Shows real-time metrics including distance, duration, pace, calories,
/// heart rate, and cadence in a grid layout.
class WorkoutMetricsPanel extends StatelessWidget {
  final Workout workout;
  final bool isMetric;
  final bool showHeartRate;
  final bool showCadence;

  const WorkoutMetricsPanel({
    Key? key,
    required this.workout,
    required this.isMetric,
    this.showHeartRate = true,
    this.showCadence = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.0,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: [
              _buildMetricTile(
                context,
                icon: Icons.straighten,
                label: 'Distance',
                value: FormatUtils.formatDistance(workout.distance, isMetric),
                unit: isMetric ? 'km' : 'mi',
              ),
              _buildMetricTile(
                context,
                icon: Icons.timer,
                label: 'Duration',
                value: FormatUtils.formatDuration(workout.duration),
                unit: '',
              ),
              _buildMetricTile(
                context,
                icon: Icons.speed,
                label: 'Pace',
                value: FormatUtils.formatPace(workout.pace, isMetric),
                unit: isMetric ? '/km' : '/mi',
              ),
              _buildMetricTile(
                context,
                icon: Icons.local_fire_department,
                label: 'Calories',
                value: workout.calories.toString(),
                unit: 'kcal',
              ),
              if (showHeartRate && workout.heartRate > 0)
                _buildMetricTile(
                  context,
                  icon: Icons.favorite,
                  label: 'Heart Rate',
                  value: workout.heartRate.toString(),
                  unit: 'bpm',
                ),
              if (showCadence && workout.cadence > 0)
                _buildMetricTile(
                  context,
                  icon: Icons.directions_walk,
                  label: 'Cadence',
                  value: workout.cadence.toString(),
                  unit: 'spm',
                ),
              if (workout.elevationGain > 0)
                _buildMetricTile(
                  context,
                  icon: Icons.trending_up,
                  label: 'Elevation',
                  value: FormatUtils.formatElevation(workout.elevationGain, isMetric),
                  unit: isMetric ? 'm' : 'ft',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16.0,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4.0),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2.0),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
