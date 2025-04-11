import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/workout.dart';

/// A widget that displays a map view of the current workout route
/// Shows the user's current position and the route taken so far
class WorkoutMapView extends StatelessWidget {
  final Workout workout;

  const WorkoutMapView({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert route points to LatLng for the map
    final points = workout.routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    
    // If no route points, show placeholder
    if (points.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No route data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'GPS signal may be weak or unavailable',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    
    // Calculate map bounds to fit all points with padding
    final bounds = LatLngBounds.fromPoints(points);
    
    return Stack(
      children: [
        // Map with route
        FlutterMap(
          options: MapOptions(
            bounds: bounds,
            boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50.0)),
            interactiveFlags: InteractiveFlag.all,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.running.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 4.0,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // Start marker
                Marker(
                  point: points.first,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                // Current position marker
                Marker(
                  point: points.last,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Map controls overlay
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              // Zoom in button
              _buildMapButton(
                context,
                Icons.add,
                () {
                  // TODO: Implement zoom in functionality
                },
              ),
              const SizedBox(height: 8),
              // Zoom out button
              _buildMapButton(
                context,
                Icons.remove,
                () {
                  // TODO: Implement zoom out functionality
                },
              ),
              const SizedBox(height: 8),
              // Center on user button
              _buildMapButton(
                context,
                Icons.my_location,
                () {
                  // TODO: Implement center on user functionality
                },
              ),
            ],
          ),
        ),
        
        // Map stats overlay
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMapStat(
                  context,
                  'Current Pace',
                  _formatPace(workout.pace, false),
                ),
                const SizedBox(height: 4),
                _buildMapStat(
                  context,
                  'Current Altitude',
                  _formatAltitude(
                    workout.routePoints.last.elevation ?? 0,
                    false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a map control button
  Widget _buildMapButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).primaryColor,
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  /// Builds a map stat display
  Widget _buildMapStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Formats a pace value (seconds per km) to a readable string
  String _formatPace(double secondsPerKm, bool useImperial) {
    if (secondsPerKm <= 0) return '--:--';
    
    // Convert to seconds per mile if using imperial
    final paceSeconds = useImperial ? secondsPerKm * 1.60934 : secondsPerKm;
    
    final minutes = paceSeconds ~/ 60;
    final seconds = (paceSeconds % 60).round();
    
    final unit = useImperial ? '/mi' : '/km';
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} $unit';
  }

  /// Formats an altitude value (meters) to a readable string
  String _formatAltitude(double meters, bool useImperial) {
    if (useImperial) {
      // Convert to feet
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)} ft';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }
}
