import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SharedPrefsHelper {
  static const String deviceIdKey = 'device_id';
  static const String themeKey = 'theme_mode';
  static const String unitsKey = 'units';
  static const String firstLaunchKey = 'first_launch';

  /// Get the device ID or generate a new one if it doesn't exist
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Get the current theme mode (light, dark, system)
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(themeKey) ?? 'system';
  }

  /// Set the theme mode
  static Future<bool> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(themeKey, mode);
  }

  /// Get measurement units (metric or imperial)
  static Future<String> getUnits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(unitsKey) ?? 'metric';
  }

  /// Set measurement units
  static Future<bool> setUnits(String units) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(unitsKey, units);
  }

  /// Check if this is the first launch of the app
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirst = prefs.getBool(firstLaunchKey) ?? true;

    if (isFirst) {
      await prefs.setBool(firstLaunchKey, false);
    }

    return isFirst;
  }

  /// Reset first launch status (for testing)
  static Future<bool> resetFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(firstLaunchKey, true);
  }

  /// Clear all stored data
  static Future<bool> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
