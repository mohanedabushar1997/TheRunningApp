import 'dart:async';
import 'dart:ui'; // For DartPluginRegistrant
import 'package:flutter/material.dart'; // For WidgetsFlutterBinding
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// Import services needed in the background isolate
import 'package:running_app/device/gps/location_service.dart';
import 'package:running_app/data/models/workout.dart'; // For workout data structure
import 'package:running_app/utils/logger.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart' as geo;
// TODO: Import other services/repositories if needed (e.g., to save intermediate points?)

// --- Configuration ---
const String notificationChannelId = 'running_app_background_service'; // Separate channel? Or use workout channel?
const int notificationId = 888; // Unique ID for the service notification

class BackgroundTrackingService {

  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static bool _isRunning = false;
  static StreamSubscription<geo.Position>? _bgPositionSubscription;
   // TODO: Store workout state (ID, start time etc.) needed for background tracking

  static bool get isRunning => _isRunning;

  // --- Initialization (Call from main.dart or based on user setting) ---
  static Future<void> initializeService() async {
    Log.i("Initializing Background Tracking Service...");

    // --- Configure the service ---
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // Entry point for background isolate
        autoStart: false, // Don't start automatically on boot
        isForegroundMode: true, // Crucial for location updates
        // Configure the persistent notification for the foreground service
        notificationChannelId: NotificationService.workoutChannelId, // Use same channel as workout progress?
        initialNotificationTitle: 'FitStride Tracking Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
         // notificationIcon: 'mipmap/ic_launcher', // Optional: Custom icon
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false, // Start manually
        onForeground: onStart, // Run logic when app is foreground
        onBackground: onIosBackground, // Optional: Specific logic for iOS background entry
      ),
    );
     Log.i("Background service configured.");
  }


  // --- Service Control ---
  static Future<void> start(Workout initialWorkout) async {
    if (_isRunning) {
       Log.w("Background service start called but already running.");
       return;
    }
    try {
       // Pass initial workout data to the background isolate
        final initialData = {
           'action': 'start',
           'workoutId': initialWorkout.id,
           'startTime': initialWorkout.date.millisecondsSinceEpoch,
           // TODO: Pass other relevant initial state if needed
        };
       await _service.startService();
       _service.invoke('setAsForeground'); // Ensure foreground status
       _service.invoke('updateNotification', {'title': 'FitStride Workout Active', 'content': 'Tracking your run...'});
        _service.invoke('startWorkoutTracking', initialData); // Send data to isolate
       _isRunning = true;
       Log.i("Background tracking service started.");
    } catch (e, s) {
       Log.e("Error starting background service", error: e, stackTrace: s);
    }
  }

  static Future<void> stop() async {
    if (!_isRunning) return;
    try {
        _service.invoke('stopWorkoutTracking'); // Tell isolate to stop tracking
        await _service.invoke("stopService"); // Stop the service itself
        _isRunning = false;
         _bgPositionSubscription?.cancel(); // Ensure subscription is cancelled
         _bgPositionSubscription = null;
        Log.i("Background tracking service stopped.");
    } catch (e, s) {
        Log.e("Error stopping background service", error: e, stackTrace: s);
    }
  }

   // --- Send commands/data TO the background service ---
   static void sendCommand(Map<String, dynamic> data) {
      if (!_isRunning) return;
       _service.invoke('command', data);
   }

   // --- Listen to data FROM the background service ---
   static Stream<Map<String, dynamic>?> onReceiveData() {
      return _service.on('update'); // Listen for 'update' events
   }

}


// --- Background Isolate Entry Point ---
// IMPORTANT: This function runs in a separate isolate.
// It cannot directly access variables or state from the main UI isolate.
// Communication happens via `service.invoke` and `service.on`.
@pragma('vm:entry-point') // Required for background execution
void onStart(ServiceInstance service) async {
  // Required for plugins in background isolate
  DartPluginRegistrant.ensureInitialized();
  // Required for path_provider and others if used in background
  WidgetsFlutterBinding.ensureInitialized();

  Log.initialize(level: kDebugMode ? Level.debug : Level.info, logToFile: false); // Initialize logger for background isolate (no file logging maybe?)
  Log.i("Background isolate started.");

  // State specific to this isolate
  LocationService? bgLocationService;
  StreamSubscription<geo.Position>? bgPositionSubscription;
  Timer? bgDurationTimer;
  Duration currentDuration = Duration.zero;
  // TODO: Store other background workout state (distance, points etc.)

  // --- Handle communication from the main isolate ---
  service.on('startWorkoutTracking').listen((data) {
     Log.i("Background received 'startWorkoutTracking': $data");
      // TODO: Initialize tracking based on received data
      // workoutId = data?['workoutId']; startTime = ... etc.
      currentDuration = Duration.zero; // Reset duration

      // Initialize location service specific to this isolate
      bgLocationService ??= GeolocatorLocationService();

      // Start location updates
      bgPositionSubscription?.cancel(); // Cancel previous if any
      bgPositionSubscription = bgLocationService?.getPositionStream().listen((position) {
          // TODO: Process position data in background
          // - Calculate distance delta, total distance
          // - Calculate pace
          // - Store route points (maybe send batches to main isolate or save directly?)
          // - Send updates back to the main isolate using service.invoke('update', {...})
          final updateData = {
             'latitude': position.latitude,
             'longitude': position.longitude,
             'speed': position.speed,
             'accuracy': position.accuracy,
             'timestamp': position.timestamp?.millisecondsSinceEpoch,
             // 'currentDistance': calculatedDistance, // Add calculated data
             // 'currentPace': calculatedPace,
          };
          service.invoke('update', updateData);
          // Update foreground notification periodically
           // service.invoke('updateNotification', {'content': 'Distance: X km, Pace: Y /km'});
       }, onError: (e, s) {
           Log.e("Background location error", error: e, stackTrace: s);
           service.invoke('update', {'error': 'GPS Error: $e'}); // Send error back
       });

      // Start duration timer
      bgDurationTimer?.cancel();
      bgDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
         currentDuration += const Duration(seconds: 1);
         // Send duration updates periodically
          if (currentDuration.inSeconds % 10 == 0) { // Example: every 10 seconds
             service.invoke('update', {'duration_seconds': currentDuration.inSeconds});
          }
      });

      Log.i("Background tracking started.");
  });

  service.on('stopWorkoutTracking').listen((data) {
      Log.i("Background received 'stopWorkoutTracking'");
      bgPositionSubscription?.cancel();
      bgPositionSubscription = null;
      bgDurationTimer?.cancel();
      bgDurationTimer = null;
      // TODO: Perform final calculations/saving if needed in background?
      Log.i("Background tracking stopped.");
  });

   service.on('command').listen((data) {
       Log.i("Background received command: $data");
       // TODO: Handle commands like pause, resume, maybe settings changes?
        final action = data?['action'];
        if (action == 'pause') {
            bgPositionSubscription?.pause();
            bgDurationTimer?.cancel(); // Stop timer while paused
             service.invoke('update', {'status': 'paused'});
             service.invoke('updateNotification', {'content': 'Workout Paused'});
        } else if (action == 'resume') {
             bgPositionSubscription?.resume();
             // Restart timer carefully based on last known duration
             // bgDurationTimer = Timer.periodic(...);
              service.invoke('update', {'status': 'active'});
              service.invoke('updateNotification', {'content': 'Tracking your run...'});
        }
   });


  // Inform the system that this service is ready
  await service.setForegroundNotificationInfo(
    title: "FitStride Service Ready",
    content: "Background tracking available.",
  );
  // Can call setForegroundNotificationInfo to update ongoing notification later
   service.invoke('updateNotification', {'title': 'FitStride Ready', 'content': 'Waiting for workout to start...'});


  // Keep the isolate alive
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    // Perform periodic tasks if needed (e.g., check service status, heartbeat)
     final isRunning = await service.isRunning();
     Log.v("Background isolate heartbeat. Service running: $isRunning");
     if (!isRunning) {
         timer.cancel(); // Stop heartbeat if service stops
         bgPositionSubscription?.cancel();
         bgDurationTimer?.cancel();
     }
  });
}

// Optional: Handle iOS background transition
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
   WidgetsFlutterBinding.ensureInitialized();
   DartPluginRegistrant.ensureInitialized();
   Log.w("App entering iOS background");
   // TODO: Configure background location updates specific to iOS if needed
   // e.g., using location package's background mode settings.
   return true; // Return true to keep service running
}