import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/location_data.dart';
import '../data/models/workout.dart';
import '../data/repositories/workout_repository.dart';
import '../device/gps/real_location_service.dart';
import '../utils/logger.dart';
import '../utils/workout_calculations.dart';

/// Provider for managing workout state and workout history.
///
/// Handles workout creation, tracking, pausing, resuming, and completing.
/// Also maintains workout history and statistics.
class WorkoutProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const String _keyWorkouts = 'workouts';
  static const String _keyCurrentWorkout = 'current_workout';
  static const String _keyIsWorkoutActive = 'is_workout_active';
  static const String _keyIsWorkoutPaused = 'is_workout_paused';

  // Location service and repository
  final RealLocationService? _locationService;
  final WorkoutRepository? _workoutRepository;

  // Workout data
  Workout? _currentWorkout;
  bool _isWorkoutActive = false;
  bool _isWorkoutPaused = false;
  List<Workout> _workouts = [];
  bool _isInitialized = false;

  // Uuid generator
  final Uuid _uuid = const Uuid();

  // Subscriptions
  StreamSubscription<LocationData>? _locationSubscription;

  // Timer for duration tracking
  Timer? _durationTimer;

  // Location history buffer
  List<LocationData> _locationBuffer = [];

  // Getters
  Workout? get currentWorkout => _currentWorkout;
  bool get isWorkoutActive => _isWorkoutActive;
  bool get isWorkoutPaused => _isWorkoutPaused;
  List<Workout> get workouts => _workouts;
  bool get isInitialized => _isInitialized;

  // Statistics getters
  double get totalDistance => _calculateTotalDistance();
  int get totalWorkouts => _workouts.length;
  int get totalDuration => _calculateTotalDuration();

  // Constructor
  WorkoutProvider({
    RealLocationService? locationService,
    WorkoutRepository? workoutRepository,
  })  : _locationService = locationService,
        _workoutRepository = workoutRepository {
    // Auto-initialize if both dependencies are provided
    if (locationService != null && workoutRepository != null) {
      _internalInitialize();
    }
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _internalInitialize();
    }
    return;
  }

  /// Internal initialization method
  Future<void> _internalInitialize() async {
    try {
      await _loadWorkoutData();
      if (_locationService != null) {
        await _initLocationService();
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize workout provider', e, stackTrace);
    }
  }

  /// Load workout data from SharedPreferences
  Future<void> _loadWorkoutData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load workout history
      final workoutsJsonList = prefs.getStringList(_keyWorkouts) ?? [];
      _workouts = workoutsJsonList
          .map((json) => Workout.fromJson(jsonDecode(json)))
          .toList();

      // Sort workouts by date (most recent first)
      _workouts.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Load current workout if any
      final currentWorkoutJson = prefs.getString(_keyCurrentWorkout);
      if (currentWorkoutJson != null) {
        _currentWorkout = Workout.fromJson(jsonDecode(currentWorkoutJson));
      }

      // Load workout state
      _isWorkoutActive = prefs.getBool(_keyIsWorkoutActive) ?? false;
      _isWorkoutPaused = prefs.getBool(_keyIsWorkoutPaused) ?? false;

      // If a workout was active, resume tracking
      if (_isWorkoutActive && !_isWorkoutPaused && _currentWorkout != null) {
        _resumeWorkoutTracking();
      }

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error loading workout data', e, stackTrace);
    }
  }

  /// Initialize the location service
  Future<void> _initLocationService() async {
    try {
      await _locationService?.initialize();
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing location service', e, stackTrace);
    }
  }

  /// Start a new workout
  Future<void> startWorkout({
    required WorkoutType type,
    String? name,
    String? notes,
  }) async {
    try {
      if (_isWorkoutActive) {
        await stopWorkout();
      }

      // Create a new workout
      final now = DateTime.now();
      final workoutId = _uuid.v4();

      _currentWorkout = Workout(
        id: workoutId,
        name: name ?? _getDefaultWorkoutName(type, now),
        type: type,
        startTime: now,
        duration: 0,
        distance: 0,
        averageSpeed: 0,
        calories: 0,
        locations: [],
        notes: notes,
      );

      // Start location tracking
      await _startLocationTracking();

      // Start duration timer
      _startDurationTimer();

      // Update state
      _isWorkoutActive = true;
      _isWorkoutPaused = false;

      // Save current state
      await _saveCurrentWorkoutState();

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error starting workout', e, stackTrace);
    }
  }

  /// Pause the current workout
  Future<void> pauseWorkout() async {
    if (!_isWorkoutActive || _isWorkoutPaused || _currentWorkout == null)
      return;

    try {
      // Pause location tracking
      _locationService?.pauseTracking();

      // Pause timer
      _durationTimer?.cancel();

      // Update state
      _isWorkoutPaused = true;

      // Save current state
      await _saveCurrentWorkoutState();

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error pausing workout', e, stackTrace);
    }
  }

  /// Resume the current workout
  Future<void> resumeWorkout() async {
    if (!_isWorkoutActive || !_isWorkoutPaused || _currentWorkout == null)
      return;

    try {
      // Resume location tracking
      _locationService?.resumeTracking();

      // Restart timer
      _startDurationTimer();

      // Update state
      _isWorkoutPaused = false;

      // Save current state
      await _saveCurrentWorkoutState();

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error resuming workout', e, stackTrace);
    }
  }

  /// Stop and save the current workout
  Future<Workout?> stopWorkout() async {
    if (!_isWorkoutActive || _currentWorkout == null) return null;

    try {
      // Stop location tracking
      await _locationService?.stopTracking();

      // Cancel timer
      _durationTimer?.cancel();

      // Process any remaining locations in buffer
      _processLocationBuffer();

      // Get final workout with calculations
      final completedWorkout = _getFinalWorkout();

      // Save to history
      _workouts.insert(0, completedWorkout);

      // Clear current workout data
      _currentWorkout = null;
      _isWorkoutActive = false;
      _isWorkoutPaused = false;

      // Save state
      await _saveWorkoutData();

      notifyListeners();

      return completedWorkout;
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping workout', e, stackTrace);
      return null;
    }
  }

  /// Get a workout by ID
  Workout? getWorkoutById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete a workout from history
  Future<void> deleteWorkout(String id) async {
    try {
      _workouts.removeWhere((w) => w.id == id);
      await _saveWorkoutData();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting workout', e, stackTrace);
    }
  }

  /// Update workout notes
  Future<void> updateWorkoutNotes(String id, String notes) async {
    try {
      final index = _workouts.indexWhere((w) => w.id == id);
      if (index >= 0) {
        final workout = _workouts[index];
        _workouts[index] = Workout(
          id: workout.id,
          name: workout.name,
          type: workout.type,
          startTime: workout.startTime,
          duration: workout.duration,
          distance: workout.distance,
          averageSpeed: workout.averageSpeed,
          calories: workout.calories,
          locations: workout.locations,
          notes: notes,
        );

        await _saveWorkoutData();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating workout notes', e, stackTrace);
    }
  }

  /// Get recent workouts, limited by count
  List<Workout> getRecentWorkouts({int count = 5}) {
    if (_workouts.isEmpty) return [];
    return _workouts.take(count).toList();
  }

  /// Get workouts by type
  List<Workout> getWorkoutsByType(WorkoutType type) {
    return _workouts.where((w) => w.type == type).toList();
  }

  /// Get workouts in a date range
  List<Workout> getWorkoutsInDateRange(DateTime start, DateTime end) {
    return _workouts
        .where((w) => w.startTime.isAfter(start) && w.startTime.isBefore(end))
        .toList();
  }

  /// Get workouts by week
  List<Workout> getWorkoutsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return getWorkoutsInDateRange(weekStart, weekEnd);
  }

  /// Get workouts by month
  List<Workout> getWorkoutsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return getWorkoutsInDateRange(start, end);
  }

  /// Get statistics for a time period
  Map<String, dynamic> getStatisticsForPeriod(DateTime start, DateTime end) {
    final workoutsInPeriod = getWorkoutsInDateRange(start, end);

    if (workoutsInPeriod.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalDistance': 0.0,
        'totalDuration': 0,
        'totalCalories': 0,
        'longestWorkout': null,
        'fastestPace': null,
      };
    }

    final totalWorkouts = workoutsInPeriod.length;
    final totalDistance =
        workoutsInPeriod.fold<double>(0, (sum, w) => sum + w.distance);
    final totalDuration =
        workoutsInPeriod.fold<int>(0, (sum, w) => sum + w.duration);
    final totalCalories =
        workoutsInPeriod.fold<int>(0, (sum, w) => sum + w.calories);

    // Find longest workout by duration
    final longestWorkout =
        workoutsInPeriod.reduce((a, b) => a.duration > b.duration ? a : b);

    // Find fastest pace workout (ignoring ones with very short distances)
    final validPaceWorkouts = workoutsInPeriod
        .where((w) => w.distance > 0.5 && w.duration > 0)
        .toList();

    Workout? fastestPaceWorkout;
    if (validPaceWorkouts.isNotEmpty) {
      fastestPaceWorkout = validPaceWorkouts.reduce((a, b) {
        final paceA = a.duration / (a.distance * 60); // min/km
        final paceB = b.duration / (b.distance * 60); // min/km
        return paceA < paceB ? a : b;
      });
    }

    return {
      'totalWorkouts': totalWorkouts,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'longestWorkout': longestWorkout,
      'fastestPace': fastestPaceWorkout,
    };
  }

  /// Calculate the workout streak (consecutive days with workouts)
  int calculateCurrentStreak() {
    if (_workouts.isEmpty) return 0;

    int streak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if there's a workout today first
    bool hadWorkoutToday = _workouts.any((w) {
      final workoutDate =
          DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      return workoutDate.isAtSameMomentAs(today);
    });

    if (!hadWorkoutToday) {
      // Check yesterday instead
      final yesterday = today.subtract(const Duration(days: 1));
      bool hadWorkoutYesterday = _workouts.any((w) {
        final workoutDate =
            DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
        return workoutDate.isAtSameMomentAs(yesterday);
      });

      if (!hadWorkoutYesterday) return 0;

      // Start from yesterday
      streak = 1;

      // Check previous days
      DateTime checkDate = yesterday.subtract(const Duration(days: 1));
      while (true) {
        bool hadWorkout = _workouts.any((w) {
          final workoutDate =
              DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
          return workoutDate.isAtSameMomentAs(checkDate);
        });

        if (hadWorkout) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    }

    // If we had a workout today, check previous days
    DateTime checkDate = today.subtract(const Duration(days: 1));
    while (true) {
      bool hadWorkout = _workouts.any((w) {
        final workoutDate =
            DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
        return workoutDate.isAtSameMomentAs(checkDate);
      });

      if (hadWorkout) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Private methods

  /// Start location tracking for the workout
  Future<void> _startLocationTracking() async {
    try {
      // Reset location buffer
      _locationBuffer = [];

      // Start location service
      final startSuccess = await _locationService?.startTracking() ?? false;

      if (startSuccess) {
        // Subscribe to location updates
        _locationSubscription = _locationService?.locationStream.listen(
          _handleLocationUpdate,
          onError: (error) {
            AppLogger.error('Location tracking error', error);
          },
        );
      } else {
        AppLogger.warning('Failed to start location tracking');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error starting location tracking', e, stackTrace);
    }
  }

  /// Resume workout tracking after app restart
  void _resumeWorkoutTracking() {
    try {
      // Start location tracking
      _startLocationTracking();

      // Start duration timer
      _startDurationTimer();
    } catch (e, stackTrace) {
      AppLogger.error('Error resuming workout tracking', e, stackTrace);
    }
  }

  /// Start the duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentWorkout != null) {
        _currentWorkout = Workout(
          id: _currentWorkout!.id,
          name: _currentWorkout!.name,
          type: _currentWorkout!.type,
          startTime: _currentWorkout!.startTime,
          duration: _currentWorkout!.duration + 1,
          distance: _currentWorkout!.distance,
          averageSpeed: _currentWorkout!.averageSpeed,
          calories: _currentWorkout!.calories,
          locations: _currentWorkout!.locations,
          notes: _currentWorkout!.notes,
        );

        // Update calories based on duration change
        _updateWorkoutStats();

        notifyListeners();
      }
    });
  }

  /// Handle new location data
  void _handleLocationUpdate(LocationData location) {
    if (!_isWorkoutActive || _isWorkoutPaused || _currentWorkout == null)
      return;

    // Add to location buffer
    _locationBuffer.add(location);

    // Process location updates periodically to reduce CPU load
    if (_locationBuffer.length >= 5) {
      _processLocationBuffer();
    }
  }

  /// Process location buffer and update workout stats
  void _processLocationBuffer() {
    if (_locationBuffer.isEmpty || _currentWorkout == null) return;

    try {
      // Add locations to workout
      final updatedLocations =
          List<LocationData>.from(_currentWorkout!.locations)
            ..addAll(_locationBuffer);

      // Update current workout with new locations
      _currentWorkout = Workout(
        id: _currentWorkout!.id,
        name: _currentWorkout!.name,
        type: _currentWorkout!.type,
        startTime: _currentWorkout!.startTime,
        duration: _currentWorkout!.duration,
        distance: _calculateDistance(updatedLocations),
        averageSpeed:
            _calculateAverageSpeed(updatedLocations, _currentWorkout!.duration),
        calories: _currentWorkout!.calories,
        locations: updatedLocations,
        notes: _currentWorkout!.notes,
      );

      // Update calories based on new distance
      _updateWorkoutStats();

      // Clear buffer
      _locationBuffer = [];

      // Save current state periodically
      _saveCurrentWorkoutState();

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error processing location updates', e, stackTrace);
    }
  }

  /// Calculate distance from locations
  double _calculateDistance(List<LocationData> locations) {
    if (locations.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < locations.length - 1; i++) {
      totalDistance += LocationData.calculateDistance(
        locations[i].latitude,
        locations[i].longitude,
        locations[i + 1].latitude,
        locations[i + 1].longitude,
      );
    }

    return totalDistance / 1000; // Convert meters to kilometers
  }

  /// Calculate average speed (km/h)
  double _calculateAverageSpeed(
      List<LocationData> locations, int durationSeconds) {
    if (locations.isEmpty || durationSeconds <= 0) return 0;

    // Calculate distance in km
    final distance = _calculateDistance(locations);

    // Calculate hours
    final hours = durationSeconds / 3600;

    // Calculate speed
    return distance / hours;
  }

  /// Update workout stats like calories
  void _updateWorkoutStats() {
    if (_currentWorkout == null) return;

    try {
      final durationMinutes = _currentWorkout!.duration ~/ 60;
      final distanceKm = _currentWorkout!.distance;
      final avgSpeedKmh = _currentWorkout!.averageSpeed;

      // Calculate calories using enhanced calculation
      final calories = WorkoutCalculations.calculateCaloriesBurned(
        workoutType: _currentWorkout!.type,
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        avgSpeedKmh: avgSpeedKmh,
        userProfile: null, // Will use default values
      );

      // Update calories in current workout
      _currentWorkout = Workout(
        id: _currentWorkout!.id,
        name: _currentWorkout!.name,
        type: _currentWorkout!.type,
        startTime: _currentWorkout!.startTime,
        duration: _currentWorkout!.duration,
        distance: _currentWorkout!.distance,
        averageSpeed: _currentWorkout!.averageSpeed,
        calories: calories,
        locations: _currentWorkout!.locations,
        notes: _currentWorkout!.notes,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error updating workout stats', e, stackTrace);
    }
  }

  /// Get a completed workout with final calculations
  Workout _getFinalWorkout() {
    if (_currentWorkout == null) {
      throw Exception('Cannot get final workout: no current workout');
    }

    // Ensure any remaining locations are processed
    _processLocationBuffer();

    // Apply final calculations for accuracy
    final duration = _currentWorkout!.duration;
    final durationMinutes = duration ~/ 60;
    final distance = _currentWorkout!.distance;
    final averageSpeed = _currentWorkout!.averageSpeed;

    // Calculate calories with enhanced algorithm
    final calories = WorkoutCalculations.calculateCaloriesBurned(
      workoutType: _currentWorkout!.type,
      durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
      distanceKm: distance,
      avgSpeedKmh: averageSpeed,
      userProfile: null, // Will use default values
    );

    // Create final workout object
    return Workout(
      id: _currentWorkout!.id,
      name: _currentWorkout!.name,
      type: _currentWorkout!.type,
      startTime: _currentWorkout!.startTime,
      duration: duration,
      distance: distance,
      averageSpeed: averageSpeed,
      calories: calories,
      locations: _currentWorkout!.locations,
      notes: _currentWorkout!.notes,
    );
  }

  /// Calculate total distance of all workouts
  double _calculateTotalDistance() {
    return _workouts.fold<double>(0, (sum, workout) => sum + workout.distance);
  }

  /// Calculate total duration of all workouts (in seconds)
  int _calculateTotalDuration() {
    return _workouts.fold<int>(0, (sum, workout) => sum + workout.duration);
  }

  /// Get default workout name based on type and time
  String _getDefaultWorkoutName(WorkoutType type, DateTime dateTime) {
    final typeString = type.toString().split('.').last;
    final dateString = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    return '${typeString.substring(0, 1).toUpperCase()}${typeString.substring(1)} - $dateString';
  }

  /// Save current workout state
  Future<void> _saveCurrentWorkoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentWorkout != null) {
        await prefs.setString(
            _keyCurrentWorkout, jsonEncode(_currentWorkout!.toJson()));
      } else {
        await prefs.remove(_keyCurrentWorkout);
      }

      await prefs.setBool(_keyIsWorkoutActive, _isWorkoutActive);
      await prefs.setBool(_keyIsWorkoutPaused, _isWorkoutPaused);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving current workout state', e, stackTrace);
    }
  }

  /// Save workout data to SharedPreferences
  Future<void> _saveWorkoutData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save workout history
      final workoutsJsonList =
          _workouts.map((w) => jsonEncode(w.toJson())).toList();
      await prefs.setStringList(_keyWorkouts, workoutsJsonList);

      // Save current workout state
      await _saveCurrentWorkoutState();
    } catch (e, stackTrace) {
      AppLogger.error('Error saving workout data', e, stackTrace);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
