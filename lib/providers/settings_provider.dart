import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Provider for application-wide settings
///
/// This class manages application settings and preferences, acting as
/// a centralized state management solution for user preferences.
class SettingsProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyThemeColor = 'theme_color';
  static const String _keyShowMetricUnits = 'show_metric_units';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyVoiceCoachEnabled = 'voice_coach_enabled';
  static const String _keyVoiceCoachVolume = 'voice_coach_volume';
  static const String _keyAnnounceIntervals = 'announce_intervals';
  static const String _keyAnnounceProgress = 'announce_progress';
  static const String _keyAnnounceMotivation = 'announce_motivation';
  static const String _keyAnnounceMilestones = 'announce_milestones';
  static const String _keyProgressAnnouncementFrequency =
      'progress_announcement_frequency';
  static const String _keyKeepScreenOn = 'keep_screen_on';
  static const String _keyEnableCrashReporting = 'enable_crash_reporting';
  static const String _keyEnableAnalytics = 'enable_analytics';
  static const String _keyAutoStartGps = 'auto_start_gps';
  static const String _keyBackgroundTrackingMode = 'background_tracking_mode';
  static const String _keyUseImperialUnits = 'use_imperial_units';
  static const String _keyPowerSavingMode = 'power_saving_mode';
  static const String _keyDataBackupFrequency = 'data_backup_frequency';
  static const String _keyEnableBackgroundTracking =
      'enable_background_tracking';

  // Default values
  static const bool defaultDarkMode = false;
  static const int defaultThemeColor = 0xFF1976D2; // Blue
  static const bool defaultShowMetricUnits = true;
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultVoiceCoachEnabled = true;
  static const double defaultVoiceCoachVolume = 0.7;
  static const bool defaultAnnounceIntervals = true;
  static const bool defaultAnnounceProgress = true;
  static const bool defaultAnnounceMotivation = true;
  static const bool defaultAnnounceMilestones = true;
  static const String defaultProgressAnnouncementFrequency = 'kilometer';
  static const bool defaultKeepScreenOn = true;
  static const bool defaultEnableCrashReporting = true;
  static const bool defaultEnableAnalytics = true;
  static const bool defaultAutoStartGps = true;
  static const String defaultBackgroundTrackingMode = 'balanced';
  static const bool defaultUseImperialUnits = false;
  static const bool defaultPowerSavingMode = false;
  static const String defaultDataBackupFrequency = 'weekly';
  static const bool defaultEnableBackgroundTracking = false;

  // Current settings
  ThemeMode _themeMode = ThemeMode.system;
  int _themeColor = defaultThemeColor;
  bool _showMetricUnits = defaultShowMetricUnits;
  bool _notificationsEnabled = defaultNotificationsEnabled;
  bool _voiceCoachEnabled = defaultVoiceCoachEnabled;
  double _voiceCoachVolume = defaultVoiceCoachVolume;
  bool _announceIntervals = defaultAnnounceIntervals;
  bool _announceProgress = defaultAnnounceProgress;
  bool _announceMotivation = defaultAnnounceMotivation;
  bool _announceMilestones = defaultAnnounceMilestones;
  String _progressAnnouncementFrequency = defaultProgressAnnouncementFrequency;
  bool _keepScreenOn = defaultKeepScreenOn;
  bool _enableCrashReporting = defaultEnableCrashReporting;
  bool _enableAnalytics = defaultEnableAnalytics;
  bool _autoStartGps = defaultAutoStartGps;
  String _backgroundTrackingMode = defaultBackgroundTrackingMode;
  bool _useImperialUnits = defaultUseImperialUnits;
  bool _powerSavingMode = defaultPowerSavingMode;
  String _dataBackupFrequency = defaultDataBackupFrequency;
  bool _enableBackgroundTracking = defaultEnableBackgroundTracking;

  // Initialization flag
  bool _initialized = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  int get themeColor => _themeColor;
  bool get showMetricUnits => _showMetricUnits;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get voiceCoachEnabled => _voiceCoachEnabled;
  double get voiceCoachVolume => _voiceCoachVolume;
  bool get announceIntervals => _announceIntervals;
  bool get announceProgress => _announceProgress;
  bool get announceMotivation => _announceMotivation;
  bool get announceMilestones => _announceMilestones;
  String get progressAnnouncementFrequency => _progressAnnouncementFrequency;
  bool get keepScreenOn => _keepScreenOn;
  bool get enableCrashReporting => _enableCrashReporting;
  bool get enableAnalytics => _enableAnalytics;
  bool get autoStartGps => _autoStartGps;
  String get backgroundTrackingMode => _backgroundTrackingMode;
  bool get useImperialUnits => _useImperialUnits;
  bool get powerSavingMode => _powerSavingMode;
  String get dataBackupFrequency => _dataBackupFrequency;
  bool get enableBackgroundTracking => _enableBackgroundTracking;
  bool get isInitialized => _initialized;

  // Derived getters
  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Color get primaryColor => Color(_themeColor);

  String get distanceUnit => _useImperialUnits ? 'mi' : 'km';
  String get weightUnit => _useImperialUnits ? 'lbs' : 'kg';
  String get heightUnit => _useImperialUnits ? 'ft' : 'cm';
  String get paceUnit => _useImperialUnits ? 'min/mi' : 'min/km';
  String get speedUnit => _useImperialUnits ? 'mph' : 'km/h';

  // Constructor
  SettingsProvider() {
    // Only call initialize if being created in main
    // otherwise just wait for explicit initialize call
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (!_initialized) {
      await _loadSettings();
    }
    return;
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme settings
      final darkMode = prefs.getBool(_keyDarkMode);
      if (darkMode != null) {
        _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }

      _themeColor = prefs.getInt(_keyThemeColor) ?? defaultThemeColor;

      // Load unit preferences
      _showMetricUnits =
          prefs.getBool(_keyShowMetricUnits) ?? defaultShowMetricUnits;
      _useImperialUnits =
          prefs.getBool(_keyUseImperialUnits) ?? defaultUseImperialUnits;

      // Load notification settings
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ??
          defaultNotificationsEnabled;

      // Load voice coaching settings
      _voiceCoachEnabled =
          prefs.getBool(_keyVoiceCoachEnabled) ?? defaultVoiceCoachEnabled;
      _voiceCoachVolume =
          prefs.getDouble(_keyVoiceCoachVolume) ?? defaultVoiceCoachVolume;
      _announceIntervals =
          prefs.getBool(_keyAnnounceIntervals) ?? defaultAnnounceIntervals;
      _announceProgress =
          prefs.getBool(_keyAnnounceProgress) ?? defaultAnnounceProgress;
      _announceMotivation =
          prefs.getBool(_keyAnnounceMotivation) ?? defaultAnnounceMotivation;
      _announceMilestones =
          prefs.getBool(_keyAnnounceMilestones) ?? defaultAnnounceMilestones;
      _progressAnnouncementFrequency =
          prefs.getString(_keyProgressAnnouncementFrequency) ??
              defaultProgressAnnouncementFrequency;

      // Load display settings
      _keepScreenOn = prefs.getBool(_keyKeepScreenOn) ?? defaultKeepScreenOn;

      // Load analytics settings
      _enableCrashReporting = prefs.getBool(_keyEnableCrashReporting) ??
          defaultEnableCrashReporting;
      _enableAnalytics =
          prefs.getBool(_keyEnableAnalytics) ?? defaultEnableAnalytics;

      // Load GPS settings
      _autoStartGps = prefs.getBool(_keyAutoStartGps) ?? defaultAutoStartGps;
      _backgroundTrackingMode = prefs.getString(_keyBackgroundTrackingMode) ??
          defaultBackgroundTrackingMode;

      // Load power settings
      _powerSavingMode =
          prefs.getBool(_keyPowerSavingMode) ?? defaultPowerSavingMode;

      // Load data backup settings
      _dataBackupFrequency = prefs.getString(_keyDataBackupFrequency) ??
          defaultDataBackupFrequency;

      // Load background tracking settings
      _enableBackgroundTracking = prefs.getBool(_keyEnableBackgroundTracking) ??
          defaultEnableBackgroundTracking;

      _initialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load settings', e, stackTrace);
    }
  }

  /// Save a setting to SharedPreferences
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save setting: $key', e, stackTrace);
    }
  }

  /// Set theme mode (light, dark, system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveSetting(_keyDarkMode, mode == ThemeMode.dark);
    notifyListeners();
  }

  /// Set theme color
  Future<void> setThemeColor(int color) async {
    if (_themeColor == color) return;

    _themeColor = color;
    await _saveSetting(_keyThemeColor, color);
    notifyListeners();
  }

  /// Set whether to show metric units
  Future<void> setShowMetricUnits(bool show) async {
    if (_showMetricUnits == show) return;

    _showMetricUnits = show;
    await _saveSetting(_keyShowMetricUnits, show);
    notifyListeners();
  }

  /// Set whether to use imperial units
  Future<void> setUseImperialUnits(bool use) async {
    if (_useImperialUnits == use) return;

    _useImperialUnits = use;
    await _saveSetting(_keyUseImperialUnits, use);
    notifyListeners();
  }

  /// Convert distance based on current unit preference
  double convertDistance(double distanceInKm) {
    return _useImperialUnits ? distanceInKm * 0.621371 : distanceInKm;
  }

  /// Convert weight based on current unit preference
  double convertWeight(double weightInKg) {
    return _useImperialUnits ? weightInKg * 2.20462 : weightInKg;
  }

  /// Get the current distance unit
  String getDistanceUnit() {
    return _useImperialUnits ? 'mi' : 'km';
  }

  /// Get the current weight unit
  String getWeightUnit() {
    return _useImperialUnits ? 'lbs' : 'kg';
  }

  /// Set whether to enable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;

    _notificationsEnabled = enabled;
    await _saveSetting(_keyNotificationsEnabled, enabled);
    notifyListeners();
  }

  /// Set whether to enable voice coaching
  Future<void> setVoiceCoachEnabled(bool enabled) async {
    if (_voiceCoachEnabled == enabled) return;

    _voiceCoachEnabled = enabled;
    await _saveSetting(_keyVoiceCoachEnabled, enabled);
    notifyListeners();
  }

  /// Set voice coach volume
  Future<void> setVoiceCoachVolume(double volume) async {
    if (_voiceCoachVolume == volume) return;

    _voiceCoachVolume = volume;
    await _saveSetting(_keyVoiceCoachVolume, volume);
    notifyListeners();
  }

  /// Set whether to announce intervals during workout
  Future<void> setAnnounceIntervals(bool announce) async {
    if (_announceIntervals == announce) return;

    _announceIntervals = announce;
    await _saveSetting(_keyAnnounceIntervals, announce);
    notifyListeners();
  }

  /// Set whether to announce progress during workout
  Future<void> setAnnounceProgress(bool announce) async {
    if (_announceProgress == announce) return;

    _announceProgress = announce;
    await _saveSetting(_keyAnnounceProgress, announce);
    notifyListeners();
  }

  /// Set whether to announce motivational messages
  Future<void> setAnnounceMotivation(bool announce) async {
    if (_announceMotivation == announce) return;

    _announceMotivation = announce;
    await _saveSetting(_keyAnnounceMotivation, announce);
    notifyListeners();
  }

  /// Set whether to announce milestones during workout
  Future<void> setAnnounceMilestones(bool announce) async {
    if (_announceMilestones == announce) return;

    _announceMilestones = announce;
    await _saveSetting(_keyAnnounceMilestones, announce);
    notifyListeners();
  }

  /// Set the frequency of progress announcements during workout
  Future<void> setProgressAnnouncementFrequency(String frequency) async {
    if (_progressAnnouncementFrequency == frequency) return;

    _progressAnnouncementFrequency = frequency;
    await _saveSetting(_keyProgressAnnouncementFrequency, frequency);
    notifyListeners();
  }

  /// Set whether to keep the screen on during workout
  Future<void> setKeepScreenOn(bool keep) async {
    if (_keepScreenOn == keep) return;

    _keepScreenOn = keep;
    await _saveSetting(_keyKeepScreenOn, keep);
    notifyListeners();
  }

  /// Set whether to enable crash reporting
  Future<void> setEnableCrashReporting(bool enable) async {
    if (_enableCrashReporting == enable) return;

    _enableCrashReporting = enable;
    await _saveSetting(_keyEnableCrashReporting, enable);
    notifyListeners();
  }

  /// Set whether to enable analytics
  Future<void> setEnableAnalytics(bool enable) async {
    if (_enableAnalytics == enable) return;

    _enableAnalytics = enable;
    await _saveSetting(_keyEnableAnalytics, enable);
    notifyListeners();
  }

  /// Set whether to auto-start GPS when opening the app
  Future<void> setAutoStartGps(bool autoStart) async {
    if (_autoStartGps == autoStart) return;

    _autoStartGps = autoStart;
    await _saveSetting(_keyAutoStartGps, autoStart);
    notifyListeners();
  }

  /// Set the background tracking mode (off, balanced, high-accuracy)
  Future<void> setBackgroundTrackingMode(String mode) async {
    if (_backgroundTrackingMode == mode) return;

    _backgroundTrackingMode = mode;
    await _saveSetting(_keyBackgroundTrackingMode, mode);
    notifyListeners();
  }

  /// Set whether to use power saving mode
  Future<void> setPowerSavingMode(bool enable) async {
    if (_powerSavingMode == enable) return;

    _powerSavingMode = enable;
    await _saveSetting(_keyPowerSavingMode, enable);
    notifyListeners();
  }

  /// Set the data backup frequency
  Future<void> setDataBackupFrequency(String frequency) async {
    if (_dataBackupFrequency == frequency) return;

    _dataBackupFrequency = frequency;
    await _saveSetting(_keyDataBackupFrequency, frequency);
    notifyListeners();
  }

  /// Set whether background tracking is enabled
  Future<void> setEnableBackgroundTracking(bool enable) async {
    if (_enableBackgroundTracking == enable) return;

    _enableBackgroundTracking = enable;
    await _saveSetting(_keyEnableBackgroundTracking, enable);
    notifyListeners();
  }

  /// Set property for enableBackgroundTracking
  set enableBackgroundTracking(bool value) {
    setEnableBackgroundTracking(value);
  }

  /// Reset all settings to default values
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all settings
      await prefs.remove(_keyDarkMode);
      await prefs.remove(_keyThemeColor);
      await prefs.remove(_keyShowMetricUnits);
      await prefs.remove(_keyNotificationsEnabled);
      await prefs.remove(_keyVoiceCoachEnabled);
      await prefs.remove(_keyVoiceCoachVolume);
      await prefs.remove(_keyAnnounceIntervals);
      await prefs.remove(_keyAnnounceProgress);
      await prefs.remove(_keyAnnounceMotivation);
      await prefs.remove(_keyAnnounceMilestones);
      await prefs.remove(_keyProgressAnnouncementFrequency);
      await prefs.remove(_keyKeepScreenOn);
      await prefs.remove(_keyEnableCrashReporting);
      await prefs.remove(_keyEnableAnalytics);
      await prefs.remove(_keyAutoStartGps);
      await prefs.remove(_keyBackgroundTrackingMode);
      await prefs.remove(_keyUseImperialUnits);
      await prefs.remove(_keyPowerSavingMode);
      await prefs.remove(_keyDataBackupFrequency);
      await prefs.remove(_keyEnableBackgroundTracking);

      // Reset to default values
      _themeMode = ThemeMode.system;
      _themeColor = defaultThemeColor;
      _showMetricUnits = defaultShowMetricUnits;
      _notificationsEnabled = defaultNotificationsEnabled;
      _voiceCoachEnabled = defaultVoiceCoachEnabled;
      _voiceCoachVolume = defaultVoiceCoachVolume;
      _announceIntervals = defaultAnnounceIntervals;
      _announceProgress = defaultAnnounceProgress;
      _announceMotivation = defaultAnnounceMotivation;
      _announceMilestones = defaultAnnounceMilestones;
      _progressAnnouncementFrequency = defaultProgressAnnouncementFrequency;
      _keepScreenOn = defaultKeepScreenOn;
      _enableCrashReporting = defaultEnableCrashReporting;
      _enableAnalytics = defaultEnableAnalytics;
      _autoStartGps = defaultAutoStartGps;
      _backgroundTrackingMode = defaultBackgroundTrackingMode;
      _useImperialUnits = defaultUseImperialUnits;
      _powerSavingMode = defaultPowerSavingMode;
      _dataBackupFrequency = defaultDataBackupFrequency;
      _enableBackgroundTracking = defaultEnableBackgroundTracking;

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reset settings to defaults', e, stackTrace);
    }
  }
}
