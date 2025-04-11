import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/models/workout.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/workout_provider.dart';
import 'widgets/workout_stat_card.dart';
import 'widgets/workout_map_view.dart';
import 'widgets/workout_pace_chart.dart';
import 'widgets/workout_metrics_panel.dart';

/// An enhanced active workout screen that displays detailed stats during a workout
/// Shows real-time metrics, pace chart, elevation profile, and map view
class EnhancedActiveWorkoutScreen extends StatefulWidget {
  const EnhancedActiveWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedActiveWorkoutScreen> createState() => _EnhancedActiveWorkoutScreenState();
}

class _EnhancedActiveWorkoutScreenState extends State<EnhancedActiveWorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentPage = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final useImperial = settingsProvider.useImperialUnits;
    
    // Get current workout data
    final isWorkoutActive = workoutProvider.isWorkoutActive;
    final currentWorkout = workoutProvider.currentWorkout;
    
    if (!isWorkoutActive || currentWorkout == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Workout'),
        ),
        body: const Center(
          child: Text('No active workout'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Workout'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show workout settings dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top stats bar
          _buildTopStatsBar(context, currentWorkout, useImperial),
          
          // Tab bar for different views
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Stats'),
              Tab(text: 'Map'),
              Tab(text: 'Pace'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Stats view
                _buildStatsView(context, currentWorkout, useImperial),
                
                // Map view
                WorkoutMapView(workout: currentWorkout),
                
                // Pace view
                WorkoutPaceChart(workout: currentWorkout, useImperial: useImperial),
              ],
            ),
          ),
          
          // Bottom control bar
          _buildControlBar(context, workoutProvider),
        ],
      ),
    );
  }

  /// Builds the top stats bar showing key metrics
  Widget _buildTopStatsBar(BuildContext context, Workout workout, bool useImperial) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Duration
          WorkoutStatCard(
            label: 'Time',
            value: _formatDuration(workout.duration),
            icon: Icons.timer,
          ),
          
          // Distance
          WorkoutStatCard(
            label: 'Distance',
            value: _formatDistance(workout.distance, useImperial),
            icon: Icons.straighten,
          ),
          
          // Pace
          WorkoutStatCard(
            label: 'Pace',
            value: _formatPace(workout.pace, useImperial),
            icon: Icons.speed,
          ),
        ],
      ),
    );
  }

  /// Builds the stats view with detailed metrics
  Widget _buildStatsView(BuildContext context, Workout workout, bool useImperial) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current metrics panel
          WorkoutMetricsPanel(
            workout: workout,
            useImperial: useImperial,
          ),
          
          const SizedBox(height: 24.0),
          
          // Interval information (if applicable)
          if (workout.type == WorkoutType.interval)
            _buildIntervalInfo(context, workout),
          
          const SizedBox(height: 24.0),
          
          // Heart rate chart (if available)
          if (workout.heartRateData != null && workout.heartRateData!.isNotEmpty)
            _buildHeartRateChart(context, workout),
          
          const SizedBox(height: 24.0),
          
          // Elevation profile (if available)
          if (workout.routePoints.any((point) => point.elevation != null))
            _buildElevationProfile(context, workout, useImperial),
          
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  /// Builds interval information for interval workouts
  Widget _buildIntervalInfo(BuildContext context, Workout workout) {
    final theme = Theme.of(context);
    
    // TODO: Replace with actual interval data from workout
    final currentInterval = 'Running';
    final nextInterval = 'Recovery';
    final timeLeft = 45; // seconds
    
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
              'Interval Workout',
              style: theme.textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16.0),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        currentInterval,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        nextInterval,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Left',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$timeLeft sec',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Progress bar
            LinearProgressIndicator(
              value: 1 - (timeLeft / 60), // Example: 60 second interval
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              borderRadius: BorderRadius.circular(4.0),
              minHeight: 8.0,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a heart rate chart
  Widget _buildHeartRateChart(BuildContext context, Workout workout) {
    final theme = Theme.of(context);
    
    // Sample heart rate data (replace with actual data)
    final heartRateData = workout.heartRateData ?? [70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heart Rate',
          style: theme.textTheme.titleLarge,
        ),
        
        const SizedBox(height: 8.0),
        
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minY: (heartRateData.reduce((a, b) => a < b ? a : b) - 10).toDouble(),
              maxY: (heartRateData.reduce((a, b) => a > b ? a : b) + 10).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    heartRateData.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      heartRateData[index].toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Heart rate zones
        const SizedBox(height: 8.0),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeartRateZone(context, 'Easy', Colors.green),
            _buildHeartRateZone(context, 'Fat Burn', Colors.blue),
            _buildHeartRateZone(context, 'Cardio', Colors.orange),
            _buildHeartRateZone(context, 'Peak', Colors.red),
          ],
        ),
      ],
    );
  }

  /// Builds a heart rate zone indicator
  Widget _buildHeartRateZone(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Builds an elevation profile chart
  Widget _buildElevationProfile(BuildContext context, Workout workout, bool useImperial) {
    final theme = Theme.of(context);
    
    // Filter route points that have elevation data
    final pointsWithElevation = workout.routePoints
        .where((point) => point.elevation != null)
        .toList();
    
    if (pointsWithElevation.isEmpty) {
      return Container();
    }
    
    // Extract elevation data
    final elevationData = pointsWithElevation
        .map((point) => point.elevation!)
        .toList();
    
    // Convert to imperial if needed
    final displayElevation = useImperial
        ? elevationData.map((e) => e * 3.28084).toList()
        : elevationData;
    
    // Calculate min and max elevation
    final minElevation = displayElevation.reduce((a, b) => a < b ? a : b);
    final maxElevation = displayElevation.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elevation Profile',
          style: theme.textTheme.titleLarge,
        ),
        
        const SizedBox(height: 8.0),
        
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: useImperial ? 50 : 20,
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: useImperial ? 50 : 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minY: (minElevation - (useImperial ? 20 : 5)).toDouble(),
              maxY: (maxElevation + (useImperial ? 20 : 5)).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    displayElevation.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      displayElevation[index].toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.brown,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.brown.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8.0),
        
        // Elevation stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildElevationStat(
              context,
              'Current',
              '${displayElevation.last.toInt()} ${useImperial ? 'ft' : 'm'}',
            ),
            _buildElevationStat(
              context,
              'Gain',
              '+${_calculateElevationGain(elevationData).toInt()} ${useImperial ? 'ft' : 'm'}',
              Colors.green,
            ),
            _buildElevationStat(
              context,
              'Loss',
              '-${_calculateElevationLoss(elevationData).toInt()} ${useImperial ? 'ft' : 'm'}',
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an elevation stat display
  Widget _buildElevationStat(BuildContext context, String label, String value, [Color? valueColor]) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the bottom control bar
  Widget _buildControlBar(BuildContext context, WorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Pause/Resume button
          _buildControlButton(
            context,
            provider.isWorkoutPaused ? Icons.play_arrow : Icons.pause,
            provider.isWorkoutPaused ? 'Resume' : 'Pause',
            () {
              if (provider.isWorkoutPaused) {
                provider.resumeWorkout();
              } else {
                provider.pauseWorkout();
              }
            },
          ),
          
          // Stop button
          _buildControlButton(
            context,
            Icons.stop,
            'Stop',
            () => _showStopWorkoutDialog(context, provider),
            Colors.red,
          ),
          
          // Lock button
          _buildControlButton(
            context,
            Icons.lock_outline,
            'Lock',
            () {
              // TODO: Implement screen lock
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screen locked')),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a control button
  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed, [
    Color? color,
  ]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color ?? Theme.of(context).primaryColor,
          iconSize: 32.0,
        ),
        Text(
          label,
          style: TextStyle(
            color: color ?? Theme.of(context).primaryColor,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  /// Shows a dialog to confirm stopping the workout
  void _showStopWorkoutDialog(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Workout'),
        content: const Text('Are you sure you want to stop this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.stopWorkout();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Stop'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculates total elevation gain from elevation data
  double _calculateElevationGain(List<double> elevationData) {
    double gain = 0;
    for (int i = 1; i < elevationData.length; i++) {
      final diff = elevationData[i] - elevationData[i - 1];
      if (diff > 0) gain += diff;
    }
    return gain;
  }

  /// Calculates total elevation loss from elevation data
  double _calculateElevationLoss(List<double> elevationData) {
    double loss = 0;
    for (int i = 1; i < elevationData.length; i++) {
      final diff = elevationData[i - 1] - elevationData[i];
      if (diff > 0) loss += diff;
    }
    return loss;
  }
}
