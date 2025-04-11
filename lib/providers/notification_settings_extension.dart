import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

/// A class to extend SettingsProvider with notification-specific settings
extension NotificationSettingsExtension on SettingsProvider {
  // Notification settings
  bool get notificationsEnabled => _preferences?.getBool('notifications_enabled') ?? false;
  bool get showWorkoutCompletionNotifications => _preferences?.getBool('show_workout_completion_notifications') ?? true;
  bool get showAchievementNotifications => _preferences?.getBool('show_achievement_notifications') ?? true;
  bool get showStreakNotifications => _preferences?.getBool('show_streak_notifications') ?? true;
  bool get showWeightGoalNotifications => _preferences?.getBool('show_weight_goal_notifications') ?? true;
  int get progressAnnouncementFrequency => _preferences?.getInt('progress_announcement_frequency') ?? 5;

  // Setters for notification settings
  Future<void> setNotificationsEnabled(bool value) async {
    await _preferences?.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setShowWorkoutCompletionNotifications(bool value) async {
    await _preferences?.setBool('show_workout_completion_notifications', value);
    notifyListeners();
  }

  Future<void> setShowAchievementNotifications(bool value) async {
    await _preferences?.setBool('show_achievement_notifications', value);
    notifyListeners();
  }

  Future<void> setShowStreakNotifications(bool value) async {
    await _preferences?.setBool('show_streak_notifications', value);
    notifyListeners();
  }

  Future<void> setShowWeightGoalNotifications(bool value) async {
    await _preferences?.setBool('show_weight_goal_notifications', value);
    notifyListeners();
  }
}
