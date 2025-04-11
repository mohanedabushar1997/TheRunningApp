import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../device/gps/real_location_service.dart';
import '../utils/logger.dart';

/// Provider for GPS and location settings
///
/// This provider manages user preferences for GPS accuracy,
/// location update frequency, and other location-related settings.
class GpsSettingsProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const String _keyGpsAccuracy = 'gps_accuracy';
  static const String _keyLocationUpdateInterval = 'location_update_interval';
  static const String _keyEnableGpsFiltering = 'enable_gps_filtering';
  static const String _keyGpsFilterStrength = 'gps_filter_strength';
  static const String _keyAutoResumeTracking = 'auto_resume_tracking';
  static const String _keyMinDistanceFilter = 'min_distance_filter';
  static const String _keyEnableBackgroundMode = 'enable_background_mode';
  static const String _keyShowGpsOnMap = 'show_gps_on_map';
  static const String _keyUseMockLocationInDebug = 'use_mock_location_in_debug';

  // Default values
  static const String defaultGpsAccuracy = 'high';
  static const int defaultLocationUpdateInterval = 1000; // 1 second
  static const bool defaultEnableGpsFiltering = true;
  static const double defaultGpsFilterStrength = 0.5; // Medium (0.0-1.0)
  static const bool defaultAutoResumeTracking = true;
  static const int defaultMinDistanceFilter = 3; // meters
  static const bool defaultEnableBackgroundMode = true;
  static const bool defaultShowGpsOnMap = true;
  static const bool defaultUseMockLocationInDebug = false;

  // Settings
  String _gpsAccuracy = defaultGpsAccuracy;
  int _locationUpdateInterval = defaultLocationUpdateInterval;
  bool _enableGpsFiltering = defaultEnableGpsFiltering;
  double _gpsFilterStrength = defaultGpsFilterStrength;
  bool _autoResumeTracking = defaultAutoResumeTracking;
  int _minDistanceFilter = defaultMinDistanceFilter;
  bool _enableBackgroundMode = defaultEnableBackgroundMode;
  bool _showGpsOnMap = defaultShowGpsOnMap;
  bool _useMockLocationInDebug = defaultUseMockLocationInDebug;

  // Location service instance
  RealLocationService? _locationService;

  // Getters
  String get gpsAccuracy => _gpsAccuracy;
  int get locationUpdateInterval => _locationUpdateInterval;
  bool get enableGpsFiltering => _enableGpsFiltering;
  double get gpsFilterStrength => _gpsFilterStrength;
  bool get autoResumeTracking => _autoResumeTracking;
  int get minDistanceFilter => _minDistanceFilter;
  bool get enableBackgroundMode => _enableBackgroundMode;
  bool get showGpsOnMap => _showGpsOnMap;
  bool get useMockLocationInDebug => _useMockLocationInDebug;

  // Get the GPS accuracy value for location services
  LocationAccuracy get gpsAccuracyValue {
    switch (_gpsAccuracy) {
      case 'highest':
        return LocationAccuracy.bestForNavigation;
      case 'high':
        return LocationAccuracy.high;
      case 'medium':
        return LocationAccuracy.medium;
      case 'low':
        return LocationAccuracy.low;
      case 'lowest':
        return LocationAccuracy.reduced;
      default:
        return LocationAccuracy.high;
    }
  }

  // Constructor
  GpsSettingsProvider({RealLocationService? locationService}) {
    _locationService = locationService;
    _loadSettings();
  }

  // Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _gpsAccuracy = prefs.getString(_keyGpsAccuracy) ?? defaultGpsAccuracy;
      _locationUpdateInterval = prefs.getInt(_keyLocationUpdateInterval) ??
          defaultLocationUpdateInterval;
      _enableGpsFiltering =
          prefs.getBool(_keyEnableGpsFiltering) ?? defaultEnableGpsFiltering;
      _gpsFilterStrength =
          prefs.getDouble(_keyGpsFilterStrength) ?? defaultGpsFilterStrength;
      _autoResumeTracking =
          prefs.getBool(_keyAutoResumeTracking) ?? defaultAutoResumeTracking;
      _minDistanceFilter =
          prefs.getInt(_keyMinDistanceFilter) ?? defaultMinDistanceFilter;
      _enableBackgroundMode = prefs.getBool(_keyEnableBackgroundMode) ??
          defaultEnableBackgroundMode;
      _showGpsOnMap = prefs.getBool(_keyShowGpsOnMap) ?? defaultShowGpsOnMap;
      _useMockLocationInDebug = prefs.getBool(_keyUseMockLocationInDebug) ??
          defaultUseMockLocationInDebug;

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load GPS settings', e, stackTrace);
    }
  }

  // Save all settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyGpsAccuracy, _gpsAccuracy);
      await prefs.setInt(_keyLocationUpdateInterval, _locationUpdateInterval);
      await prefs.setBool(_keyEnableGpsFiltering, _enableGpsFiltering);
      await prefs.setDouble(_keyGpsFilterStrength, _gpsFilterStrength);
      await prefs.setBool(_keyAutoResumeTracking, _autoResumeTracking);
      await prefs.setInt(_keyMinDistanceFilter, _minDistanceFilter);
      await prefs.setBool(_keyEnableBackgroundMode, _enableBackgroundMode);
      await prefs.setBool(_keyShowGpsOnMap, _showGpsOnMap);
      await prefs.setBool(_keyUseMockLocationInDebug, _useMockLocationInDebug);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save GPS settings', e, stackTrace);
    }
  }

  // Set the location service instance
  void setLocationService(RealLocationService service) {
    _locationService = service;
  }

  // Get location settings based on current configuration
  LocationSettings getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: gpsAccuracyValue,
        distanceFilter: _minDistanceFilter,
        intervalDuration: Duration(milliseconds: _locationUpdateInterval),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "FitStride is tracking your location",
          notificationTitle: "Location Tracking",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: gpsAccuracyValue,
        activityType: ActivityType.fitness,
        distanceFilter: _minDistanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return LocationSettings(
        accuracy: gpsAccuracyValue,
        distanceFilter: _minDistanceFilter,
      );
    }
  }

  // Set GPS accuracy
  Future<void> setGpsAccuracy(String accuracy) async {
    if (_gpsAccuracy == accuracy) return;

    _gpsAccuracy = accuracy;
    await _saveSettings();
    notifyListeners();
  }

  // Set location update interval (in milliseconds)
  Future<void> setLocationUpdateInterval(int interval) async {
    if (_locationUpdateInterval == interval) return;

    _locationUpdateInterval = interval;
    await _saveSettings();
    notifyListeners();
  }

  // Enable/disable GPS filtering for smoother tracking
  Future<void> setEnableGpsFiltering(bool enable) async {
    if (_enableGpsFiltering == enable) return;

    _enableGpsFiltering = enable;
    await _saveSettings();
    notifyListeners();
  }

  // Set GPS filter strength (0.0-1.0)
  Future<void> setGpsFilterStrength(double strength) async {
    if (_gpsFilterStrength == strength) return;

    _gpsFilterStrength = strength;
    await _saveSettings();
    notifyListeners();
  }

  // Set auto-resume tracking option
  Future<void> setAutoResumeTracking(bool autoResume) async {
    if (_autoResumeTracking == autoResume) return;

    _autoResumeTracking = autoResume;
    await _saveSettings();
    notifyListeners();
  }

  // Set minimum distance filter (in meters)
  Future<void> setMinDistanceFilter(int distance) async {
    if (_minDistanceFilter == distance) return;

    _minDistanceFilter = distance;
    await _saveSettings();
    notifyListeners();
  }

  // Enable/disable background mode
  Future<void> setEnableBackgroundMode(bool enable) async {
    if (_enableBackgroundMode == enable) return;

    _enableBackgroundMode = enable;
    await _saveSettings();
    notifyListeners();
  }

  // Set show GPS indicator on map
  Future<void> setShowGpsOnMap(bool show) async {
    if (_showGpsOnMap == show) return;

    _showGpsOnMap = show;
    await _saveSettings();
    notifyListeners();
  }

  // Enable/disable mock location in debug mode
  Future<void> setUseMockLocationInDebug(bool use) async {
    if (_useMockLocationInDebug == use) return;

    _useMockLocationInDebug = use;
    await _saveSettings();
    notifyListeners();
  }

  // Reset settings to defaults
  Future<void> resetToDefaults() async {
    _gpsAccuracy = defaultGpsAccuracy;
    _locationUpdateInterval = defaultLocationUpdateInterval;
    _enableGpsFiltering = defaultEnableGpsFiltering;
    _gpsFilterStrength = defaultGpsFilterStrength;
    _autoResumeTracking = defaultAutoResumeTracking;
    _minDistanceFilter = defaultMinDistanceFilter;
    _enableBackgroundMode = defaultEnableBackgroundMode;
    _showGpsOnMap = defaultShowGpsOnMap;
    _useMockLocationInDebug = defaultUseMockLocationInDebug;

    await _saveSettings();
    notifyListeners();
  }

  // Check if GPS is available and enabled
  Future<bool> isGpsAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permissions if needed
  Future<bool> requestLocationPermissions() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Request location permission
    PermissionStatus status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return false;
    }

    // Request background location permission if needed
    if (_enableBackgroundMode && status.isGranted) {
      status = await Permission.locationAlways.request();
    }

    return status.isGranted;
  }

  // Get current permission status
  Future<String> getLocationPermissionStatus() async {
    final status = await Permission.location.status;

    if (status.isPermanentlyDenied) {
      return 'permanently_denied';
    } else if (status.isDenied) {
      return 'denied';
    } else if (status.isGranted) {
      final backgroundStatus = await Permission.locationAlways.status;
      if (backgroundStatus.isGranted) {
        return 'background_granted';
      } else {
        return 'foreground_only';
      }
    } else if (status.isLimited) {
      return 'limited';
    } else {
      return 'unknown';
    }
  }
}
