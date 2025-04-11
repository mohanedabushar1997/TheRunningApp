import 'package:flutter/material.dart';

import '../../../../data/models/workout.dart';

/// A widget that displays detailed workout metrics during an active workout
/// Shows various metrics in a grid layout with current values
class WorkoutMetricsPanel extends StatelessWidget {
  final Workout workout;
  final bool useImperial;

  const WorkoutMetricsPanel({
    Key? key,
    required this.workout,
    required this.useImperial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Metrics',
              style: theme.textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16.0),
            
            // Metrics grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2.0,
              children: [
                // Distance
                _buildMetricItem(
                  context,
                  'Distance',
                  _formatDistance(workout.distance, useImperial),
                  Icons.straighten,
                ),
                
                // Duration
                _buildMetricItem(
                  context,
                  'Duration',
                  _formatDuration(workout.duration),
                  Icons.timer,
                ),
                
                // Pace
                _buildMetricItem(
                  context,
                  'Current Pace',
                  _formatPace(workout.pace, useImperial),
                  Icons.speed,
                ),
                
                // Calories
                _buildMetricItem(
                  context,
                  'Calories',
                  '${workout.caloriesBurned} kcal',
                  Icons.local_fire_department,
                ),
                
                // Heart rate (if available)
                if (workout.heartRate != null)
                  _buildMetricItem(
                    context,
                    'Heart Rate',
                    '${workout.heartRate} bpm',
                    Icons.favorite,
                    Colors.red,
                  ),
                
                // Cadence (if available)
                if (workout.cadence != null)
                  _buildMetricItem(
                    context,
                    'Cadence',
                    '${workout.cadence} spm',
                    Icons.directions_run,
                  ),
                
                // Current elevation (if available)
                if (workout.routePoints.isNotEmpty && 
                    workout.routePoints.last.elevation != null)
                  _buildMetricItem(
                    context,
                    'Elevation',
                    _formatElevation(
                      workout.routePoints.last.elevation!,
                      useImperial,
                    ),
                    Icons.terrain,
                  ),
                
                // Elevation gain (if available)
                if (workout.elevationGain != null)
                  _buildMetricItem(
                    context,
                    'Elevation Gain',
                    _formatElevation(workout.elevationGain!, useImperial),
                    Icons.trending_up,
                    Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a metric item with label, value, and icon
  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Metric icon
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? theme.primaryColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12.0),
          
          // Metric label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a duration in seconds to a readable string
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  /// Formats a distance in meters to a readable string
  String _formatDistance(double meters, bool useImperial) {
    if (useImperial) {
      // Convert to miles
      final miles = meters / 1609.34;
      return '${miles.toStringAsFixed(2)} mi';
    } else {
      // Use kilometers
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  /// Formats a pace value (seconds per km/mile) to a readable string
  String _formatPace(double secondsPerKm, bool useImperial) {
    if (secondsPerKm <= 0) return '--:--';
    
    // Convert to seconds per mile if using imperial
    final paceSeconds = useImperial ? secondsPerKm * 1.60934 : secondsPerKm;
    
    final minutes = paceSeconds ~/ 60;
    final seconds = (paceSeconds % 60).round();
    
    final unit = useImperial ? '/mi' : '/km';
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} $unit';
  }

  /// Formats an elevation value (meters) to a readable string
  String _formatElevation(double meters, bool useImperial) {
    if (useImperial) {
      // Convert to feet
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)} ft';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }
}
