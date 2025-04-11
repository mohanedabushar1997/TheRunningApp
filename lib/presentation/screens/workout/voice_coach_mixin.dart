import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'voice_coach_controller.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../data/models/workout.dart';

/// A mixin that adds voice coaching capabilities to workout screens
mixin VoiceCoachMixin<T extends StatefulWidget> on State<T> {
  VoiceCoachController? _voiceCoachController;
  
  @override
  void initState() {
    super.initState();
    _initializeVoiceCoach();
  }
  
  /// Initialize the voice coach controller
  Future<void> _initializeVoiceCoach() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settingsProvider.voiceCoachEnabled) {
      _voiceCoachController = VoiceCoachController(context);
      await _voiceCoachController!.initialize();
    }
  }
  
  /// Start voice coaching for a workout
  Future<void> startVoiceCoaching(Workout workout) async {
    if (_voiceCoachController != null) {
      await _voiceCoachController!.startWorkout(workout);
    }
  }
  
  /// Handle interval change during interval workouts
  Future<void> handleIntervalChange(String intervalType, int durationSeconds) async {
    if (_voiceCoachController != null) {
      await _voiceCoachController!.handleIntervalChange(intervalType, durationSeconds);
    }
  }
  
  /// Announce upcoming interval change
  Future<void> announceUpcomingIntervalChange(String nextIntervalType, int secondsRemaining) async {
    if (_voiceCoachController != null) {
      await _voiceCoachController!.announceUpcomingIntervalChange(nextIntervalType, secondsRemaining);
    }
  }
  
  /// Complete the workout and announce final stats
  Future<void> completeVoiceCoaching(Workout workout) async {
    if (_voiceCoachController != null) {
      await _voiceCoachController!.completeWorkout(workout);
    }
  }
  
  /// Pause voice coaching
  void pauseVoiceCoaching() {
    _voiceCoachController?.pause();
  }
  
  /// Resume voice coaching
  void resumeVoiceCoaching() {
    _voiceCoachController?.resume();
  }
  
  @override
  void dispose() {
    _voiceCoachController?.dispose();
    super.dispose();
  }
}
