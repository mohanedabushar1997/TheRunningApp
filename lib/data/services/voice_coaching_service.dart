import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Basic voice coaching service for workout guidance
///
/// Provides text-to-speech functionality for workout announcements
/// and guidance during running sessions.
class VoiceCoachingService {
  // Singleton pattern
  static final VoiceCoachingService _instance = VoiceCoachingService._internal();
  factory VoiceCoachingService() => _instance;
  VoiceCoachingService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  String _language = 'en-US';

  /// Initialize the voice coaching service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure TTS settings
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setLanguage(_language);

    // Set up completion listener
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  /// Speak a message using text-to-speech
  Future<void> speak(String message) async {
    if (!_isInitialized) await initialize();

    if (_isSpeaking) {
      await stop();
    }

    _isSpeaking = true;
    await _flutterTts.speak(message);
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Set the volume for speech (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  /// Set the pitch for speech (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  /// Set the speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_rate);
  }

  /// Set the language for speech
  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(_language);
  }

  /// Announce the current distance
  Future<void> announceDistance(double distance, bool isMetric) async {
    final unit = isMetric ? 'kilometers' : 'miles';
    final formattedDistance = isMetric 
        ? (distance / 1000).toStringAsFixed(2) 
        : (distance / 1609.34).toStringAsFixed(2);
    
    await speak('You have covered $formattedDistance $unit');
  }

  /// Announce the current pace
  Future<void> announcePace(double paceSeconds, bool isMetric) async {
    final unit = isMetric ? 'kilometer' : 'mile';
    
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).floor();
    
    final formattedPace = '$minutes minutes and $seconds seconds per $unit';
    
    await speak('Your current pace is $formattedPace');
  }

  /// Announce the elapsed time
  Future<void> announceTime(int seconds) async {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = seconds % 60;
    
    String timeString = '';
    
    if (hours > 0) {
      timeString += '$hours hours, ';
    }
    
    if (minutes > 0 || hours > 0) {
      timeString += '$minutes minutes, and ';
    }
    
    timeString += '$remainingSeconds seconds';
    
    await speak('You have been running for $timeString');
  }

  /// Announce a workout milestone
  Future<void> announceMilestone(String milestone) async {
    await speak('Congratulations! $milestone');
  }

  /// Announce a motivational message
  Future<void> announceMotivation(String message) async {
    await speak(message);
  }

  /// Check if the service is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose of resources
  void dispose() {
    _flutterTts.stop();
  }
}
