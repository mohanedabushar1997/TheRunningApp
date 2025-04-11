import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../data/models/workout.dart';

/// A widget that displays a real-time pace chart during a workout
/// Shows pace variations throughout the workout using a line chart
class WorkoutPaceChart extends StatelessWidget {
  final Workout workout;
  final bool useImperial;

  const WorkoutPaceChart({
    Key? key,
    required this.workout,
    required this.useImperial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If no pace data available, show placeholder
    if (workout.paceData == null || workout.paceData!.isEmpty) {
      return _buildEmptyChart(context);
    }

    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pace Chart',
            style: theme.textTheme.titleLarge,
          ),
          
          const SizedBox(height: 16.0),
          
          // Pace stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPaceStat(
                context,
                'Current',
                _formatPace(workout.pace, useImperial),
                theme.primaryColor,
              ),
              _buildPaceStat(
                context,
                'Average',
                _formatPace(workout.pace, useImperial),
                Colors.blue,
              ),
              _buildPaceStat(
                context,
                'Best',
                _formatPace(_calculateBestPace(), useImperial),
                Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 24.0),
          
          // Pace chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 60, // 1 minute intervals for pace
                  verticalInterval: 1,
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Show distance markers at intervals
                        final km = value.toInt();
                        if (km % 2 == 0) {
                          return Text(
                            useImperial ? '${(km * 0.621).toStringAsFixed(1)} mi' : '$km km',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 60, // 1 minute intervals
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Format pace values (seconds per km/mile)
                        return Text(
                          _formatPaceSimple(value.toInt(), useImperial),
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
                minX: 0,
                maxX: _calculateMaxX(),
                minY: _calculateMinY(),
                maxY: _calculateMaxY(),
                lineBarsData: [
                  // Pace line
                  LineChartBarData(
                    spots: _createDataPoints(),
                    isCurved: true,
                    color: theme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  
                  // Average pace line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, workout.pace.toDouble()),
                      FlSpot(_calculateMaxX(), workout.pace.toDouble()),
                    ],
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5], // Dashed line
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final pace = spot.y;
                        final distance = spot.x;
                        return LineTooltipItem(
                          '${useImperial ? (distance * 0.621).toStringAsFixed(2) + ' mi' : distance.toStringAsFixed(2) + ' km'}\n${_formatPace(pace, useImperial)}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a pace stat display
  Widget _buildPaceStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
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
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Creates data points for the pace chart
  List<FlSpot> _createDataPoints() {
    final spots = <FlSpot>[];
    
    // If we have pace data, create accurate pace chart
    if (workout.paceData != null && workout.paceData!.isNotEmpty) {
      final totalDistance = workout.distance;
      final distanceInterval = totalDistance / workout.paceData!.length;
      
      for (int i = 0; i < workout.paceData!.length; i++) {
        final distance = (i * distanceInterval) / 1000; // Convert to km
        final pace = workout.paceData![i].toDouble();
        spots.add(FlSpot(distance, pace));
      }
    } 
    // If we don't have detailed data, just use average pace
    else {
      spots.add(FlSpot(0, workout.pace.toDouble()));
      spots.add(FlSpot(workout.distance / 1000, workout.pace.toDouble()));
    }
    
    return spots;
  }

  /// Calculates the maximum X value for the chart (distance in km)
  double _calculateMaxX() {
    return (workout.distance / 1000).ceilToDouble();
  }

  /// Calculates the minimum Y value for the chart (pace in seconds per km)
  double _calculateMinY() {
    if (workout.paceData == null || workout.paceData!.isEmpty) {
      return (workout.pace * 0.8).floorToDouble();
    }
    
    final minPace = workout.paceData!.reduce((a, b) => a < b ? a : b);
    return (minPace * 0.8).floorToDouble();
  }

  /// Calculates the maximum Y value for the chart (pace in seconds per km)
  double _calculateMaxY() {
    if (workout.paceData == null || workout.paceData!.isEmpty) {
      return (workout.pace * 1.2).ceilToDouble();
    }
    
    final maxPace = workout.paceData!.reduce((a, b) => a > b ? a : b);
    return (maxPace * 1.2).ceilToDouble();
  }

  /// Calculates the best (lowest) pace from pace data
  double _calculateBestPace() {
    if (workout.paceData == null || workout.paceData!.isEmpty) {
      return workout.pace;
    }
    
    return workout.paceData!.reduce((a, b) => a < b ? a : b).toDouble();
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

  /// Formats a pace value (seconds per km/mile) to a simple string without units
  String _formatPaceSimple(int secondsPerKm, bool useImperial) {
    if (secondsPerKm <= 0) return '--:--';
    
    // Convert to seconds per mile if using imperial
    final paceSeconds = useImperial ? secondsPerKm * 1.60934 : secondsPerKm;
    
    final minutes = paceSeconds ~/ 60;
    final seconds = (paceSeconds % 60).round();
    
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Builds an empty chart placeholder when no pace data is available
  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pace data available yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pace data will appear as you continue your workout',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
