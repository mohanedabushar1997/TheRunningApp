import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../gps/location_service.dart';
import '../../data/models/workout.dart';
import '../../presentation/utils/format_utils.dart';

/// Enhanced Voice Coaching Service with offline capabilities
/// 
/// This service provides voice feedback during workouts with both online and offline capabilities.
/// It uses Flutter TTS for text-to-speech conversion and falls back to pre-recorded audio files
/// when offline or when TTS is not available.
class VoiceCoachingService {
  // Singleton pattern
  static final VoiceCoachingService _instance = VoiceCoachingService._internal();
  factory VoiceCoachingService() => _instance;
  VoiceCoachingService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  bool _isOfflineMode = false;
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5; // Slower rate for better clarity
  
  // Map of pre-recorded audio files for offline use
  Map<String, String> _audioFiles = {};
  
  // Audio categories for organization
  static const String CATEGORY_WORKOUT_START = 'workout_start';
  static const String CATEGORY_WORKOUT_COMPLETE = 'workout_complete';
  static const String CATEGORY_INTERVAL_CHANGE = 'interval_change';
  static const String CATEGORY_PROGRESS = 'progress';
  static const String CATEGORY_MOTIVATION = 'motivation';
  static const String CATEGORY_MILESTONE = 'milestone';

  /// Initialize the voice coaching service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize TTS engine
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_rate);
      
      // Check if device has TTS voices installed
      List<dynamic>? voices = await _flutterTts.getVoices;
      _isOfflineMode = voices == null || voices.isEmpty;
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      // Set up error handler to switch to offline mode
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _isOfflineMode = true;
        _isSpeaking = false;
      });
      
      // Initialize offline audio files
      await _initializeOfflineAudio();
      
      _initialized = true;
    } catch (e) {
      print('Failed to initialize TTS: $e');
      _isOfflineMode = true;
    }
  }
  
  /// Initialize offline audio files
  Future<void> _initializeOfflineAudio() async {
    // This would typically load pre-recorded audio files from assets
    // For now, we'll just define the mapping of phrases to file paths
    
    // In a real implementation, these would be actual audio files in the assets folder
    _audioFiles = {
      // Workout start messages
      'starting_running_workout': 'assets/audio/starting_running_workout.mp3',
      'starting_walking_workout': 'assets/audio/starting_walking_workout.mp3',
      'starting_interval_workout': 'assets/audio/starting_interval_workout.mp3',
      
      // Workout complete messages
      'workout_complete': 'assets/audio/workout_complete.mp3',
      'great_job': 'assets/audio/great_job.mp3',
      
      // Interval change messages
      'now_running': 'assets/audio/now_running.mp3',
      'now_walking': 'assets/audio/now_walking.mp3',
      'now_resting': 'assets/audio/now_resting.mp3',
      
      // Progress messages
      'distance_covered': 'assets/audio/distance_covered.mp3',
      'current_pace': 'assets/audio/current_pace.mp3',
      
      // Motivation messages
      'motivation_1': 'assets/audio/motivation_1.mp3',
      'motivation_2': 'assets/audio/motivation_2.mp3',
      'motivation_3': 'assets/audio/motivation_3.mp3',
      'motivation_4': 'assets/audio/motivation_4.mp3',
      'motivation_5': 'assets/audio/motivation_5.mp3',
      
      // Milestone messages
      'reached_1km': 'assets/audio/reached_1km.mp3',
      'reached_2km': 'assets/audio/reached_2km.mp3',
      'reached_3km': 'assets/audio/reached_3km.mp3',
      'reached_4km': 'assets/audio/reached_4km.mp3',
      'reached_5km': 'assets/audio/reached_5km.mp3',
    };
  }

  /// Speak text using TTS or play pre-recorded audio if in offline mode
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();

    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _isSpeaking = true;
    
    if (_isOfflineMode) {
      // In offline mode, we would play a pre-recorded audio file
      // that most closely matches the text
      // This is a simplified implementation
      print('Using offline TTS mode: $text');
      // In a real implementation, we would use a package like just_audio
      // to play the pre-recorded audio file
      
      // Simulate completion after a delay
      await Future.delayed(Duration(seconds: 2));
      _isSpeaking = false;
    } else {
      // Use online TTS
      await _flutterTts.speak(text);
    }
  }

  /// Announce the start of a workout
  Future<void> announceWorkoutStart(String workoutType) async {
    await speak('Starting $workoutType workout. Let\'s go!');
  }

  /// Announce the completion of a workout with metrics
  Future<void> announceWorkoutComplete(Workout workout) async {
    final distance = FormatUtils.formatDistance(workout.distance, false);
    final duration = FormatUtils.formatDuration(workout.duration);
    final calories = workout.calories.toStringAsFixed(0);

    await speak(
      'Workout complete! You covered $distance in $duration and burned approximately $calories calories. Great job!',
    );
  }

  /// Announce a change in interval during interval training
  Future<void> announceIntervalChange(
    String intervalType,
    int durationSeconds,
  ) async {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;

    String durationText = '';
    if (minutes > 0) {
      durationText = '$minutes minute${minutes > 1 ? 's' : ''}';
      if (seconds > 0) {
        durationText += ' and $seconds second${seconds > 1 ? 's' : ''}';
      }
    } else {
      durationText = '$seconds second${seconds > 1 ? 's' : ''}';
    }

    await speak('Now $intervalType for $durationText');
  }

  /// Announce progress during a workout with current metrics
  Future<void> announceProgress(Workout workout) async {
    final distance = FormatUtils.formatDistance(workout.distance, false);
    final duration = FormatUtils.formatDuration(workout.duration);
    final pace = FormatUtils.formatPace(workout.pace, false);
    final calories = workout.calories.toStringAsFixed(0);

    await speak(
      'You\'ve covered $distance in $duration. Your current pace is $pace and you\'ve burned approximately $calories calories.',
    );
  }

  /// Announce a motivational phrase
  Future<void> announceMotivation() async {
    final motivationalPhrases = [
      'You\'re doing great! Keep pushing!',
      'Stay strong, you\'ve got this!',
      'Excellent work! Keep up the pace!',
      'You\'re making great progress!',
      'Keep going! Every step counts!',
      'You\'re stronger than you think!',
      'Believe in yourself! You can do this!',
      'Focus on your breathing and keep moving!',
      'You\'re building a stronger you with every step!',
      'Don\'t give up now, you\'re doing amazing!',
    ];

    final phrase = motivationalPhrases[DateTime.now().millisecond % motivationalPhrases.length];
    await speak(phrase);
  }

  /// Announce reaching a distance milestone
  Future<void> announceMilestone(double distance) async {
    // Convert to km for milestone announcements
    final kmDistance = (distance / 1000).floor();

    if (kmDistance > 0 && kmDistance % 1 == 0) {
      await speak('You\'ve reached $kmDistance kilometers. Keep it up!');
    }
  }

  /// Announce heart rate zone information
  Future<void> announceHeartRateZone(int heartRate) async {
    String zone = '';
    
    if (heartRate < 120) {
      zone = 'easy';
    } else if (heartRate < 140) {
      zone = 'fat burning';
    } else if (heartRate < 160) {
      zone = 'cardio';
    } else {
      zone = 'peak';
    }
    
    await speak('Your heart rate is $heartRate beats per minute. You are in the $zone zone.');
  }

  /// Announce upcoming interval change
  Future<void> announceUpcomingIntervalChange(String nextIntervalType, int secondsRemaining) async {
    if (secondsRemaining <= 10) {
      await speak('$secondsRemaining seconds until $nextIntervalType.');
    }
  }

  /// Set the volume for voice coaching
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Check if the service is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if the service is in offline mode
  bool get isOfflineMode => _isOfflineMode;

  /// Force the service to use offline mode
  void forceOfflineMode(bool offline) {
    _isOfflineMode = offline;
  }

  /// Clean up resources
  void dispose() {
    _flutterTts.stop();
  }
}

/// Class representing workout metrics for voice coaching
class WorkoutMetrics {
  final double distance;
  final Duration duration;
  final double pace;
  final int? heartRate;
  final double calories;
  final String formattedDuration;
  final String formattedPace;

  WorkoutMetrics({
    required this.distance,
    required this.duration,
    required this.pace,
    this.heartRate,
    required this.calories,
    required this.formattedDuration,
    required this.formattedPace,
  });

  factory WorkoutMetrics.fromWorkout(Workout workout, bool useImperial) {
    return WorkoutMetrics(
      distance: workout.distance,
      duration: workout.duration,
      pace: workout.pace,
      heartRate: workout.currentHeartRate,
      calories: workout.calories,
      formattedDuration: FormatUtils.formatDuration(workout.duration),
      formattedPace: FormatUtils.formatPace(workout.pace, useImperial),
    );
  }
}
