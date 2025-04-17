import 'dart:async';
import 'dart:math' as math; // Import full math library with prefix
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'enhanced_battery_service.dart';
import '../../utils/kalman_filter.dart';
// Use prefix for local models to avoid Position conflict
import '../models/enhanced_location_data.dart' as local_models;

/// Enhanced service for location tracking with advanced features
///
/// Provides sophisticated location tracking with Kalman filtering for position smoothing,
/// accuracy filtering, battery optimization, and activity detection.
class EnhancedLocationService {
  // Singleton pattern
  static final EnhancedLocationService _instance =
      EnhancedLocationService._internal();
  factory EnhancedLocationService() => _instance;
  EnhancedLocationService._internal();

  // Core services
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;
  final EnhancedBatteryService _batteryService = EnhancedBatteryService();

  // Streaming
  // Explicitly use geolocator.Position for the stream subscription type
  StreamSubscription<geolocator.Position>? _positionStreamSubscription;
  // Use prefixed type for the StreamController
  final _positionController =
      StreamController<local_models.EnhancedLocationData>.broadcast();

  // Data storage
  // Use prefixed type for the list
  final List<local_models.EnhancedLocationData> _locations = [];
  // Explicitly use geolocator.Position for the list type
  final List<geolocator.Position> _positions =
      []; // Keep for backward compatibility

  // Filter components
  // Assuming LocationKalmanFilter is defined in the imported utils file
  LocationKalmanFilter? _kalmanFilter;

  // Status flags
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isPermissionGranted = false;
  bool _useSmoothing = true;
  bool _useAccuracyFilter = true;
  bool _useBatteryOptimization = true;
  int _accuracyThreshold = 20; // meters

  // Tracking metrics
  double _totalElevationGain = 0;
  double _totalElevationLoss = 0;
  DateTime? _lastLocationTime;
  // Explicitly use geolocator.Position for the variable type
  geolocator.Position? _lastPosition;
  // Use prefixed type for the variable
  local_models.EnhancedLocationData? _lastLocation;
  int _consecutiveBadReadings = 0;
  final int _maxConsecutiveBadReadings = 5;

  // Configuration
  int _distanceFilter = 5; // meters
  LocationAccuracy _locationAccuracy = LocationAccuracy.high;
  Duration _locationInterval = const Duration(seconds: 1);
  Timer? _locationUpdateTimer;

  // Activity detection
  String _currentActivity = "unknown";
  double _currentSpeed = 0.0;
  bool _isMoving = false;
  Timer? _activityDetectionTimer;

  // Getters
  // Use prefixed type for the stream getter
  Stream<local_models.EnhancedLocationData> get locationStream =>
      _positionController.stream;
  // Explicitly use geolocator.Position for the stream type
  Stream<geolocator.Position> get positionStream =>
      locationStream.map((loc) => loc.rawPosition);
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isPermissionGranted => _isPermissionGranted;
  // Explicitly use geolocator.Position for the list type
  List<geolocator.Position> get positions => List.unmodifiable(_positions);
  // Use prefixed type for the list getter
  List<local_models.EnhancedLocationData> get locations =>
      List.unmodifiable(_locations);
  String get currentActivity => _currentActivity;
  bool get isMoving => _isMoving;

  // Feature toggles
  bool get useSmoothing => _useSmoothing;
  bool get useAccuracyFilter => _useAccuracyFilter;
  bool get useBatteryOptimization => _useBatteryOptimization;

  // Metrics
  double get totalElevationGain => _totalElevationGain;
  double get totalElevationLoss => _totalElevationLoss;

  /// Initialize service
  Future<void> initialize() async {
    // Initialize battery service
    await _batteryService.initialize();
  }

  /// Configure settings
  void configure({
    bool? useSmoothing,
    bool? useAccuracyFilter,
    bool? useBatteryOptimization,
    int? accuracyThreshold,
    int? distanceFilter,
    LocationAccuracy? locationAccuracy,
    Duration? locationInterval,
  }) {
    _useSmoothing = useSmoothing ?? _useSmoothing;
    _useAccuracyFilter = useAccuracyFilter ?? _useAccuracyFilter;
    _useBatteryOptimization = useBatteryOptimization ?? _useBatteryOptimization;
    _accuracyThreshold = accuracyThreshold ?? _accuracyThreshold;
    _distanceFilter = distanceFilter ?? _distanceFilter;
    _locationAccuracy = locationAccuracy ?? _locationAccuracy;
    _locationInterval = locationInterval ?? _locationInterval;

    // Update battery service
    _batteryService.setBatteryOptimization(_useBatteryOptimization);
  }

  /// Check if we have the necessary permissions
  Future<bool> checkPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check if app has location permission
    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Also check background location permission for Android
    if (await Permission.locationAlways.isGranted) {
      _isPermissionGranted = true;
      return true;
    }

    // Request background location permission
    final backgroundStatus = await Permission.locationAlways.request();
    _isPermissionGranted = backgroundStatus.isGranted;
    return _isPermissionGranted;
  }

  /// Request location permission explicitly
  Future<bool> requestLocationPermission() async {
    // First request normal location permission
    final locationStatus = await Permission.location.request();

    if (locationStatus.isGranted) {
      // Then request background location
      final backgroundStatus = await Permission.locationAlways.request();
      _isPermissionGranted = backgroundStatus.isGranted;
      return _isPermissionGranted;
    }

    _isPermissionGranted = false;
    return false;
  }

  /// Get current position
  // Explicitly use geolocator.Position for the return type
  Future<geolocator.Position?> getCurrentPosition() async {
    if (!await checkPermissions()) {
      return null;
    }

    try {
      return await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Start tracking location with adaptive parameters
  Future<void> startTracking({int? distanceFilter}) async {
    if (_isTracking && !_isPaused) return;

    if (!await checkPermissions()) {
      throw Exception('Location permissions not granted');
    }

    // Clear previous positions if starting new tracking session
    if (!_isPaused) {
      _positions.clear();
      _locations.clear();
      _totalElevationGain = 0;
      _totalElevationLoss = 0;
      _lastLocationTime = null;
      _lastPosition = null;
      _lastLocation = null;
      _consecutiveBadReadings = 0;
      _kalmanFilter = null; // Reset filter when starting new tracking
      _currentActivity = "unknown";
      _currentSpeed = 0.0;
      _isMoving = false;
    }

    // Cancel any active subscription
    await _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();

    // Apply battery optimization if enabled
    if (_useBatteryOptimization) {
      _updateBatteryOptimizedSettings();
    } else if (distanceFilter != null) {
      _distanceFilter = distanceFilter;
    }

    // Start new tracking
    _positionStreamSubscription = _geolocator
        .getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _locationAccuracy,
        distanceFilter: _distanceFilter,
      ),
    )
        .listen(
      _processRawPosition,
      onError: (error) {
        _positionController.addError(error);
        print('Location stream error: $error');
      },
    );

    // Start periodic updates for battery optimization if enabled
    if (_useBatteryOptimization) {
      _startAdaptiveLocationUpdates();
    }

    // Start activity detection
    _startActivityDetection();

    _isTracking = true;
    _isPaused = false;
  }

  /// Process incoming GPS positions
  // Explicitly use geolocator.Position for the parameter type
  void _processRawPosition(geolocator.Position position) {
    // Add raw position to list for backward compatibility
    _positions.add(position);

    // Update current speed
    _currentSpeed = position.speed;

    // Update movement status
    _isMoving = position.speed > 0.5; // Moving if speed > 0.5 m/s (1.8 km/h)

    // Check accuracy if filtering is enabled
    bool isReliable = true;
    if (_useAccuracyFilter && position.accuracy > _accuracyThreshold) {
      _consecutiveBadReadings++;
      isReliable = false;

      // If we've had too many bad readings in a row, let this one through anyway
      // to avoid completely stopping location updates
      if (_consecutiveBadReadings > _maxConsecutiveBadReadings) {
        isReliable = true;
        _consecutiveBadReadings = 0;
      } else if (_lastLocation != null) {
        // Use the last known good location instead
        // but don't broadcast it again to avoid duplicates
        return;
      }
    } else {
      _consecutiveBadReadings = 0;
    }

    // Apply Kalman filter for position smoothing if enabled
    double filteredLat = position.latitude;
    double filteredLng = position.longitude;
    double filteredAlt = position.altitude;

    if (_useSmoothing) {
      if (_kalmanFilter == null) {
        // Initialize filter with first position
        _kalmanFilter = LocationKalmanFilter(
          initialLat: position.latitude,
          initialLng: position.longitude,
          initialAlt: position.altitude,
        );
      } else {
        // Apply filter to smooth location data
        final filtered = _kalmanFilter!.update(
          position.latitude,
          position.longitude,
          alt: position.altitude,
          accuracy: position.accuracy,
        );

        filteredLat = filtered['latitude']!;
        filteredLng = filtered['longitude']!;
        filteredAlt = filtered['altitude']!;
      }
    }

    // Calculate metrics
    double elevationGain = 0;
    double elevationLoss = 0;
    double distanceFromPrevious = 0;
    double calculatedSpeed = position.speed;

    if (_lastPosition != null) {
      // Calculate distance from previous point
      distanceFromPrevious = calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Calculate elevation change if altitude data is available
      if (_lastPosition!.altitude != 0 && position.altitude != 0) {
        double elevationChange = position.altitude - _lastPosition!.altitude;

        // Only count significant elevation changes (more than 1 meter)
        // to avoid GPS altitude noise
        if (elevationChange > 1) {
          elevationGain = elevationChange;
          _totalElevationGain += elevationGain;
        } else if (elevationChange < -1) {
          elevationLoss = -elevationChange;
          _totalElevationLoss += elevationLoss;
        }
      }

      // Calculate speed if timestamp is available
      if (_lastLocationTime != null && position.timestamp != null) {
        final timeDiff =
            position.timestamp!.difference(_lastLocationTime!).inSeconds;
        if (timeDiff > 0 && distanceFromPrevious > 0) {
          calculatedSpeed = distanceFromPrevious / timeDiff;
        }
      }
    }

    // Create enhanced location data using the prefixed constructor
    final enhancedLocation = local_models.EnhancedLocationData(
      rawPosition: position,
      filteredLatitude: filteredLat,
      filteredLongitude: filteredLng,
      filteredAltitude: filteredAlt,
      isReliable: isReliable,
      elevationGain: elevationGain,
      elevationLoss: elevationLoss,
      distanceFromPrevious: distanceFromPrevious,
      calculatedSpeed: calculatedSpeed,
      batteryLevel: _batteryService.currentBatteryLevel,
      activity: _currentActivity,
    );

    // Add to locations list and broadcast
    _locations.add(enhancedLocation);
    _positionController.add(enhancedLocation);

    // Update tracking variables
    _lastPosition = position;
    _lastLocationTime = position.timestamp;
    _lastLocation = enhancedLocation;
  }

  /// Update settings based on battery level
  void _updateBatteryOptimizedSettings() {
    if (!_useBatteryOptimization) return;

    _distanceFilter = _batteryService.getRecommendedDistanceFilter();
    _locationAccuracy = _batteryService.getRecommendedLocationAccuracy();
    _locationInterval = _batteryService.getRecommendedSamplingInterval();

    // If already tracking, update the stream settings
    if (_isTracking && !_isPaused && _positionStreamSubscription != null) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = _geolocator
          .getPositionStream(
        locationSettings: LocationSettings(
          accuracy: _locationAccuracy,
          distanceFilter: _distanceFilter,
        ),
      )
          .listen(
        _processRawPosition,
        onError: (error) {
          _positionController.addError(error);
          print('Location stream error: $error');
        },
      );
    }

    // Log the current settings
    print('Battery optimization settings updated:');
    print('- Battery level: ${_batteryService.currentBatteryLevel}%');
    print('- Distance filter: $_distanceFilter meters');
    print('- Location accuracy: ${_locationAccuracy.name}');
    print('- Sampling interval: ${_locationInterval.inSeconds} seconds');

    // If battery is critically low, suggest pausing tracking
    if (_batteryService.currentBatteryLevel < 10 &&
        !_batteryService.isCharging) {
      print(
          'WARNING: Battery level critically low. Consider pausing tracking.');
    }
  }

  /// Start periodic updates to adjust tracking parameters based on battery level
  void _startAdaptiveLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _updateBatteryOptimizedSettings();
    });

    // Also listen to battery level changes to adjust on significant changes
    _batteryService.batteryLevelStream.listen((level) {
      if (isTracking && !isPaused) {
        _updateBatteryOptimizedSettings();
      }
    });
  }

  /// Start activity detection based on movement patterns
  void _startActivityDetection() {
    _activityDetectionTimer?.cancel();
    _activityDetectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _detectActivity();
    });
  }

  /// Detect user activity based on speed and movement patterns
  void _detectActivity() {
    if (!_isTracking || _isPaused || _locations.isEmpty) return;

    // Get recent locations for analysis
    final recentLocations = _locations.length > 10
        ? _locations.sublist(_locations.length - 10)
        : _locations;

    // Calculate average speed
    double avgSpeed = 0;
    for (final loc in recentLocations) {
      avgSpeed += loc.calculatedSpeed;
    }
    avgSpeed /= recentLocations.length;

    // Determine activity based on speed
    if (avgSpeed < 0.5) {
      // < 1.8 km/h
      _currentActivity = "stationary";
    } else if (avgSpeed < 2.0) {
      // < 7.2 km/h
      _currentActivity = "walking";
    } else if (avgSpeed < 3.0) {
      // < 10.8 km/h
      _currentActivity = "jogging";
    } else {
      _currentActivity = "running";
    }

    // Adjust tracking parameters based on activity
    if (_useBatteryOptimization) {
      if (_currentActivity == "stationary" && _distanceFilter < 10) {
        // If stationary, increase distance filter to reduce updates
        _distanceFilter = 10;
        _updateTrackingParameters();
      } else if (_currentActivity != "stationary" && _distanceFilter > 5) {
        // If moving, decrease distance filter for better tracking
        _distanceFilter = 5;
        _updateTrackingParameters();
      }
    }
  }

  /// Update tracking parameters while tracking is active
  void _updateTrackingParameters() {
    if (_isTracking && !_isPaused && _positionStreamSubscription != null) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = _geolocator
          .getPositionStream(
        locationSettings: LocationSettings(
          accuracy: _locationAccuracy,
          distanceFilter: _distanceFilter,
        ),
      )
          .listen(
        _processRawPosition,
        onError: (error) {
          _positionController.addError(error);
          print('Location stream error: $error');
        },
      );
    }
  }

  /// Pause location tracking
  Future<void> pauseTracking() async {
    if (!_isTracking || _isPaused) return;

    _positionStreamSubscription?.pause();
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();
    _isPaused = true;
  }

  /// Resume location tracking
  Future<void> resumeTracking() async {
    if (!_isTracking || !_isPaused) return;

    _positionStreamSubscription?.resume();

    // Restart timers
    if (_useBatteryOptimization) {
      _startAdaptiveLocationUpdates();
    }
    _startActivityDetection();

    _isPaused = false;
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();
    _isTracking = false;
    _isPaused = false;
  }

  /// Calculate distance between two points using the Haversine formula
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    // Use math prefix for static math functions
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper methods for the Haversine formula
  double _toRadians(double degrees) => degrees * (math.pi / 180);
  double _sin(double radians) => math.sin(radians); // Use math.sin
  double _cos(double radians) => math.cos(radians); // Use math.cos
  double _sqrt(double value) => math.sqrt(value); // Use math.sqrt
  double _atan2(double y, double x) => math.atan2(y, x); // Use math.atan2

  // Removed the redundant safe math wrappers

  /// Dispose of resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();
    _positionController.close();
  }
}
