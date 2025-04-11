import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/location_data.dart';
import '../../utils/logger.dart';
import 'kalman_filter.dart';

/// A service that provides real GPS tracking functionality.
///
/// This implementation uses the geolocator package to access real device GPS,
/// applies a Kalman filter for accuracy, and includes comprehensive error handling.
class RealLocationService {
  // Controllers for location streams
  final _locationStreamController = StreamController<LocationData>.broadcast();
  final _errorStreamController = StreamController<String>.broadcast();
  final _statusStreamController = StreamController<String>.broadcast();

  // Streams for consumers
  Stream<LocationData> get locationStream => _locationStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;

  // Geolocator stream subscription
  StreamSubscription<Position>? _positionStreamSubscription;

  // Status flags
  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isPermissionGranted = false;

  // Location settings
  LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update when moved 5 meters
  );

  // Kalman filter for location data
  KalmanFilter2D? _kalmanFilter;

  // Last known location
  LocationData? _lastLocation;
  List<LocationData> _locationHistory = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking && !_isPaused;
  bool get isPaused => _isPaused;
  bool get isPermissionGranted => _isPermissionGranted;
  List<LocationData> get locationHistory => _locationHistory;

  /// Initialize the location service and request permissions
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Log initialization
      Log.i('Initializing RealLocationService');

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorStreamController.add('Location services are disabled');
        Log.w('Location services are disabled');
        return false;
      }

      // Request location permission
      PermissionStatus status = await Permission.location.request();
      if (status.isDenied) {
        _errorStreamController.add('Location permission denied');
        Log.w('Location permission denied');
        return false;
      }

      if (status.isPermanentlyDenied) {
        _errorStreamController.add(
          'Location permission permanently denied. Please enable in settings.',
        );
        Log.w('Location permission permanently denied');
        return false;
      }

      _isPermissionGranted = status.isGranted;

      // Request background location permission for tracking
      if (_isPermissionGranted) {
        status = await Permission.locationAlways.request();
        if (status.isDenied) {
          _statusStreamController.add(
            'Background location permission denied. Tracking will only work in foreground.',
          );
          Log.w('Background location permission denied');
        }
      }

      // Setup location settings based on platform
      _setupLocationSettings();

      _isInitialized = true;
      Log.i('RealLocationService initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _errorStreamController.add('Failed to initialize location service: $e');
      Log.e('Failed to initialize location service',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Configure location settings based on platform
  void _setupLocationSettings() {
    // Setup the appropriate settings based on the platform
    if (defaultTargetPlatform == TargetPlatform.android) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "FitStride is tracking your location",
          notificationTitle: "Location Tracking",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      _locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }

  /// Start tracking location
  Future<bool> startTracking() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (!_isPermissionGranted) {
        _errorStreamController.add('Location permission not granted');
        Log.w('Cannot start tracking: Location permission not granted');
        return false;
      }

      if (_isTracking) return true;

      Log.i('Starting location tracking');
      _statusStreamController.add('Starting location tracking...');

      // Reset location history
      _locationHistory = [];

      // Get current position first to have an immediate value
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Initialize the Kalman filter with the first position
        _kalmanFilter = KalmanFilter2D(
          processNoise: 0.01,
          measurementNoise: 4.0,
        );

        _processLocationUpdate(position);
      } catch (e) {
        Log.w('Failed to get current position: $e');
        // Continue even if we can't get current position
      }

      // Start listening to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        _processLocationUpdate,
        onError: (e) {
          _errorStreamController.add('Location tracking error: $e');
          Log.e('Error in location stream', error: e);
        },
        onDone: () {
          _statusStreamController.add('Location tracking completed');
          Log.i('Location stream completed');
        },
      );

      _isTracking = true;
      _isPaused = false;
      _statusStreamController.add('Location tracking started');
      Log.i('Location tracking started successfully');
      return true;
    } catch (e, stackTrace) {
      _errorStreamController.add('Failed to start location tracking: $e');
      Log.e('Failed to start location tracking',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Process raw location data from geolocator
  void _processLocationUpdate(Position position) {
    try {
      // If we don't have a Kalman filter yet (edge case), initialize it
      if (_kalmanFilter == null) {
        _kalmanFilter = KalmanFilter2D(
          processNoise: 0.01,
          measurementNoise: 4.0,
        );
      }

      // Apply Kalman filter
      final filteredCoords = _kalmanFilter!.filter(
        position.latitude,
        position.longitude,
        position.accuracy,
        position.timestamp != null
            ? DateTime.now()
                    .difference(DateTime.fromMillisecondsSinceEpoch(
                        position.timestamp!.millisecondsSinceEpoch))
                    .inMilliseconds /
                1000
            : 0.1, // Default dt value if no timestamp
      );

      // Convert Position to our LocationData model
      final locationData = LocationData(
        latitude: filteredCoords['latitude']!,
        longitude: filteredCoords['longitude']!,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Store location
      _lastLocation = locationData;
      _locationHistory.add(locationData);

      // Broadcast location update
      _locationStreamController.add(locationData);
    } catch (e, stackTrace) {
      Log.e('Error processing location update',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Pause location tracking
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    Log.i('Pausing location tracking');
    _positionStreamSubscription?.pause();
    _isPaused = true;
    _statusStreamController.add('Location tracking paused');
  }

  /// Resume location tracking
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;

    Log.i('Resuming location tracking');
    _positionStreamSubscription?.resume();
    _isPaused = false;
    _statusStreamController.add('Location tracking resumed');
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    Log.i('Stopping location tracking');
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _isPaused = false;
    _statusStreamController.add('Location tracking stopped');
  }

  /// Calculate distance between two points in meters
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calculate total distance of tracked route in meters
  double calculateTotalDistance() {
    if (_locationHistory.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < _locationHistory.length - 1; i++) {
      totalDistance += calculateDistance(
        _locationHistory[i].latitude,
        _locationHistory[i].longitude,
        _locationHistory[i + 1].latitude,
        _locationHistory[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Dispose the service and clean up resources
  void dispose() {
    Log.i('Disposing RealLocationService');
    _positionStreamSubscription?.cancel();
    _locationStreamController.close();
    _errorStreamController.close();
    _statusStreamController.close();
  }
}
