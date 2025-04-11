import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart'; // Import latlong2

class PaceChart extends StatelessWidget {
  final List<RoutePoint> points;

  const PaceChart({required this.points, super.key});

  List<FlSpot> _prepareChartData(bool useImperial) {
     List<FlSpot> spots = [];
     if (points.length < 2) return spots;

     double cumulativeDistance = 0;
     double distanceInterval = useImperial ? 160.934 : 100.0; // Sample every ~0.1 mile or 100m
     double intervalDistanceAccumulator = 0;
     Duration intervalDurationAccumulator = Duration.zero;
     DateTime? intervalStartTime = points.first.timestamp;

     for (int i = 1; i < points.length; i++) {
        final p1 = points[i - 1];
        final p2 = points[i];
        final timeDelta = p2.timestamp.difference(p1.timestamp);
        // Skip if time delta is zero or negative
        if (timeDelta.inSeconds <= 0) continue;

        final distCalc = const Distance();
        final distDelta = distCalc.as(LengthUnit.Meter, p1.toLatLng(), p2.toLatLng());

        intervalDistanceAccumulator += distDelta;
        intervalDurationAccumulator += timeDelta;
        cumulativeDistance += distDelta;

        // When enough distance accumulates for an interval, calculate average pace for that interval
        if (intervalDistanceAccumulator >= distanceInterval) {
            double intervalPaceSecPerKm = (intervalDurationAccumulator.inSeconds / (intervalDistanceAccumulator / 1000.0));
             double displayPace = intervalPaceSecPerKm;
             if (useImperial) { displayPace /= 1.60934; } // sec/km to sec/mile
              displayPace /= 60.0; // To minutes for Y-axis

            double displayDistance = useImperial ? (cumulativeDistance * 0.000621371) : (cumulativeDistance / 1000.0);

             // Filter out extreme/unrealistic pace values
             if (displayPace < 25 && displayPace > 1) { // Pace between 1 and 25 min/unit
                spots.add(FlSpot(displayDistance, displayPace));
             }

            // Reset for next interval
            intervalDistanceAccumulator = 0;
            intervalDurationAccumulator = Duration.zero;
        }
     }
     // TODO: Consider how to handle the last partial interval
     return spots;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, bool useImperial) {
       final String unit = useImperial ? 'mi' : 'km';
        // Dynamic interval based on total distance (maxX)
        double interval = max(1.0, (meta.max / 5.0).ceilToDouble());
        if ((value % interval == 0 && value <= meta.max) || value == 0) {
           return SideTitleWidget( axisSide: meta.axisSide, space: 4,
              child: Text('${value.toInt()}$unit', style: const TextStyle(fontSize: 10, color: Colors.grey)),
           );
        }
        return Container();
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, bool useImperial) {
     final String unit = useImperial ? '/mi' : '/km';
      // Dynamic interval for pace
      double range = meta.max - meta.min;
      double interval = max(1.0, (range / 4.0).roundToDouble()); // Show ~5 labels
      if ((value % interval == 0 && value >= meta.min && value <= meta.max) || value == meta.min || value == meta.max) {
          return SideTitleWidget( axisSide: meta.axisSide, space: 4,
              child: Text('${value.toInt()}:00$unit', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          );
      }
      return Container();
  }

  @override
  Widget build(BuildContext context) {
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;
    final List<FlSpot> chartData = _prepareChartData(useImperial);

    if (chartData.isEmpty) {
      return const Card(child: Center(heightFactor: 3, child: Text("Not enough data for pace chart.")));
    }

    final double minPace = chartData.map((s) => s.y).reduce(min);
    final double maxPace = chartData.map((s) => s.y).reduce(max);
    // Add padding, ensure min isn't negative, ensure decent range
    final double minY = max(0, (minPace - 1).floorToDouble());
    final double maxY = max(minY + 2, (maxPace + 1).ceilToDouble());
    final double maxX = chartData.last.x.ceilToDouble();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 8.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
               show: true, drawVerticalLine: true,
               horizontalInterval: max(1.0, (maxY - minY) / 4.0), // ~5 horizontal lines
               verticalInterval: max(1.0, maxX / 5.0), // ~6 vertical lines
               getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
               getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
               show: true,
               rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
               topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
               bottomTitles: AxisTitles( sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22, interval: max(1.0, maxX / 5.0),
                  getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, useImperial),
               )),
               leftTitles: AxisTitles( sideTitles: SideTitles(
                  showTitles: true, reservedSize: 42, interval: max(1.0, (maxY-minY) / 4.0),
                  getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, useImperial),
               )),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
            minX: 0, maxX: maxX, minY: minY, maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: chartData, isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
                belowBarData: BarAreaData( show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.1), ),
              ),
            ],
            lineTouchData: LineTouchData( // Tooltip
                touchTooltipData: LineTouchTooltipData(
                   tooltipBgColor: Colors.black.withOpacity(0.7),
                   getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final paceMin = spot.y;
                      final dist = spot.x;
                      final paceStr = FormatUtils.formatPace(paceMin * 60.0, useImperial); // Convert back to sec/unit
                      final distStr = FormatUtils.formatDistance(useImperial ? dist / 0.000621371 : dist * 1000.0, useImperial);
                      return LineTooltipItem('$paceStr\nat $distStr', const TextStyle(color: Colors.white, fontSize: 10));
                   }).toList(),
                ),
             ),
          ),
           duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }
}