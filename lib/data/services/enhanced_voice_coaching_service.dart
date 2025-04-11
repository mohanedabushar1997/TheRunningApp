import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced voice coaching service with advanced features
///
/// Provides sophisticated text-to-speech functionality for workout guidance
/// with voice customization, dynamic coaching, and multilingual support.
class EnhancedVoiceCoachingService {
  // Singleton pattern
  static final EnhancedVoiceCoachingService _instance = EnhancedVoiceCoachingService._internal();
  factory EnhancedVoiceCoachingService() => _instance;
  EnhancedVoiceCoachingService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  
  // Voice settings
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  String _language = 'en-US';
  String _voice = '';
  
  // Available voices
  List<Map<String, dynamic>> _availableVoices = [];
  List<String> _availableLanguages = [];
  
  // Coaching settings
  bool _isEnabled = true;
  bool _announceDistance = true;
  bool _announcePace = true;
  bool _announceTime = true;
  bool _announceCalories = false;
  int _announcementFrequency = 1; // in minutes
  
  // Queue for announcements to prevent overlap
  final _announcementQueue = <String>[];
  bool _isProcessingQueue = false;
  
  // Coaching phrases for motivation
  final Map<String, List<String>> _motivationalPhrases = {
    'start': [
      "Let's get started! You've got this!",
      "Ready to crush your workout today!",
      "Time to hit the road and achieve your goals!",
    ],
    'milestone': [
      "Great job! You're making excellent progress!",
      "Keep it up! You're doing amazing!",
      "Fantastic work! You're crushing this workout!",
    ],
    'slowdown': [
      "You're pushing too hard. Try slowing down a bit.",
      "Remember to pace yourself. Slow down slightly.",
      "Ease up a little to maintain your endurance.",
    ],
    'speedup': [
      "You can push a bit harder! Pick up the pace!",
      "Let's increase that speed! You've got more to give!",
      "Time to challenge yourself! Speed up a little!",
    ],
    'finish': [
      "Excellent work! You've completed your workout!",
      "Workout complete! You should be proud of yourself!",
      "You did it! Great job finishing strong!",
    ],
  };
  
  // Multilingual support
  final Map<String, Map<String, String>> _translations = {
    'en-US': {
      'distance': 'You have covered {distance} {unit}',
      'pace': 'Your current pace is {minutes} minutes and {seconds} seconds per {unit}',
      'time': 'You have been running for {time}',
      'calories': 'You have burned {calories} calories',
    },
    'es-ES': {
      'distance': 'Has recorrido {distance} {unit}',
      'pace': 'Tu ritmo actual es de {minutes} minutos y {seconds} segundos por {unit}',
      'time': 'Has estado corriendo durante {time}',
      'calories': 'Has quemado {calories} calorías',
    },
    'fr-FR': {
      'distance': 'Vous avez parcouru {distance} {unit}',
      'pace': 'Votre allure actuelle est de {minutes} minutes et {seconds} secondes par {unit}',
      'time': 'Vous courez depuis {time}',
      'calories': 'Vous avez brûlé {calories} calories',
    },
  };

  /// Initialize the voice coaching service
  Future<void> initialize() async {
    if (_initialized) return;

    // Configure TTS settings
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setLanguage(_language);
    
    // Get available voices
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        _availableVoices = List<Map<String, dynamic>>.from(voices);
        
        // Extract available languages
        final languages = <String>{};
        for (final voice in _availableVoices) {
          final locale = voice['locale'] as String?;
          if (locale != null) {
            languages.add(locale);
          }
        }
        _availableLanguages = languages.toList();
      }
    } catch (e) {
      print('Error getting available voices: $e');
    }

    // Set up completion listener
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processNextInQueue();
    });
    
    // Load saved settings
    await _loadSettings();

    _initialized = true;
  }
  
  /// Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isEnabled = prefs.getBool('voice_coaching_enabled') ?? true;
      _volume = prefs.getDouble('voice_coaching_volume') ?? 1.0;
      _pitch = prefs.getDouble('voice_coaching_pitch') ?? 1.0;
      _rate = prefs.getDouble('voice_coaching_rate') ?? 0.5;
      _language = prefs.getString('voice_coaching_language') ?? 'en-US';
      _voice = prefs.getString('voice_coaching_voice') ?? '';
      
      _announceDistance = prefs.getBool('voice_coaching_announce_distance') ?? true;
      _announcePace = prefs.getBool('voice_coaching_announce_pace') ?? true;
      _announceTime = prefs.getBool('voice_coaching_announce_time') ?? true;
      _announceCalories = prefs.getBool('voice_coaching_announce_calories') ?? false;
      _announcementFrequency = prefs.getInt('voice_coaching_frequency') ?? 1;
      
      // Apply loaded settings
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_rate);
      await _flutterTts.setLanguage(_language);
      
      if (_voice.isNotEmpty) {
        await _flutterTts.setVoice({"name": _voice});
      }
    } catch (e) {
      print('Error loading voice coaching settings: $e');
    }
  }
  
  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('voice_coaching_enabled', _isEnabled);
      await prefs.setDouble('voice_coaching_volume', _volume);
      await prefs.setDouble('voice_coaching_pitch', _pitch);
      await prefs.setDouble('voice_coaching_rate', _rate);
      await prefs.setString('voice_coaching_language', _language);
      await prefs.setString('voice_coaching_voice', _voice);
      
      await prefs.setBool('voice_coaching_announce_distance', _announceDistance);
      await prefs.setBool('voice_coaching_announce_pace', _announcePace);
      await prefs.setBool('voice_coaching_announce_time', _announceTime);
      await prefs.setBool('voice_coaching_announce_calories', _announceCalories);
      await prefs.setInt('voice_coaching_frequency', _announcementFrequency);
    } catch (e) {
      print('Error saving voice coaching settings: $e');
    }
  }

  /// Speak a message using text-to-speech
  Future<void> speak(String message) async {
    if (!_initialized) await initialize();
    
    if (!_isEnabled) return;

    // Add to queue instead of speaking immediately
    _announcementQueue.add(message);
    
    // Start processing queue if not already processing
    if (!_isProcessingQueue) {
      _processNextInQueue();
    }
  }
  
  /// Process the next announcement in the queue
  Future<void> _processNextInQueue() async {
    if (_announcementQueue.isEmpty || _isSpeaking) {
      _isProcessingQueue = false;
      return;
    }
    
    _isProcessingQueue = true;
    
    if (_isSpeaking) {
      await stop();
    }
    
    final message = _announcementQueue.removeAt(0);
    _isSpeaking = true;
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print('Error speaking message: $e');
      _isSpeaking = false;
      _processNextInQueue();
    }
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }
  
  /// Clear the announcement queue
  void clearQueue() {
    _announcementQueue.clear();
  }

  /// Enable or disable voice coaching
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    
    if (!_isEnabled) {
      await stop();
      clearQueue();
    }
  }

  /// Set the volume for speech (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
    await _saveSettings();
  }

  /// Set the pitch for speech (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
    await _saveSettings();
  }

  /// Set the speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_rate);
    await _saveSettings();
  }

  /// Set the language for speech
  Future<void> setLanguage(String language) async {
    if (_availableLanguages.contains(language)) {
      _language = language;
      await _flutterTts.setLanguage(_language);
      await _saveSettings();
    } else {
      print('Language not available: $language');
    }
  }
  
  /// Set the voice for speech
  Future<void> setVoice(String voice) async {
    _voice = voice;
    if (_voice.isNotEmpty) {
      await _flutterTts.setVoice({"name": _voice});
    }
    await _saveSettings();
  }
  
  /// Configure which metrics to announce
  Future<void> configureAnnouncements({
    bool? announceDistance,
    bool? announcePace,
    bool? announceTime,
    bool? announceCalories,
    int? frequency,
  }) async {
    _announceDistance = announceDistance ?? _announceDistance;
    _announcePace = announcePace ?? _announcePace;
    _announceTime = announceTime ?? _announceTime;
    _announceCalories = announceCalories ?? _announceCalories;
    
    if (frequency != null && frequency > 0) {
      _announcementFrequency = frequency;
    }
    
    await _saveSettings();
  }

  /// Announce the current distance
  Future<void> announceDistance(double distance, bool isMetric) async {
    if (!_isEnabled || !_announceDistance) return;
    
    final unit = isMetric ? 
        (_language == 'en-US' ? 'kilometers' : 'km') : 
        (_language == 'en-US' ? 'miles' : 'mi');
    
    final formattedDistance = isMetric 
        ? (distance / 1000).toStringAsFixed(2) 
        : (distance / 1609.34).toStringAsFixed(2);
    
    final template = _getTranslation('distance');
    final message = template
        .replaceAll('{distance}', formattedDistance)
        .replaceAll('{unit}', unit);
    
    await speak(message);
  }

  /// Announce the current pace
  Future<void> announcePace(double paceSeconds, bool isMetric) async {
    if (!_isEnabled || !_announcePace) return;
    
    final unit = isMetric ? 
        (_language == 'en-US' ? 'kilometer' : 'km') : 
        (_language == 'en-US' ? 'mile' : 'mi');
    
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).floor();
    
    final template = _getTranslation('pace');
    final message = template
        .replaceAll('{minutes}', minutes.toString())
        .replaceAll('{seconds}', seconds.toString())
        .replaceAll('{unit}', unit);
    
    await speak(message);
  }

  /// Announce the elapsed time
  Future<void> announceTime(int seconds) async {
    if (!_isEnabled || !_announceTime) return;
    
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = seconds % 60;
    
    String timeString = '';
    
    if (hours > 0) {
      timeString += '$hours ${_language == 'en-US' ? 'hours' : 'h'}, ';
    }
    
    if (minutes > 0 || hours > 0) {
      timeString += '$minutes ${_language == 'en-US' ? 'minutes' : 'min'}, ';
    }
    
    timeString += '$remainingSeconds ${_language == 'en-US' ? 'seconds' : 's'}';
    
    final template = _getTranslation('time');
    final message = template.replaceAll('{time}', timeString);
    
    await speak(message);
  }
  
  /// Announce calories burned
  Future<void> announceCalories(int calories) async {
    if (!_isEnabled || !_announceCalories) return;
    
    final template = _getTranslation('calories');
    final message = template.replaceAll('{calories}', calories.toString());
    
    await speak(message);
  }

  /// Announce a workout milestone with a motivational message
  Future<void> announceMilestone(String milestone) async {
    if (!_isEnabled) return;
    
    final phrases = _motivationalPhrases['milestone'] ?? [];
    if (phrases.isNotEmpty) {
      final index = DateTime.now().millisecondsSinceEpoch % phrases.length;
      final message = '${milestone}. ${phrases[index]}';
      await speak(message);
    } else {
      await speak('Congratulations! $milestone');
    }
  }

  /// Announce the start of a workout
  Future<void> announceWorkoutStart() async {
    if (!_isEnabled) return;
    
    final phrases = _motivationalPhrases['start'] ?? [];
    if (phrases.isNotEmpty) {
      final index = DateTime.now().millisecondsSinceEpoch % phrases.length;
      await speak(phrases[index]);
    } else {
      await speak("Let's get started! You've got this!");
    }
  }
  
  /// Announce the end of a workout
  Future<void> announceWorkoutFinish() async {
    if (!_isEnabled) return;
    
    final phrases = _motivationalPhrases['finish'] ?? [];
    if (phrases.isNotEmpty) {
      final index = DateTime.now().millisecondsSinceEpoch % phrases.length;
      await speak(phrases[index]);
    } else {
      await speak("Excellent work! You've completed your workout!");
    }
  }
  
  /// Suggest slowing down
  Future<void> suggestSlowDown() async {
    if (!_isEnabled) return;
    
    final phrases = _motivationalPhrases['slowdown'] ?? [];
    if (phrases.isNotEmpty) {
      final index = DateTime.now().millisecondsSinceEpoch % phrases.length;
      await speak(phrases[index]);
    } else {
      await speak("You're pushing too hard. Try slowing down a bit.");
    }
  }
  
  /// Suggest speeding up
  Future<void> suggestSpeedUp() async {
    if (!_isEnabled) return;
    
    final phrases = _motivationalPhrases['speedup'] ?? [];
    if (phrases.isNotEmpty) {
      final index = DateTime.now().millisecondsSinceEpoch % phrases.length;
      await speak(phrases[index]);
    } else {
      await speak("You can push a bit harder! Pick up the pace!");
    }
  }
  
  /// Announce a custom motivational message
  Future<void> announceMotivation(String message) async {
    if (!_isEnabled) return;
    
    await speak(message);
  }
  
  /// Get a translation for the current language
  String _getTranslation(String key) {
    final translations = _translations[_language] ?? _translations['en-US']!;
    return translations[key] ?? _translations['en-US']![key]!;
  }

  /// Check if the service is currently speaking
  bool get isSpeaking => _isSpeaking;
  
  /// Check if voice coaching is enabled
  bool get isEnabled => _isEnabled;
  
  /// Get the current volume
  double get volume => _volume;
  
  /// Get the current pitch
  double get pitch => _pitch;
  
  /// Get the current rate
  double get rate => _rate;
  
  /// Get the current language
  String get language => _language;
  
  /// Get the current voice
  String get voice => _voice;
  
  /// Get available languages
  List<String> get availableLanguages => List.unmodifiable(_availableLanguages);
  
  /// Get available voices
  List<Map<String, dynamic>> get availableVoices => List.unmodifiable(_availableVoices);
  
  /// Get announcement settings
  Map<String, dynamic> get announcementSettings => {
    'announceDistance': _announceDistance,
    'announcePace': _announcePace,
    'announceTime': _announceTime,
    'announceCalories': _announceCalories,
    'frequency': _announcementFrequency,
  };
  
  /// Get announcement frequency in minutes
  int get announcementFrequency => _announcementFrequency;

  /// Dispose of resources
  void dispose() {
    _flutterTts.stop();
  }
}
