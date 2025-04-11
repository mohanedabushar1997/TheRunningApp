import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/presentation/widgets/workout_details/workout_metrics_card.dart';
// TODO: Import chart widgets when implemented
// import 'package:running_app/presentation/widgets/workout_details/pace_chart.dart';
// import 'package:running_app/presentation/widgets/workout_details/elevation_chart.dart';
import 'package:running_app/utils/logger.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailsScreen({required this.workout, super.key});
  static const routeName = '/workout-details'; // Use consistent naming if needed elsewhere

  // --- Helpers (Copied from WorkoutSummaryScreen, ensure consistency) ---
  LatLngBounds? _calculateBoundsWithPadding(List<LatLng> points, {double padding = 0.01}) {
     // ... (same implementation as in WorkoutSummaryScreen) ...
     if (points.isEmpty) return null;
     final bounds = LatLngBounds.fromPoints(points);
     final double latPadding = (bounds.north - bounds.south).abs() * padding;
     final double lngPadding = (bounds.east - bounds.west).abs() * padding;
      if (latPadding <= 1e-6 || lngPadding <= 1e-6 || lngPadding.isNaN || latPadding.isNaN) {
         const double defaultPaddingDegrees = 0.005;
         return LatLngBounds(
           LatLng(bounds.center.latitude - defaultPaddingDegrees, bounds.center.longitude - defaultPaddingDegrees),
           LatLng(bounds.center.latitude + defaultPaddingDegrees, bounds.center.longitude + defaultPaddingDegrees),
         );
      }
     return LatLngBounds(
       LatLng(bounds.south - latPadding, bounds.west - lngPadding),
       LatLng(bounds.north + latPadding, bounds.east + lngPadding),
     );
  }

  String _buildShareSummary(Workout workout, bool useImperial) {
     // ... (same implementation as in WorkoutSummaryScreen) ...
     final dateStr = FormatUtils.formatDateTime(workout.date, format: 'MMM d, yyyy HH:mm');
     final typeStr = FormatUtils.formatWorkoutType(workout.workoutType);
     final distanceStr = FormatUtils.formatDistance(workout.distance, useImperial);
     final durationStr = FormatUtils.formatDuration(workout.durationInSeconds);
     final paceStr = FormatUtils.formatPace(workout.pace ?? workout.calculatedPaceSecondsPerKm, useImperial);
     final caloriesStr = FormatUtils.formatCalories(workout.caloriesBurned);
     final gainStr = FormatUtils.formatElevation(workout.elevationGain);

     return """
Check out my $typeStr workout from $dateStr!
Distance: $distanceStr | Duration: $durationStr
Avg Pace: $paceStr | Calories: $caloriesStr
Elevation Gain: $gainStr
#FitStrideApp #running #fitness
""";
  }

  Future<void> _confirmAndDelete(BuildContext context, Workout workoutToDelete) async {
     // ... (same implementation as in WorkoutSummaryScreen) ...
     bool? confirmDelete = await showDialog<bool>( /* ... AlertDialog ... */ );
      if (confirmDelete == true && context.mounted) {
          Log.i("User confirmed deletion for workout ID: ${workoutToDelete.id}");
           try {
               // Use read as this is a one-off action
               await context.read<WorkoutProvider>().deleteWorkoutById(workoutToDelete.id);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workout deleted.'), backgroundColor: Colors.green),
                   );
                   Navigator.of(context).pop(); // Pop back after deletion
                }
           } catch (e, s) { /* ... Error Handling ... */ }
      }
  }

   List<Marker> _buildMapMarkers(BuildContext context, List<LatLng> points) {
      // ... (same implementation as in WorkoutSummaryScreen) ...
       if (points.isEmpty) return [];
       return [
           Marker( width: 35.0, height: 35.0, point: points.first,
              child: Container( decoration: BoxDecoration( color: Colors.green.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))] ), child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18,), ), ),
           if (points.length > 1)
              Marker( width: 35.0, height: 35.0, point: points.last,
                 child: Container( decoration: BoxDecoration( color: Colors.red.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))] ), child: const Icon(Icons.sports_score_rounded, color: Colors.white, size: 18,), ), ),
       ];
   }

   Widget _buildSectionHeader(BuildContext context, String title) {
      // ... (same implementation as in WorkoutSummaryScreen) ...
       return Padding( padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), child: Text( title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), ), );
   }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final useImperial = settingsProvider.useImperialUnits;
    final textTheme = Theme.of(context).textTheme;

    final List<LatLng> routeLatLngs = workout.routePoints.map((p) => p.toLatLng()).toList();
    final mapController = MapController();
    final bounds = _calculateBoundsWithPadding(routeLatLngs);

    return Scaffold(
      appBar: AppBar(
        title: Text(FormatUtils.formatWorkoutType(workout.workoutType)),
        actions: [
          IconButton( icon: const Icon(Icons.share_outlined), tooltip: 'Share Workout',
            onPressed: () {
               final summary = _buildShareSummary(workout, useImperial);
               Share.share(summary, subject: 'My ${FormatUtils.formatWorkoutType(workout.workoutType)} Workout');
            },
          ),
           IconButton( icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Delete Workout',
             onPressed: () => _confirmAndDelete(context, workout),
           ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // --- Header: Date & Time ---
          Text(
            FormatUtils.formatRelativeDate(workout.date),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), // Slightly smaller than summary
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
           Text(
             FormatUtils.formatDateTime(workout.date, format: 'EEEE, h:mm a'),
             style: textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
             textAlign: TextAlign.center,
           ),
          const SizedBox(height: 16),

          // --- Metrics Card ---
          WorkoutMetricsCard(
             distance: FormatUtils.formatDistance(workout.distance, useImperial),
             duration: FormatUtils.formatDuration(workout.durationInSeconds),
             avgPace: FormatUtils.formatPace(workout.pace ?? workout.calculatedPaceSecondsPerKm, useImperial),
             calories: FormatUtils.formatCalories(workout.caloriesBurned),
             elevationGain: FormatUtils.formatElevation(workout.elevationGain),
             elevationLoss: FormatUtils.formatElevation(workout.elevationLoss),
             // avgHeartRate: workout.avgHeartRate?.toString() ?? '--',
          ),
          const SizedBox(height: 16),

          // --- Map View ---
          if (routeLatLngs.length > 1 && bounds != null) ...[
             _buildSectionHeader(context, 'Map'),
             SizedBox(
               height: 300, // Fixed height for map in details view
               child: FlutterMap(
                  mapController: mapController,
                 options: MapOptions(
                    initialCenter: bounds.center,
                    initialZoom: 14.0,
                    cameraConstraint: CameraConstraint.contain(bounds: bounds),
                    interactionOptions: const InteractionOptions( flags: InteractiveFlag.all & ~InteractiveFlag.rotate, ), // Allow all except rotate
                    onMapReady: () {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted && bounds != null) { mapController.fitCamera( CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40.0))); }
                       });
                    },
                 ),
                  children: [
                    TileLayer( urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.fitstride.running_app', ),
                    PolylineLayer( polylines: [ Polyline( points: routeLatLngs, color: Theme.of(context).colorScheme.primary, strokeWidth: 5.0, ), ], ),
                     MarkerLayer( markers: _buildMapMarkers(context, routeLatLngs), ),
                  ],
               ),
             ),
             const SizedBox(height: 16),
          ],

          // --- Charts ---
          // TODO: Add Pace Chart Widget
          // if (workout.routePoints.length > 1) ...[
          //   _buildSectionHeader(context, 'Pace'),
          //   SizedBox( height: 200, child: PaceChart(points: workout.routePoints, useImperial: useImperial)),
          //   const SizedBox(height: 16),
          // ],

          // TODO: Add Elevation Chart Widget
          // if (workout.elevationGain != null || workout.elevationLoss != null) ...[
          //    _buildSectionHeader(context, 'Elevation'),
          //    SizedBox( height: 200, child: ElevationChart(points: workout.routePoints, useImperial: useImperial)),
          //    const SizedBox(height: 16),
          // ],

           // TODO: Add Heart Rate Chart Widget (if data available)
           // if (workout.hasHeartRateData) ...[
           //   _buildSectionHeader(context, 'Heart Rate'),
           //   SizedBox( height: 200, child: HeartRateChart(points: workout.routePoints)),
           //   const SizedBox(height: 16),
           // ],


          // --- Splits / Intervals ---
           if (workout.intervals.isNotEmpty) ...[
             _buildSectionHeader(context, workout.intervals.first.type == IntervalType.work ? 'Splits' : 'Intervals'),
             // TODO: Create IntervalList Widget or similar
              Column(
                 children: workout.intervals.map((interval) => ListTile(
                    leading: CircleAvatar(child: Text('${workout.intervals.indexOf(interval) + 1}')),
                    title: Text(interval.type.name.toUpperCase()),
                    subtitle: Text('Planned: ${FormatUtils.formatDuration(interval.duration.inSeconds)} / ${FormatUtils.formatDistance(interval.distance ?? 0, useImperial)}'),
                    trailing: Text('Pace: ${FormatUtils.formatPace(interval.actualPace, useImperial)}'),
                 )).toList(),
              ),
             const SizedBox(height: 16),
           ],

            // TODO: Add Personal Bests achieved during this workout?
            // TODO: Add option to manually edit workout details? (Name, Type?)

           const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }
}