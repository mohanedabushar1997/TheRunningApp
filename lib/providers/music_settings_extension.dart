import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

/// Extension for SettingsProvider to handle music-related settings
extension MusicSettingsExtension on SettingsProvider {
  // Music settings
  bool get musicEnabled => _preferences?.getBool('music_enabled') ?? false;
  bool get lowerMusicVolumeForVoiceCoach => _preferences?.getBool('lower_music_volume_for_voice_coach') ?? true;
  bool get showMusicControlsDuringWorkout => _preferences?.getBool('show_music_controls_during_workout') ?? true;
  double get defaultMusicVolume => _preferences?.getDouble('default_music_volume') ?? 0.8;

  // Setters for music settings
  Future<void> setMusicEnabled(bool value) async {
    await _preferences?.setBool('music_enabled', value);
    notifyListeners();
  }

  Future<void> setLowerMusicVolumeForVoiceCoach(bool value) async {
    await _preferences?.setBool('lower_music_volume_for_voice_coach', value);
    notifyListeners();
  }

  Future<void> setShowMusicControlsDuringWorkout(bool value) async {
    await _preferences?.setBool('show_music_controls_during_workout', value);
    notifyListeners();
  }

  Future<void> setDefaultMusicVolume(double value) async {
    await _preferences?.setDouble('default_music_volume', value);
    notifyListeners();
  }
}
