import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:running_app/data/models/route_point.dart' as model; // Alias model
import 'package:running_app/utils/logger.dart';
import 'dart:math';

class WorkoutMapView extends StatefulWidget {
  final List<model.RoutePoint> routePoints;
  final bool followUser;
  final MapController? mapController;

  const WorkoutMapView({
    required this.routePoints,
    this.followUser = true,
    this.mapController,
    super.key,
  });

  @override
  State<WorkoutMapView> createState() => _WorkoutMapViewState();
}

class _WorkoutMapViewState extends State<WorkoutMapView> {
  late MapController _internalMapController;
  LatLng? _currentMapCenter;
  double _currentZoom = 16.0; // Maintain current zoom level

  @override
  void initState() {
    super.initState();
    _internalMapController = widget.mapController ?? MapController();
     if (widget.routePoints.isNotEmpty) {
       _currentMapCenter = widget.routePoints.last.toLatLng();
     } else {
        _currentMapCenter = const LatLng(25.3, 55.4); // Default Ajman
     }
  }

  @override
  void didUpdateWidget(covariant WorkoutMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routePoints.isNotEmpty && widget.routePoints != oldWidget.routePoints) {
      final newCenter = widget.routePoints.last.toLatLng();
       // Only update map if following or if it's the first point
      if (widget.followUser || oldWidget.routePoints.isEmpty) {
         _moveMap(newCenter);
      }
       // Update internal center regardless for initial build if needed
       _currentMapCenter = newCenter;
    }
  }

   void _moveMap(LatLng center) {
      if (mounted) {
         // Use current zoom level when moving
         _currentZoom = _internalMapController.camera.zoom;
          _internalMapController.move(center, max(_currentZoom, 15.0)); // Ensure minimum zoom on move
          Log.v("Map moved to follow user: $center");
      }
   }


  @override
  Widget build(BuildContext context) {
    final routeLatLngs = widget.routePoints.map((p) => p.toLatLng()).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return FlutterMap(
      mapController: _internalMapController,
      options: MapOptions(
        initialCenter: _currentMapCenter!,
        initialZoom: _currentZoom,
        minZoom: 10.0, maxZoom: 19.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
        ),
        // Update internal zoom state when user interacts
         onMapEvent: (event) {
            if (event is MapEventMove) {
               _currentMapCenter = event.camera.center; // Track center change
            }
            if (event is MapEventRotate) {
              // Optionally handle rotation state
            }
             _currentZoom = event.camera.zoom; // Update zoom on any event
             // If user gestures, potentially disable follow mode temporarily?
             // if (event.source != MapEventSource.mapController && widget.followUser) { ... }
         },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fitstride.running_app',
           // TODO: Implement Tile caching
        ),
        if (routeLatLngs.length > 1)
          PolylineLayer(
            polylines: [ Polyline( points: routeLatLngs, color: colorScheme.primary, strokeWidth: 5.0, ), ],
          ),
         if (routeLatLngs.isNotEmpty)
            MarkerLayer( markers: [
               // Current Position Marker
               Marker(
                  width: 24.0, height: 24.0, point: routeLatLngs.last,
                  child: Container(
                     decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.blue.shade700,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [ BoxShadow(color: Colors.black38, blurRadius: 4, spreadRadius: 0) ],
                     ),
                  ),
               ),
               // Start Marker (Optional)
               // if (routeLatLngs.length > 1) Marker(...)
            ]),
      ],
    );
  }
}