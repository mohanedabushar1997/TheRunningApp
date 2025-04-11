import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart'; // To delete workout
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/presentation/widgets/workout_details/workout_metrics_card.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart'; // For potential loading state
// TODO: Import chart widgets when implemented
// import 'package:running_app/presentation/widgets/workout_details/pace_chart.dart';
// import 'package:running_app/presentation/widgets/workout_details/elevation_chart.dart';
import 'package:running_app/utils/logger.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutSummaryScreen({required this.workout, super.key});
  static const routeName = '/workout-summary';

  // Helper to calculate map bounds with padding
  LatLngBounds? _calculateBoundsWithPadding(List<LatLng> points, {double padding = 0.01}) {
    if (points.isEmpty) return null;
    final bounds = LatLngBounds.fromPoints(points);
    // Add padding to avoid route touching edges
    // This is a simple padding, more sophisticated methods exist
    final double latPadding = (bounds.north - bounds.south) * padding;
    final double lngPadding = (bounds.east - bounds.west) * padding;

    // Handle cases where bounds might be invalid (e.g., single point)
     if (latPadding <= 0 || lngPadding <= 0 || lngPadding.isNaN || latPadding.isNaN) {
        // For single point or very small area, use a fixed size bound around the center
        const double defaultPaddingDegrees = 0.005; // Approx 500m
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

  // Helper to build shareable text
  String _buildShareSummary(Workout workout, bool useImperial) {
     final dateStr = FormatUtils.formatDateTime(workout.date, format: 'MMM d, yyyy HH:mm');
     final typeStr = FormatUtils.formatWorkoutType(workout.workoutType);
     final distanceStr = FormatUtils.formatDistance(workout.distance, useImperial);
     final durationStr = FormatUtils.formatDuration(workout.durationInSeconds);
     final paceStr = FormatUtils.formatPace(workout.pace, useImperial);
     final caloriesStr = FormatUtils.formatCalories(workout.caloriesBurned);
     final gainStr = workout.elevationGain != null ? FormatUtils.formatElevation(workout.elevationGain) : 'N/A';

     return """
Check out my recent $typeStr workout! (${dateStr})
Distance: $distanceStr
Duration: $durationStr
Avg Pace: $paceStr
Calories: $caloriesStr
Elevation Gain: $gainStr
Tracked with FitStride! #running #fitness #FitStrideApp
""";
     // TODO: Add link to app store?
  }

  // --- Delete Confirmation ---
   Future<void> _confirmAndDelete(BuildContext context) async {
      bool? confirmDelete = await showDialog<bool>(
         context: context,
         builder: (BuildContext context) => AlertDialog(
           title: const Text('Delete Workout?'),
           content: const Text('This action cannot be undone. Are you sure you want to delete this workout permanently?'),
           actions: <Widget>[
             TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
             TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true)
              ),
           ],
         ),
       );

      if (confirmDelete == true && context.mounted) { // Check context is still valid
         Log.i("User confirmed deletion for workout ID: ${workout.id}");
          try {
              // Call provider to delete (passing device ID implicitly via provider state)
              await context.read<WorkoutProvider>().deleteWorkoutById(workout.id);
               if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Workout deleted successfully.'), backgroundColor: Colors.green),
                  );
                  // Navigate back home after deletion
                  Navigator.of(context).popUntil((route) => route.isFirst);
               }
          } catch (e, s) {
             Log.e("Error deleting workout", error: e, stackTrace: s);
             if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting workout: $e'), backgroundColor: Colors.red),
                 );
             }
          }
      }
   }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final useImperial = settingsProvider.useImperialUnits;
    final textTheme = Theme.of(context).textTheme;

    final List<LatLng> routeLatLngs = workout.routePoints.map((p) => p.toLatLng()).toList();
    final mapController = MapController(); // Controller for map interactions
    final bounds = _calculateBoundsWithPadding(routeLatLngs);

     // Ensure workout data is cleared from provider when leaving summary
     WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WorkoutProvider>().clearActiveWorkout();
     });

    return Scaffold(
      appBar: AppBar(
        title: Text(FormatUtils.formatWorkoutType(workout.workoutType)),
         leading: IconButton(
             icon: const Icon(Icons.done), // Use Done instead of Close/Back
             tooltip: 'Done',
             onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        actions: [
          IconButton( icon: const Icon(Icons.share_outlined), tooltip: 'Share Workout',
            onPressed: () {
               final summary = _buildShareSummary(workout, useImperial);
               Share.share(summary, subject: 'My Recent ${FormatUtils.formatWorkoutType(workout.workoutType)} Workout');
            },
          ),
           IconButton( icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Delete Workout',
             onPressed: () => _confirmAndDelete(context),
           ),
        ],
      ),
      body: ListView( // Use ListView for scrollable content
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Header: Date & Time ---
          Text(
            FormatUtils.formatRelativeDate(workout.date),
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
           Text(
             FormatUtils.formatDateTime(workout.date, format: 'EEEE, h:mm a'), // Include day name and time
             style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
             textAlign: TextAlign.center,
           ),
          const SizedBox(height: 24),

          // --- Metrics Card ---
          WorkoutMetricsCard(
             distance: FormatUtils.formatDistance(workout.distance, useImperial),
             duration: FormatUtils.formatDuration(workout.durationInSeconds),
             avgPace: FormatUtils.formatPace(workout.pace ?? workout.calculatedPaceSecondsPerKm, useImperial), // Use stored pace or calc
             calories: FormatUtils.formatCalories(workout.caloriesBurned),
             elevationGain: FormatUtils.formatElevation(workout.elevationGain),
             elevationLoss: FormatUtils.formatElevation(workout.elevationLoss),
             // TODO: Add Avg Heart Rate metric if available
             // avgHeartRate: workout.avgHeartRate?.toString() ?? '--',
          ),
          const SizedBox(height: 24),

          // --- Map View ---
          if (routeLatLngs.length > 1 && bounds != null) ...[
             _buildSectionHeader(context, 'Route Map'),
             SizedBox(
               height: 350, // Increased height
               child: FlutterMap(
                  mapController: mapController, // Assign controller
                 options: MapOptions(
                   initialCenter: bounds.center, // Start centered on bounds
                   initialZoom: 14.0, // Let fitBounds handle zoom mostly
                   // Use cameraFit instead of initialCameraFit for v6
                   cameraConstraint: CameraConstraint.contain(bounds: bounds), // Ensure bounds visible
                   interactionOptions: const InteractionOptions(
                     flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                   ),
                   // Fit map to bounds on load
                   onMapReady: () {
                      // Need slight delay for controller/bounds to be ready?
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted && bounds != null) {
                            mapController.fitCamera(
                                CameraFit.bounds(
                                    bounds: bounds,
                                    padding: const EdgeInsets.all(40.0), // Padding around route
                                ),
                             );
                          }
                      });
                   },
                 ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                       // TODO: Add option for different tile layers (Satellite, Dark) via SettingsProvider
                      userAgentPackageName: 'com.fitstride.running_app',
                       // Add attribution for OpenStreetMap
                       // RichAttributionWidget(...) or SimpleAttributionWidget(...)
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routeLatLngs,
                          color: Theme.of(context).colorScheme.primary, // Use theme color
                          strokeWidth: 5.0,
                           isDotted: false,
                        ),
                      ],
                    ),
                     MarkerLayer(
                       markers: _buildMapMarkers(context, routeLatLngs),
                    ),
                  ],
               ),
             ),
             const SizedBox(height: 24),
          ] else if (routeLatLngs.isNotEmpty) {
              // Handle case with only one point (no map to show)
              const Text("Workout started but no movement recorded.", textAlign: TextAlign.center),
              const SizedBox(height: 24),
          },

          // --- Charts ---
          // TODO: Implement Pace Chart
          // if (workout.routePoints.length > 1) ...[
          //   _buildSectionHeader(context, 'Pace Over Time'),
          //   SizedBox(
          //      height: 200,
          //      child: PaceChart(points: workout.routePoints, useImperial: useImperial), // Your PaceChart widget
          //   ),
          //   const SizedBox(height: 24),
          // ],

          // TODO: Implement Elevation Chart
          // if (workout.elevationGain != null || workout.elevationLoss != null) ...[
          //    _buildSectionHeader(context, 'Elevation Profile'),
          //    SizedBox(
          //       height: 200,
          //       child: ElevationChart(points: workout.routePoints, useImperial: useImperial), // Your ElevationChart widget
          //    ),
          //    const SizedBox(height: 24),
          // ],

          // TODO: Implement Splits/Intervals breakdown
           // if (workout.intervals.isNotEmpty) ...[
           //   _buildSectionHeader(context, workout.intervals.first.type == IntervalType.work ? 'Splits' : 'Intervals'),
           //   // Build list of interval widgets
           //    ...workout.intervals.map((interval) => IntervalCard(interval: interval, useImperial: useImperial)).toList(),
           //   const SizedBox(height: 24),
           // ],

        ],
      ),
    );
  }

   // Helper to build map markers
   List<Marker> _buildMapMarkers(BuildContext context, List<LatLng> points) {
      if (points.isEmpty) return [];
      return [
          // Start Marker
          Marker(
             width: 35.0, height: 35.0, point: points.first,
             child: Container(
                decoration: BoxDecoration( color: Colors.green.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))] ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18,),
             ),
          ),
          // End Marker (only if more than one point)
          if (points.length > 1)
             Marker(
                width: 35.0, height: 35.0, point: points.last,
                child: Container(
                   decoration: BoxDecoration( color: Colors.red.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))] ),
                   child: const Icon(Icons.sports_score_rounded, color: Colors.white, size: 18,),
                ),
             ),
      ];
   }

  // Helper for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8.0),
       child: Text(
         title,
         style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
       ),
     );
  }
}