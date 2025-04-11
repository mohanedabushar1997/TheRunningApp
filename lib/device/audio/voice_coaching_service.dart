import 'package:flutter_tts/flutter_tts.dart';
import '../gps/location_service.dart';

class VoiceCoachingService {
  // Singleton pattern
  static final VoiceCoachingService _instance =
      VoiceCoachingService._internal();
  factory VoiceCoachingService() => _instance;
  VoiceCoachingService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5; // Slower rate for better clarity

  Future<void> initialize() async {
    if (_initialized) return;

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await initialize();

    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> announceWorkoutStart(String workoutType) async {
    await speak('Starting $workoutType workout. Let\'s go!');
  }

  Future<void> announceWorkoutComplete(WorkoutMetrics metrics) async {
    final distance =
        metrics.distance < 1000
            ? '${metrics.distance.toStringAsFixed(0)} meters'
            : '${(metrics.distance / 1000).toStringAsFixed(2)} kilometers';

    final duration = metrics.formattedDuration;

    await speak(
      'Workout complete! You covered $distance in $duration. Great job!',
    );
  }

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

  Future<void> announceProgress(WorkoutMetrics metrics) async {
    final distance =
        metrics.distance < 1000
            ? '${metrics.distance.toStringAsFixed(0)} meters'
            : '${(metrics.distance / 1000).toStringAsFixed(2)} kilometers';

    final duration = metrics.formattedDuration;
    final pace = metrics.formattedPace;

    await speak(
      'You\'ve covered $distance in $duration. Your current pace is $pace.',
    );
  }

  Future<void> announceMotivation() async {
    final motivationalPhrases = [
      'You\'re doing great! Keep pushing!',
      'Stay strong, you\'ve got this!',
      'Excellent work! Keep up the pace!',
      'You\'re making great progress!',
      'Keep going! Every step counts!',
    ];

    final phrase =
        motivationalPhrases[DateTime.now().millisecond %
            motivationalPhrases.length];
    await speak(phrase);
  }

  Future<void> announceMilestone(double distance) async {
    // Convert to km for milestone announcements
    final kmDistance = (distance / 1000).floor();

    if (kmDistance > 0 && kmDistance % 1 == 0) {
      await speak('You\'ve reached $kmDistance kilometers. Keep it up!');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}
