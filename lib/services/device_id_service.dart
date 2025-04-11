import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To cache the ID
import 'package:uuid/uuid.dart'; // Using UUID as a more robust fallback/alternative

class DeviceIdService {
  static const _deviceIdKey = 'app_device_unique_id_v2'; // Key for storing generated UUID
  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    // --- Using a locally stored UUID is generally more reliable than platform IDs ---
    final prefs = await SharedPreferences.getInstance();
    String? storedUuid = prefs.getString(_deviceIdKey);

    if (storedUuid != null && storedUuid.isNotEmpty) {
      Log.d("Loaded Device ID (UUID) from cache: $storedUuid");
      _cachedDeviceId = storedUuid;
      return storedUuid;
    } else {
      // If no UUID stored, generate one and save it
      var uuid = const Uuid();
      String newUuid = uuid.v4();
      Log.i("Generated new Device ID (UUID): $newUuid");
      await prefs.setString(_deviceIdKey, newUuid);
      _cachedDeviceId = newUuid;
      return newUuid;
    }

    // --- Platform-specific ID logic (kept as alternative/reference) ---
    /*
    String? deviceId;
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        deviceId = 'web_placeholder_${DateTime.now().millisecondsSinceEpoch}';
        Log.w("Using unstable placeholder ID for web.");
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID (can change on factory reset)
        Log.i("Obtained Android ID: $deviceId");
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // identifierForVendor (can change on reinstall if no other apps from vendor)
        Log.i("Obtained iOS identifierForVendor: $deviceId");
      } else {
         deviceId = 'unknown_platform_${DateTime.now().millisecondsSinceEpoch}';
         Log.w("Unsupported platform for device ID.");
      }
    } catch (e, s) {
      Log.e("Failed to get platform device ID", error: e, stackTrace: s);
      deviceId = 'error_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

     if (deviceId == null || deviceId.isEmpty) {
        deviceId = 'fallback_generated_${DateTime.now().millisecondsSinceEpoch}';
         Log.w("Generated fallback device ID: $deviceId");
     }
     _cachedDeviceId = deviceId;
     return deviceId;
     */
  }
}