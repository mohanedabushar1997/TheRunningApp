import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart'; // Import latlong2

class ElevationChart extends StatelessWidget {
  final List<RoutePoint> points;

  const ElevationChart({required this.points, super.key});

  List<FlSpot> _prepareChartData(bool useImperial) {
     List<FlSpot> spots = [];
     if (points.length < 2) return spots;

     double cumulativeDistance = 0;
     double? smoothedAltitude;

     for (int i = 0; i < points.length; i++) {
        final p = points[i];
        if (p.altitude == null) continue;

        // --- Simple Smoothing ---
        double currentAltitude = p.altitude!;
        smoothedAltitude ??= currentAltitude; // Initialize
        smoothedAltitude = (0.3 * currentAltitude) + (0.7 * smoothedAltitude); // Exponential smoothing

        // --- Calculate Distance ---
        if (i > 0) {
            final p1 = points[i - 1];
            if (p1.timestamp != p.timestamp) { // Avoid division by zero or weirdness
               final distCalc = const Distance();
               cumulativeDistance += distCalc.as(LengthUnit.Meter, p1.toLatLng(), p.toLatLng());
            }
        }

        // --- Convert Units ---
        double displayDistance = useImperial ? (cumulativeDistance * 0.000621371) : (cumulativeDistance / 1000.0);
        double displayAltitude = useImperial ? (smoothedAltitude * 3.28084) : smoothedAltitude; // Meters to feet

        // --- Filter extreme altitude changes (likely GPS errors) ---
        // if (i > 0 && (displayAltitude - spots.last.y).abs() > 50) { continue; } // Example filter

        spots.add(FlSpot(displayDistance, displayAltitude));
     }
     return spots;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, bool useImperial) {
       final String unit = useImperial ? 'mi' : 'km';
       double interval = max(1.0, (meta.max / 5.0).ceilToDouble());
        if ((value % interval == 0 && value <= meta.max) || value == 0) {
          return SideTitleWidget( axisSide: meta.axisSide, space: 4,
             child: Text('${value.toInt()}$unit', style: const TextStyle(fontSize: 10, color: Colors.grey)), );
       }
       return Container();
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, bool useImperial) {
     final String unit = useImperial ? 'ft' : 'm';
      double range = meta.max - meta.min;
      double interval = max(5.0, (range / 4.0).ceilToDouble()); // Min interval 5m/ft
       if ((value.round() % interval.round() == 0 && value >= meta.min && value <= meta.max) || value == meta.min || value == meta.max) {
         return SideTitleWidget( axisSide: meta.axisSide, space: 4,
            child: Text('${value.round()}$unit', style: const TextStyle(fontSize: 10, color: Colors.grey)), );
      }
      return Container();
  }


  @override
  Widget build(BuildContext context) {
    final bool useImperial = context.watch<SettingsProvider>().useImperialUnits;
    final List<FlSpot> chartData = _prepareChartData(useImperial);

    if (chartData.length < 2) { // Need at least 2 points to draw a line/area
      return const Card(child: Center(heightFactor: 3, child: Text("Not enough elevation data.")));
    }

    final double minElevation = chartData.map((s) => s.y).reduce(min);
    final double maxElevation = chartData.map((s) => s.y).reduce(max);
    double range = max(10.0, (maxElevation - minElevation).abs());
    double minY = (minElevation - range * 0.1).floorToDouble();
    double maxY = (maxElevation + range * 0.1).ceilToDouble();
    final double maxX = chartData.last.x.ceilToDouble();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 8.0),
        child: LineChart(
          LineChartData(
             gridData: FlGridData(
               show: true, drawVerticalLine: true,
               horizontalInterval: max(1.0, range / 4),
               verticalInterval: max(1.0, maxX / 5),
               getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
               getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
             ),
             titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                   showTitles: true, reservedSize: 22, interval: max(1.0, maxX / 5.0),
                   getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, useImperial),
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                   showTitles: true, reservedSize: 40, interval: max(1.0, range / 4.0),
                   getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, useImperial),
                )),
             ),
             borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
             minX: 0, maxX: maxX, minY: minY, maxY: maxY,
             lineBarsData: [
               LineChartBarData(
                 spots: chartData, isCurved: true,
                 gradient: LinearGradient( // Use gradient for visual appeal
                    colors: [Colors.teal.shade300, Colors.cyan.shade300].map((color) => color.withOpacity(0.8)).toList(),
                 ),
                 barWidth: 3, isStrokeCapRound: false, dotData: const FlDotData(show: false),
                 belowBarData: BarAreaData( // Fill area
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade300, Colors.cyan.shade300].map((color) => color.withOpacity(0.2)).toList(),
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                 ),
               ),
             ],
              lineTouchData: LineTouchData( // Tooltip
                  touchTooltipData: LineTouchTooltipData(
                     tooltipBgColor: Colors.black.withOpacity(0.7),
                     getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final elevation = spot.y;
                        final dist = spot.x;
                        final elevStr = FormatUtils.formatElevation(useImperial ? elevation / 3.28084 : elevation); // Convert back to meters if needed for formatElevation
                        final distStr = FormatUtils.formatDistance(useImperial ? dist / 0.000621371 : dist * 1000.0, useImperial);
                        return LineTooltipItem('$elevStr\nat $distStr', const TextStyle(color: Colors.white, fontSize: 10));
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