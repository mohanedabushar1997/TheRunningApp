import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_profile.dart';
import '../data/models/weight_record.dart';
import '../utils/logger.dart';

/// Provider for managing user profile data and preferences
class UserProvider extends ChangeNotifier {
  // Keys for SharedPreferences
  static const String _keyUserProfile = 'user_profile';
  static const String _keyWeightRecords = 'weight_records';
  static const String _keyWeightGoal = 'weight_goal';
  static const String _keyUseImperialUnits = 'use_imperial_units';
  static const String _keyDeviceId = 'device_id';

  // User data
  UserProfile? _userProfile;
  List<WeightRecord> _weightRecords = [];
  double? _weightGoal;
  bool _useImperialUnits = false;
  late String _deviceId;

  // Uuid generator
  final Uuid _uuid = const Uuid();

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<WeightRecord> get weightRecords => _weightRecords;
  double? get weightGoal => _weightGoal;
  bool get useImperialUnits => _useImperialUnits;
  String get deviceId => _deviceId;

  // Derived values
  bool get hasUserProfile => _userProfile != null;

  // Constructor loads user data
  UserProvider() {
    _loadUserData();
  }

  /// Load all user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load or initialize device ID
      _deviceId = prefs.getString(_keyDeviceId) ?? '';
      if (_deviceId.isEmpty) {
        _deviceId = _uuid.v4();
        await prefs.setString(_keyDeviceId, _deviceId);
      }

      // Load user profile
      final userProfileJson = prefs.getString(_keyUserProfile);
      if (userProfileJson != null) {
        final Map<String, dynamic> userProfileMap = jsonDecode(userProfileJson);
        _userProfile = UserProfile.fromMap(userProfileMap);
      }

      // Load weight records
      final weightRecordsJson = prefs.getStringList(_keyWeightRecords) ?? [];
      _weightRecords = weightRecordsJson
          .map((json) => WeightRecord.fromMap(jsonDecode(json)))
          .toList();

      // Sort weight records by date (most recent first)
      _weightRecords.sort((a, b) => b.date.compareTo(a.date));

      // Load weight goal
      _weightGoal = prefs.getDouble(_keyWeightGoal);

      // Load unit preferences
      _useImperialUnits = prefs.getBool(_keyUseImperialUnits) ?? false;

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading user data', e);
    }
  }

  /// Save user profile
  Future<void> setUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userProfile = profile;
      await prefs.setString(_keyUserProfile, jsonEncode(profile.toMap()));
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error saving user profile', e);
    }
  }

  /// Update specific user profile fields
  Future<void> updateUserProfile({
    String? name,
    int? age,
    double? weight,
    double? height,
    Gender? gender,
    FitnessLevel? fitnessLevel,
    WorkoutGoal? workoutGoal,
  }) async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = UserProfile(
        name: name ?? _userProfile!.name,
        age: age ?? _userProfile!.age,
        weight: weight ?? _userProfile!.weight,
        height: height ?? _userProfile!.height,
        gender: gender ?? _userProfile!.gender,
        fitnessLevel: fitnessLevel ?? _userProfile!.fitnessLevel,
        workoutGoal: workoutGoal ?? _userProfile!.workoutGoal,
      );

      await setUserProfile(updatedProfile);

      // If weight was updated, add a weight record
      if (weight != null && weight != _userProfile!.weight) {
        await addWeightRecord(
          weight: weight,
          date: DateTime.now(),
        );
      }
    } catch (e) {
      AppLogger.error('Error updating user profile', e);
    }
  }

  /// Add a weight record
  Future<void> addWeightRecord({
    required double weight,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create the record
      final record = WeightRecord(
        id: _uuid.v4(),
        deviceId: _deviceId,
        weight: weight,
        date: date,
        notes: notes,
      );

      // Add to list
      _weightRecords.add(record);

      // Sort by date (most recent first)
      _weightRecords.sort((a, b) => b.date.compareTo(a.date));

      // Save to preferences
      final recordJsonList =
          _weightRecords.map((r) => jsonEncode(r.toMap())).toList();
      await prefs.setStringList(_keyWeightRecords, recordJsonList);

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error adding weight record', e);
    }
  }

  /// Delete a weight record
  Future<void> deleteWeightRecord(WeightRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove from list
      _weightRecords.removeWhere((r) => r.id == record.id);

      // Save to preferences
      final recordJsonList =
          _weightRecords.map((r) => jsonEncode(r.toMap())).toList();
      await prefs.setStringList(_keyWeightRecords, recordJsonList);

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error deleting weight record', e);
    }
  }

  /// Set weight goal
  Future<void> setWeightGoal(double? goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _weightGoal = goal;

      if (goal != null) {
        await prefs.setDouble(_keyWeightGoal, goal);
      } else {
        await prefs.remove(_keyWeightGoal);
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error setting weight goal', e);
    }
  }

  /// Set unit preference
  Future<void> setUseImperialUnits(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useImperialUnits = value;
      await prefs.setBool(_keyUseImperialUnits, value);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error setting unit preference', e);
    }
  }

  /// Convert weight to the current unit system (kg or lbs)
  double convertWeightToCurrentUnit(double weightInKg) {
    return _useImperialUnits ? weightInKg * 2.20462 : weightInKg;
  }

  /// Convert weight from the current unit system to kg
  double convertWeightFromCurrentUnit(double weight) {
    return _useImperialUnits ? weight / 2.20462 : weight;
  }

  /// Get weight unit string (kg or lbs)
  String getWeightUnit() {
    return _useImperialUnits ? 'lbs' : 'kg';
  }

  /// Get distance unit string (km or mi)
  String getDistanceUnit() {
    return _useImperialUnits ? 'mi' : 'km';
  }

  /// Convert distance to the current unit system (km or mi)
  double convertDistanceToCurrentUnit(double distanceInKm) {
    return _useImperialUnits ? distanceInKm * 0.621371 : distanceInKm;
  }

  /// Convert distance from the current unit system to km
  double convertDistanceFromCurrentUnit(double distance) {
    return _useImperialUnits ? distance / 0.621371 : distance;
  }

  /// Get BMI category for the current user
  String? getBmiCategory() {
    return _userProfile?.bmiCategory;
  }

  /// Get the latest weight record
  WeightRecord? getLatestWeightRecord() {
    return _weightRecords.isNotEmpty ? _weightRecords.first : null;
  }

  /// Get weight trend (gained, lost, or maintained)
  String getWeightTrend() {
    if (_weightRecords.length < 2) return 'Not enough data';

    final latest = _weightRecords[0].weight;
    final previous = _weightRecords[1].weight;

    if ((latest - previous).abs() < 0.1) return 'Maintained';
    return latest > previous ? 'Gained' : 'Lost';
  }

  /// Get weight change over the last month
  double getMonthlyWeightChange() {
    if (_weightRecords.length < 2) return 0;

    final latest = _weightRecords[0];
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));

    // Find the record closest to a month ago
    WeightRecord? oldestInTimeframe;
    for (final record in _weightRecords.reversed) {
      if (record.date.isAfter(monthAgo)) {
        oldestInTimeframe = record;
      }
    }

    if (oldestInTimeframe == null) return 0;
    return latest.weight - oldestInTimeframe.weight;
  }

  /// Clear all user data (for logout/reset)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserProfile);
      await prefs.remove(_keyWeightRecords);
      await prefs.remove(_keyWeightGoal);

      _userProfile = null;
      _weightRecords = [];
      _weightGoal = null;

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error clearing user data', e);
    }
  }
}
