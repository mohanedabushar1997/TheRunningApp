import 'package:flutter/material.dart';
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define keys for SharedPreferences
const String _themeModeKey = 'app_theme_mode';
const String _useImperialKey = 'use_imperial_units';
const String _onboardingCompleteKey = 'onboarding_complete';
// TODO: Add keys for other settings (GPS accuracy, voice coach enabled, notification prefs etc.)
const String _gpsAccuracyKey = 'gps_accuracy_setting';
const String _voiceCoachEnabledKey = 'voice_coach_enabled';
const String _dataSaverModeKey = 'data_saver_mode';


// Enum for GPS Accuracy Preference (Example)
enum GpsAccuracyPreference { low, balanced, high }


class SettingsProvider with ChangeNotifier {
  // --- Private backing fields ---
  ThemeMode _themeMode = ThemeMode.system;
  bool _useImperialUnits = false;
  bool _isOnboardingComplete = false;
  bool _isLoading = true; // Start as loading
  Future<void>? _loadingFuture; // To ensure settings are loaded only once

  // GPS Settings Example
  GpsAccuracyPreference _gpsAccuracy = GpsAccuracyPreference.high;

   // Voice Coach Example
   bool _voiceCoachEnabled = true;

   // Data Saver Example
   bool _dataSaverMode = false;


  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  bool get useImperialUnits => _useImperialUnits;
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoading => _isLoading;
  GpsAccuracyPreference get gpsAccuracy => _gpsAccuracy;
  bool get voiceCoachEnabled => _voiceCoachEnabled;
  bool get dataSaverMode => _dataSaverMode;


  // Ensures settings are loaded before proceeding (used in AppStartWrapper)
  Future<void> ensureSettingsLoaded() {
     // If already loaded or currently loading, return the existing future
     _loadingFuture ??= loadSettings();
     return _loadingFuture!;
  }


  // --- Load settings from SharedPreferences ---
  Future<void> loadSettings() async {
    // Prevent multiple concurrent loads if called directly elsewhere
    if (!_isLoading && _loadingFuture != null) return;

    _isLoading = true;
    // Don't notify listeners immediately, wait until load is complete

    try {
      final prefs = await SharedPreferences.getInstance();
      Log.d("Loading settings from SharedPreferences...");

      // Load Theme Mode
      final themeModeString = prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      } else {
         _themeMode = ThemeMode.system; // Default
      }

      // Load Unit Preference
      _useImperialUnits = prefs.getBool(_useImperialKey) ?? false; // Default false (metric)

      // Load Onboarding Status
      _isOnboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;

      // TODO: Load other settings
       final gpsAccuracyString = prefs.getString(_gpsAccuracyKey);
       _gpsAccuracy = GpsAccuracyPreference.values.firstWhere(
          (e) => e.name == gpsAccuracyString, orElse: () => GpsAccuracyPreference.high);

       _voiceCoachEnabled = prefs.getBool(_voiceCoachEnabledKey) ?? true;
       _dataSaverMode = prefs.getBool(_dataSaverModeKey) ?? false;


      Log.i("Settings loaded: Theme=$_themeMode, Imperial=$_useImperialUnits, OnboardingComplete=$_isOnboardingComplete, GPS=$_gpsAccuracy");

    } catch (e, s) {
      Log.e("Error loading settings", error: e, stackTrace: s);
      // Keep default values on error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify that loading is complete
    }
  }

  // --- Setters (Save to SharedPreferences and notify listeners) ---

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    Log.i("Setting theme mode to: $mode");
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e, s) {
       Log.e("Error saving theme mode", error: e, stackTrace: s);
    }
  }

  Future<void> setUseImperialUnits(bool value) async {
    if (_useImperialUnits == value) return;
    _useImperialUnits = value;
    Log.i("Setting use imperial units to: $value");
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useImperialKey, value);
    } catch (e, s) {
       Log.e("Error saving unit preference", error: e, stackTrace: s);
    }
  }

  Future<void> setOnboardingComplete(bool value) async {
    if (_isOnboardingComplete == value) return;
    _isOnboardingComplete = value;
    Log.i("Setting onboarding complete to: $value");
    notifyListeners(); // Notify potentially waiting AppStartWrapper
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, value);
    } catch (e, s) {
       Log.e("Error saving onboarding status", error: e, stackTrace: s);
    }
  }

   // TODO: Add setters for other settings
   Future<void> setGpsAccuracy(GpsAccuracyPreference value) async {
      if (_gpsAccuracy == value) return;
      _gpsAccuracy = value;
      Log.i("Setting GPS Accuracy to: ${value.name}");
      notifyListeners();
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString(_gpsAccuracyKey, value.name);
          // TODO: Potentially update LocationService settings immediately
          // context.read<LocationService>().updateSettings(...);
       } catch (e, s) {
          Log.e("Error saving GPS Accuracy", error: e, stackTrace: s);
       }
   }

    Future<void> setVoiceCoachEnabled(bool value) async {
      if (_voiceCoachEnabled == value) return;
      _voiceCoachEnabled = value;
      Log.i("Setting Voice Coach Enabled to: $value");
      notifyListeners();
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setBool(_voiceCoachEnabledKey, value);
          // TODO: Update VoiceCoachService settings immediately
          // context.read<VoiceCoachService>().updateSettings(...);
       } catch (e, s) {
          Log.e("Error saving Voice Coach Enabled status", error: e, stackTrace: s);
       }
   }

    Future<void> setDataSaverMode(bool value) async {
      if (_dataSaverMode == value) return;
      _dataSaverMode = value;
      Log.i("Setting Data Saver Mode to: $value");
      notifyListeners();
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setBool(_dataSaverModeKey, value);
          // TODO: Apply data saver logic (e.g., reduce map tile loading, disable auto-sync)
       } catch (e, s) {
          Log.e("Error saving Data Saver Mode", error: e, stackTrace: s);
       }
   }
}