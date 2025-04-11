import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/location_data.dart';

/// A service for handling location-related functionality
class LocationService {
  // Controllers for location streams
  final _locationStreamController = StreamController<LocationData>.broadcast();

  // Stream getters
  Stream<LocationData> get locationStream => _locationStreamController.stream;

  // Tracking state
  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isPermissionGranted = false;
  Timer? _mockLocationTimer;

  // Mock data - for demo purposes only
  LocationData? _lastLocation;
  final List<LocationData> _mockRoute = [];
  final double _mockStartLat = 37.7749; // Example: San Francisco
  final double _mockStartLng = -122.4194;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking && !_isPaused;
  bool get isPaused => _isPaused;
  bool get isPermissionGranted => _isPermissionGranted;

  /// Initialize the location service and request permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request location permission
    final status = await Permission.location.request();
    _isPermissionGranted = status.isGranted;

    // Generate some initial mock route points
    _generateMockRoute();

    _isInitialized = true;
  }

  /// Start location tracking
  Future<bool> startTracking() async {
    if (!_isPermissionGranted) {
      throw Exception('Location permission not granted');
    }

    if (_isTracking) return true;

    try {
      // In a real app, you would start the location service here
      // For this demo, we'll use a mock location service
      _startMockLocationUpdates();

      _isTracking = true;
      _isPaused = false;
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Pause location tracking
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    _mockLocationTimer?.cancel();
    _isPaused = true;
  }

  /// Resume location tracking
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;

    _startMockLocationUpdates();
    _isPaused = false;
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _mockLocationTimer?.cancel();
    _isTracking = false;
    _isPaused = false;
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return LocationData.calculateDistance(lat1, lng1, lat2, lng2);
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _mockLocationTimer?.cancel();
    _locationStreamController.close();
  }

  // MOCK IMPLEMENTATION - For demo purposes only
  // In a real app, you would use a real location service like geolocator

  /// Start mock location updates for demonstration
  void _startMockLocationUpdates() {
    _mockLocationTimer?.cancel();

    int currentIndex = 0;

    _mockLocationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentIndex < _mockRoute.length) {
        final location = _mockRoute[currentIndex];
        _lastLocation = location;
        _locationStreamController.add(location);
        currentIndex++;
      } else {
        // If we reach the end of the predefined route, add some random movement
        if (_lastLocation != null) {
          final newLocation = _getNextRandomLocation(_lastLocation!);
          _lastLocation = newLocation;
          _locationStreamController.add(newLocation);
        }
      }
    });
  }

  /// Generate a mock route for demonstration
  void _generateMockRoute() {
    // Clear any existing mock route
    _mockRoute.clear();

    // Starting point
    double lat = _mockStartLat;
    double lng = _mockStartLng;

    // Create a series of points that form a route
    for (int i = 0; i < 60; i++) {
      // Add some randomness to the path
      final latChange = (math.Random().nextDouble() - 0.5) * 0.0005;
      final lngChange =
          (math.Random().nextDouble() - 0.3) * 0.0008; // Tendency to move right

      lat += latChange;
      lng += lngChange;

      final speed = 2.0 + math.Random().nextDouble() * 3.0; // 2-5 m/s

      _mockRoute.add(
        LocationData(
          latitude: lat,
          longitude: lng,
          altitude: 10 + math.Random().nextDouble() * 5,
          speed: speed,
          accuracy: 3.0 + math.Random().nextDouble() * 2.0,
          timestamp: DateTime.now().add(Duration(seconds: i)),
        ),
      );
    }
  }

  /// Generate the next random location based on the last one
  LocationData _getNextRandomLocation(LocationData lastLocation) {
    // Add some randomness to the path
    final latChange = (math.Random().nextDouble() - 0.5) * 0.0003;
    final lngChange =
        (math.Random().nextDouble() - 0.3) * 0.0005; // Tendency to move right

    final newLat = lastLocation.latitude + latChange;
    final newLng = lastLocation.longitude + lngChange;

    final speed = 2.0 + math.Random().nextDouble() * 3.0; // 2-5 m/s

    return LocationData(
      latitude: newLat,
      longitude: newLng,
      altitude:
          lastLocation.altitude != null
              ? lastLocation.altitude! +
                  (math.Random().nextDouble() - 0.5) * 0.5
              : 10.0,
      speed: speed,
      accuracy: 3.0 + math.Random().nextDouble() * 2.0,
      timestamp: DateTime.now(),
    );
  }
}
