import 'dart:async';
import 'dart:math' show cos, sqrt, asin, pi, min, max;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/enhanced_battery_service.dart'; // Corrected path
import 'kalman_filter.dart';
import '../../data/models/enhanced_location_data.dart';

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
  StreamSubscription<Position>? _positionStreamSubscription;
  final _positionController =
      StreamController<EnhancedLocationData>.broadcast();

  // Data storage
  final List<EnhancedLocationData> _locations = [];
  final List<Position> _positions = []; // Keep for backward compatibility

  // Filter components
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
  Position? _lastPosition;
  EnhancedLocationData? _lastLocation;
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
  Stream<EnhancedLocationData> get locationStream => _positionController.stream;
  Stream<Position> get positionStream =>
      locationStream.map((loc) => loc.rawPosition);
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isPermissionGranted => _isPermissionGranted;
  List<Position> get positions => List.unmodifiable(_positions);
  List<EnhancedLocationData> get locations => List.unmodifiable(_locations);
  String get currentActivity => _currentActivity;
  bool get isMoving => _isMoving;

  // Feature toggles
  bool get useSmoothing => _useSmoothing;
  bool get useAccuracyFilter => _useAccuracyFilter;
  bool get useBatteryOptimization => _useBatteryOptimization;

  // Metrics
  double get totalElevationGain => _totalElevationGain;
  double get totalElevationLoss => _totalElevationLoss;

  // Initialize service
  Future<void> initialize() async {
    // Initialize battery service
    await _batteryService.initialize();
  }

  // Configure settings
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

  // Check if we have the necessary permissions
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

  // Request location permission explicitly
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

  // Get current position
  Future<Position?> getCurrentPosition() async {
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

  // Start tracking location with adaptive parameters
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

  // Process incoming GPS positions
  void _processRawPosition(Position position) {
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

    // Create enhanced location data
    final enhancedLocation = EnhancedLocationData(
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

  // Update settings based on battery level
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

  // Start periodic updates to adjust tracking parameters based on battery level
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

  // Start activity detection based on movement patterns
  void _startActivityDetection() {
    _activityDetectionTimer?.cancel();
    _activityDetectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _detectActivity();
    });
  }

  // Detect user activity based on speed and movement patterns
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

  // Update tracking parameters while tracking is active
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

  // Pause tracking
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    _positionStreamSubscription?.pause();
    _isPaused = true;
  }

  // Resume tracking
  Future<void> resumeTracking() async {
    if (!_isTracking || !_isPaused) return;

    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.resume();
      _isPaused = false;
    } else {
      await startTracking();
    }
  }

  // Stop tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _isPaused = false;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    // Earth's radius in meters
    const earthRadius = 6371000;
    return 2 * earthRadius * asin(sqrt(a));
  }

  // Calculate enhanced metrics from positions
  WorkoutMetrics calculateMetrics() {
    if (_positions.isEmpty) {
      return WorkoutMetrics.zero();
    }

    // Calculate total distance
    double totalDistance = 0;
    for (int i = 0; i < _positions.length - 1; i++) {
      totalDistance += calculateDistance(
        _positions[i].latitude,
        _positions[i].longitude,
        _positions[i + 1].latitude,
        _positions[i + 1].longitude,
      );
    }

    // Calculate duration
    final Duration duration = _positions.isNotEmpty &&
            _positions.first.timestamp != null &&
            _positions.last.timestamp != null
        ? _positions.last.timestamp!.difference(_positions.first.timestamp!)
        : Duration.zero;

    // Calculate average speed (m/s)
    final double avgSpeed =
        duration.inSeconds > 0 ? totalDistance / duration.inSeconds : 0;

    // Calculate average pace (min/km)
    final double avgPaceSeconds =
        totalDistance > 0 ? (duration.inSeconds / (totalDistance / 1000)) : 0;

    // Calculate calories (basic estimation)
    // Assuming 60 calories per km for a 70kg person
    // Add 0.2 calories per meter of elevation gain
    final int calories =
        (totalDistance / 1000 * 60 + _totalElevationGain * 0.2).round();

    // Calculate battery usage
    final int batteryUsage = _locations.isNotEmpty
        ? _locations.first.batteryLevel - _locations.last.batteryLevel
        : 0;

    return WorkoutMetrics(
      distance: totalDistance,
      duration: duration,
      avgSpeed: avgSpeed,
      avgPace: avgPaceSeconds,
      calories: calories,
      elevationGain: _totalElevationGain,
      elevationLoss: _totalElevationLoss,
      batteryUsage: batteryUsage,
    );
  }

  // Get filtered route points (removing unreliable points)
  List<EnhancedLocationData> getFilteredRoute() {
    if (_locations.isEmpty) return [];

    return _locations.where((loc) => loc.isReliable).toList();
  }

  // Get battery optimization recommendations
  Map<String, String> getBatteryOptimizationTips() {
    return _batteryService.getBatteryOptimizationTips();
  }

  // Get estimated remaining battery life in hours
  double getEstimatedRemainingBatteryLife() {
    return _batteryService.getEstimatedRemainingBatteryLife();
  }

  // Dispose resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _activityDetectionTimer?.cancel();
    _positionController.close();
    _batteryService.dispose();
  }
}

// WorkoutMetrics model
class WorkoutMetrics {
  final double distance; // in meters
  final Duration duration;
  final double avgSpeed; // in m/s
  final double avgPace; // in seconds per km
  final int calories;
  final double elevationGain; // in meters
  final double elevationLoss; // in meters
  final int batteryUsage; // battery percentage used

  const WorkoutMetrics({
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    required this.avgPace,
    required this.calories,
    required this.elevationGain,
    required this.elevationLoss,
    this.batteryUsage = 0,
  });

  // Create empty metrics
  factory WorkoutMetrics.zero() {
    return const WorkoutMetrics(
      distance: 0,
      duration: Duration.zero,
      avgSpeed: 0,
      avgPace: 0,
      calories: 0,
      elevationGain: 0,
      elevationLoss: 0,
      batteryUsage: 0,
    );
  }

  // Format pace as mm:ss
  String get formattedPace {
    final int minutes = (avgPace / 60).floor();
    final int seconds = (avgPace % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Format speed in km/h
  String get formattedSpeed {
    final double speedKmh = avgSpeed * 3.6; // Convert m/s to km/h
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  // Format distance in km
  String get formattedDistance {
    final double distanceKm = distance / 1000;
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  // Format duration as hh:mm:ss
  String get formattedDuration {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    final int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
