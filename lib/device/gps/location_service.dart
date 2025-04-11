import 'dart:async';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart' as geo; // Use alias
import 'package:permission_handler/permission_handler.dart' as ph; // Use alias for permission_handler
import 'package:running_app/data/models/enhanced_location_data.dart'; // Keep if needed for conversion example
import 'package:running_app/data/models/location_data.dart';
import 'package:running_app/utils/logger.dart';
import 'package:running_app/device/gps/kalman_filter.dart'; // Import Kalman Filter

// Abstract interface
abstract class LocationService {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<bool> isLocationServiceEnabled();
  Future<geo.Position?> getCurrentPosition({geo.LocationAccuracy desiredAccuracy = geo.LocationAccuracy.high}); // Use geo.LocationAccuracy
  Stream<geo.Position> getPositionStream({geo.LocationSettings? locationSettings}); // Use geo.LocationSettings
  Future<geo.LocationAccuracyStatus> getLocationAccuracy(); // Use geo.LocationAccuracyStatus
  Future<bool> isReady();
  // Added methods for settings navigation
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
   // Method to allow updating settings externally (e.g., from SettingsProvider)
   void updateSettings({geo.LocationAccuracy? accuracy, int? distanceFilter});
}

// Implementation using Geolocator
class GeolocatorLocationService implements LocationService {

  geo.LocationAccuracy _currentAccuracy = geo.LocationAccuracy.high;
  int _currentDistanceFilter = 5; // Default 5 meters

  geo.LocationSettings? _androidSettings;
  geo.LocationSettings? _appleSettings;

  // Kalman Filter (Optional) - Simple 2D version now
  KalmanFilter2D? _kalmanFilter;

  GeolocatorLocationService() {
     _updatePlatformSettings(); // Initial setup
     // Initialize Kalman Filter if desired
      _kalmanFilter = KalmanFilter2D(processNoise: 0.1, measurementNoise: 10.0); // Example parameters
     Log.i("GeolocatorLocationService initialized.");
  }

  // Update internal settings and platform-specific settings objects
  @override
  void updateSettings({geo.LocationAccuracy? accuracy, int? distanceFilter}) {
     bool changed = false;
     if (accuracy != null && accuracy != _currentAccuracy) {
        _currentAccuracy = accuracy;
        changed = true;
        Log.i("Location accuracy setting updated to: $_currentAccuracy");
     }
      if (distanceFilter != null && distanceFilter >= 0 && distanceFilter != _currentDistanceFilter) {
         _currentDistanceFilter = distanceFilter;
         changed = true;
          Log.i("Location distance filter setting updated to: $_currentDistanceFilter meters");
      }
      if (changed) {
         _updatePlatformSettings(); // Rebuild platform settings objects
      }
  }


  void _updatePlatformSettings() {
    // Android specific settings
    _androidSettings = geo.AndroidSettings(
      accuracy: _currentAccuracy,
      distanceFilter: _currentDistanceFilter,
      // intervalDuration: const Duration(seconds: 1), // Shorter interval for faster updates
      foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
           notificationText: "Tracking your run in the background",
           notificationTitle: "FitStride Running",
           enableWakeLock: true,
           // Use default icon if specific one isn't set up correctly
            // notificationIcon: geo.AndroidResource(name: '@mipmap/ic_launcher', defType: 'mipmap'),
       )
    );

    // iOS/macOS specific settings
    _appleSettings = geo.AppleSettings(
      accuracy: _currentAccuracy,
      activityType: geo.ActivityType.fitness,
      distanceFilter: _currentDistanceFilter.toDouble(), // iOS uses double
      pauseAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
     Log.d("Platform location settings updated: Accuracy=$_currentAccuracy, Filter=$_currentDistanceFilter m");
  }

  geo.LocationSettings? get _platformSettings {
     // Ensure settings are always up-to-date based on current config
     // _updatePlatformSettings(); // Rebuild every time, or rely on updateSettings call? Rely on update call.

     if (kIsWeb) {
      return geo.LocationSettings(accuracy: _currentAccuracy, distanceFilter: _currentDistanceFilter);
    } else if (Platform.isAndroid) {
      return _androidSettings;
    } else if (Platform.isIOS || Platform.isMacOS) {
      return _appleSettings;
    }
    Log.w("Location settings requested for unsupported platform.");
    return null; // Default or unsupported platform
  }


  // --- Permission Handling (using permission_handler for consistency) ---

  @override
  Future<bool> requestPermission() async {
     Log.i("Requesting location permissions...");
     // Request "while in use" first
      ph.PermissionStatus status = await ph.Permission.locationWhenInUse.request();
      Log.d("Location 'While In Use' permission status: $status");

      if (status.isGranted) {
         // If background tracking is essential, request "always"
          // IMPORTANT: Requires careful justification for users and store review
          // Consider requesting this later, only when user enables background features.
          // ph.PermissionStatus bgStatus = await ph.Permission.locationAlways.request();
          // Log.d("Location 'Always' permission status: $bgStatus");
          // return bgStatus.isGranted; // Return true only if 'Always' is granted if required
          Log.i("Location 'While In Use' permission granted.");
          return true; // Granted 'while in use' is often sufficient
      } else if (status.isPermanentlyDenied || status.isRestricted) {
          Log.e("Location permission permanently denied or restricted. Opening settings...");
          await openAppSettings();
          return false;
      } else {
           Log.w("Location permission denied.");
           return false;
      }
  }

  @override
  Future<bool> hasPermission() async {
    // Check for 'while in use' or 'always'
     final status = await ph.Permission.locationWhenInUse.status;
     // final alwaysStatus = await ph.Permission.locationAlways.status; // Check if needed
     Log.d("Current location permission status: $status");
     return status.isGranted; // || alwaysStatus.isGranted;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
     final enabled = await ph.ServiceStatus.locationWhenInUse.isEnabled;
     Log.d("Location service enabled status: $enabled");
     return enabled;
  }

  @override
  Future<bool> isReady() async {
     final serviceEnabled = await isLocationServiceEnabled();
     if (!serviceEnabled) {
        Log.w("Location service is disabled.");
        return false;
     }
     final permissionGranted = await hasPermission();
     if (!permissionGranted) {
        Log.w("Location permission not granted.");
        return false;
     }
     return true;
  }

   // --- Opening Settings ---
   @override
   Future<bool> openAppSettings() {
      return ph.openAppSettings();
   }
   @override
   Future<bool> openLocationSettings() async {
      // Geolocator provides a specific method for location settings
       return await Geolocator.openLocationSettings();
   }


  // --- Position Retrieval ---

  @override
  Future<geo.Position?> getCurrentPosition({
    geo.LocationAccuracy desiredAccuracy = geo.LocationAccuracy.high // Allow override
  }) async {
    if (!await isLocationServiceEnabled()) {
       Log.w("Cannot get current position: Location service disabled.");
        // Optionally prompt user to enable
        // await openLocationSettings();
       return null;
    }
    if (!await hasPermission()) {
        Log.w("Cannot get current position: Permission denied.");
         // Optionally request permission
         // if (!await requestPermission()) return null;
        return null;
    }

    try {
       Log.d("Getting current position with accuracy: $desiredAccuracy");
       geo.Position position = await Geolocator.getCurrentPosition(
           desiredAccuracy: desiredAccuracy,
           timeLimit: const Duration(seconds: 15) // Increased timeout
        );
        Log.i("Current position obtained: (${position.latitude}, ${position.longitude}) Acc: ${position.accuracy}");
        return position;
    } catch (e, s) {
      Log.e("Error getting current position", error: e, stackTrace: s);
      return null;
    }
  }

  @override
  Stream<geo.Position> getPositionStream({geo.LocationSettings? locationSettings}) {
     final settings = locationSettings ?? _platformSettings;
     if (settings == null) {
        Log.e("Location settings not available for this platform.");
        return Stream.error(Exception("Location settings not available for this platform."));
     }

     Log.i("Starting position stream: Accuracy=${settings.accuracy}, Filter=${settings.distanceFilter}m");

     // Reset Kalman filter when stream starts
      _kalmanFilter?.reset();

     return Geolocator.getPositionStream(locationSettings: settings)
         .handleError((error, stackTrace) {
           Log.e("Error in position stream", error: error, stackTrace: stackTrace);
           // Let the error propagate, WorkoutProvider should handle UI/state changes
         })
         .map((position) {
             // Apply Kalman Filter if initialized
              if (_kalmanFilter != null) {
                 final filtered = _kalmanFilter!.filter(position);
                  // Log comparison for tuning
                  // Log.v("Kalman Filter: (${position.latitude}, ${position.longitude}) -> (${filtered.latitude}, ${filtered.longitude}) Acc: ${position.accuracy}");
                 return filtered;
              }
              return position;
          })
          .where((position) {
              // Apply post-filter accuracy check if needed, or trust filter's estimate
              bool isAccurateEnough = (position.accuracy ?? 1000.0) < (_currentAccuracy == geo.LocationAccuracy.low ? 150.0 : 75.0); // Dynamic threshold based on desired accuracy
              if (!isAccurateEnough) {
                 Log.v("Stream: Filtering potentially inaccurate point (Acc: ${position.accuracy})");
              }
              return isAccurateEnough; // Only emit points considered accurate enough
          });
  }

  // --- Accuracy & Status ---

  @override
  Future<geo.LocationAccuracyStatus> getLocationAccuracy() async {
     // Check readiness first
     if (!await isLocationServiceEnabled()) return geo.LocationAccuracyStatus.unknown;
     if (!await hasPermission()) return geo.LocationAccuracyStatus.denied;

     try {
        return await Geolocator.getLocationAccuracy();
     } catch (e, s) {
        Log.e("Error getting location accuracy status", error: e, stackTrace: s);
        return geo.LocationAccuracyStatus.unknown;
     }
  }
}

// Example Conversion Extension (if EnhancedLocationData model is used)
/*
extension PositionToEnhanced on geo.Position {
  EnhancedLocationData toEnhancedLocationData({required ActivityType activity}) {
    return EnhancedLocationData(
      latitude: latitude, longitude: longitude, altitude: altitude,
      speed: speed, accuracy: accuracy, heading: heading,
      timestamp: timestamp ?? DateTime.now(),
      activity: activity, // Pass the determined activity
      speedAccuracy: speedAccuracy, altitudeAccuracy: altitudeAccuracy,
      headingAccuracy: headingAccuracy, isMocked: isMocked,
    );
  }
}
*/