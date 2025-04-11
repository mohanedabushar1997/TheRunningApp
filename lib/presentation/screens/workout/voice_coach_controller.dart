import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../device/audio/voice_coaching_service_enhanced.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../data/models/workout.dart';

/// A controller for managing voice coaching during workouts
/// 
/// This controller integrates with the workout screen to provide
/// voice feedback at appropriate times during the workout.
class VoiceCoachController {
  final VoiceCoachingService _voiceCoachingService = VoiceCoachingService();
  final WorkoutProvider _workoutProvider;
  final SettingsProvider _settingsProvider;
  final BuildContext _context;
  
  Timer? _progressTimer;
  Timer? _motivationTimer;
  double _lastMilestoneDistance = 0.0;
  bool _isActive = false;
  
  VoiceCoachController(this._context) 
      : _workoutProvider = Provider.of<WorkoutProvider>(_context, listen: false),
        _settingsProvider = Provider.of<SettingsProvider>(_context, listen: false);
  
  /// Initialize the voice coach controller
  Future<void> initialize() async {
    await _voiceCoachingService.initialize();
  }
  
  /// Start voice coaching for a workout
  Future<void> startWorkout(Workout workout) async {
    if (!_settingsProvider.voiceCoachEnabled) return;
    
    _isActive = true;
    
    // Announce workout start
    await _voiceCoachingService.announceWorkoutStart(
      _getWorkoutTypeString(workout.type)
    );
    
    // Set up timers for periodic announcements
    _setupTimers();
  }
  
  /// Handle interval change during interval workouts
  Future<void> handleIntervalChange(String intervalType, int durationSeconds) async {
    if (!_settingsProvider.voiceCoachEnabled || 
        !_settingsProvider.announceIntervals ||
        !_isActive) return;
    
    await _voiceCoachingService.announceIntervalChange(intervalType, durationSeconds);
  }
  
  /// Announce upcoming interval change
  Future<void> announceUpcomingIntervalChange(String nextIntervalType, int secondsRemaining) async {
    if (!_settingsProvider.voiceCoachEnabled || 
        !_settingsProvider.announceIntervals ||
        !_isActive) return;
    
    await _voiceCoachingService.announceUpcomingIntervalChange(nextIntervalType, secondsRemaining);
  }
  
  /// Complete the workout and announce final stats
  Future<void> completeWorkout(Workout workout) async {
    if (!_settingsProvider.voiceCoachEnabled || !_isActive) return;
    
    _isActive = false;
    
    // Cancel timers
    _progressTimer?.cancel();
    _motivationTimer?.cancel();
    
    // Announce workout completion
    await _voiceCoachingService.announceWorkoutComplete(workout);
  }
  
  /// Pause voice coaching
  void pause() {
    _progressTimer?.cancel();
    _motivationTimer?.cancel();
  }
  
  /// Resume voice coaching
  void resume() {
    if (!_isActive) return;
    _setupTimers();
  }
  
  /// Set up timers for periodic announcements
  void _setupTimers() {
    // Cancel existing timers
    _progressTimer?.cancel();
    _motivationTimer?.cancel();
    
    // Set up progress announcement timer
    if (_settingsProvider.announceProgress) {
      final progressFrequency = _settingsProvider.progressAnnouncementFrequency;
      _progressTimer = Timer.periodic(
        Duration(minutes: progressFrequency),
        (_) => _announceProgress(),
      );
    }
    
    // Set up motivation announcement timer
    if (_settingsProvider.announceMotivation) {
      _motivationTimer = Timer.periodic(
        const Duration(minutes: 3), // Motivational phrases every 3 minutes
        (_) => _announceMotivation(),
      );
    }
  }
  
  /// Announce current progress
  Future<void> _announceProgress() async {
    if (!_isActive) return;
    
    final workout = _workoutProvider.currentWorkout;
    if (workout == null) return;
    
    await _voiceCoachingService.announceProgress(workout);
    
    // Check for milestones
    if (_settingsProvider.announceMilestones) {
      _checkMilestones(workout.distance);
    }
  }
  
  /// Announce a motivational phrase
  Future<void> _announceMotivation() async {
    if (!_isActive) return;
    
    await _voiceCoachingService.announceMotivation();
  }
  
  /// Check for distance milestones
  Future<void> _checkMilestones(double distance) async {
    if (!_isActive) return;
    
    // Convert to km
    final kmDistance = distance / 1000;
    final lastKmDistance = _lastMilestoneDistance / 1000;
    
    // Check if we've passed a kilometer milestone
    if (kmDistance.floor() > lastKmDistance.floor()) {
      _lastMilestoneDistance = distance;
      await _voiceCoachingService.announceMilestone(distance);
    }
  }
  
  /// Get a string representation of the workout type
  String _getWorkoutTypeString(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return 'running';
      case WorkoutType.walking:
        return 'walking';
      case WorkoutType.interval:
        return 'interval';
      case WorkoutType.treadmill:
        return 'treadmill';
      default:
        return 'workout';
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _progressTimer?.cancel();
    _motivationTimer?.cancel();
    _isActive = false;
  }
}
