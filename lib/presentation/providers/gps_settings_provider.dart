import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../device/gps/location_service.dart';

class GpsSettingsProvider with ChangeNotifier {
  // Location service singleton
  final LocationService _locationService;

  // Settings keys
  static const String _useGpsSmoothing = 'use_gps_smoothing';
  static const String _useAccuracyFilter = 'use_accuracy_filter';
  static const String _useBatteryOptimization = 'use_battery_optimization';
  static const String _accuracyThreshold = 'accuracy_threshold';
  static const String _distanceFilter = 'distance_filter';

  // Default values
  bool _useSmoothing = true;
  bool _useAccuracyFiltering = true;
  bool _useBatteryOptimizing = true;
  int _gpsAccuracyThreshold = 20; // in meters
  int _gpsDistanceFilter = 5; // in meters

  // Constructor
  GpsSettingsProvider({required LocationService locationService})
    : _locationService = locationService {
    _loadSettings();
  }

  // Getters
  bool get useSmoothing => _useSmoothing;
  bool get useAccuracyFiltering => _useAccuracyFiltering;
  bool get useBatteryOptimizing => _useBatteryOptimizing;
  int get gpsAccuracyThreshold => _gpsAccuracyThreshold;
  int get gpsDistanceFilter => _gpsDistanceFilter;

  // Setters
  Future<void> setUseSmoothing(bool value) async {
    if (_useSmoothing == value) return;
    _useSmoothing = value;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  Future<void> setUseAccuracyFiltering(bool value) async {
    if (_useAccuracyFiltering == value) return;
    _useAccuracyFiltering = value;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  Future<void> setUseBatteryOptimizing(bool value) async {
    if (_useBatteryOptimizing == value) return;
    _useBatteryOptimizing = value;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  Future<void> setGpsAccuracyThreshold(int value) async {
    if (_gpsAccuracyThreshold == value) return;
    _gpsAccuracyThreshold = value;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  Future<void> setGpsDistanceFilter(int value) async {
    if (_gpsDistanceFilter == value) return;
    _gpsDistanceFilter = value;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _useSmoothing = true;
    _useAccuracyFiltering = true;
    _useBatteryOptimizing = true;
    _gpsAccuracyThreshold = 20;
    _gpsDistanceFilter = 5;
    await _saveSettings();
    _updateLocationService();
    notifyListeners();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _useSmoothing = prefs.getBool(_useGpsSmoothing) ?? true;
      _useAccuracyFiltering = prefs.getBool(_useAccuracyFilter) ?? true;
      _useBatteryOptimizing = prefs.getBool(_useBatteryOptimization) ?? true;
      _gpsAccuracyThreshold = prefs.getInt(_accuracyThreshold) ?? 20;
      _gpsDistanceFilter = prefs.getInt(_distanceFilter) ?? 5;

      _updateLocationService();
      notifyListeners();
    } catch (e) {
      print('Error loading GPS settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_useGpsSmoothing, _useSmoothing);
      await prefs.setBool(_useAccuracyFilter, _useAccuracyFiltering);
      await prefs.setBool(_useBatteryOptimization, _useBatteryOptimizing);
      await prefs.setInt(_accuracyThreshold, _gpsAccuracyThreshold);
      await prefs.setInt(_distanceFilter, _gpsDistanceFilter);
    } catch (e) {
      print('Error saving GPS settings: $e');
    }
  }

  // Update location service with current settings
  void _updateLocationService() {
    _locationService.configure(
      useSmoothing: _useSmoothing,
      useAccuracyFilter: _useAccuracyFiltering,
      useBatteryOptimization: _useBatteryOptimizing,
      accuracyThreshold: _gpsAccuracyThreshold,
      distanceFilter: _gpsDistanceFilter,
    );
  }
}
