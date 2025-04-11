import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static const String notificationChannelId = 'running_app_channel';
  static const String notificationId = 'running_app_notification';
  static const int notificationIconId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Running App Service',
      description: 'Notifications for the running app tracking service',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configure background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Running App',
        initialNotificationContent: 'Ready to track your workout',
        foregroundServiceNotificationId: notificationIconId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // iOS background handler
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    // Keep app awake (wakelock functionality removed for compatibility)
    // We'd use another package or native implementation here in a real app
    return true;
  }

  // Service start handler
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    // Keep app awake (wakelock functionality removed for compatibility)
    // We'd use another package or native implementation here in a real app

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
      // Disable wake lock (functionality removed for compatibility)
    });

    // Start location tracking and update timer
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Update notification with latest tracking data
          final prefs = await SharedPreferences.getInstance();
          final distance = prefs.getDouble('current_distance') ?? 0;
          final duration = prefs.getInt('current_duration') ?? 0;

          service.setForegroundNotificationInfo(
            title: 'Running App Active',
            content:
                'Distance: ${formatDistance(distance)} | Time: ${formatDuration(duration)}',
          );
        }
      }

      // Send data to app UI
      service.invoke('update', {
        'current_time': DateTime.now().toIso8601String(),
      });
    });
  }

  // Start the background service
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  // Stop the background service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  // Update workout data to be displayed in the notification
  static Future<void> updateWorkoutData({
    required double distance,
    required int duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_distance', distance);
    await prefs.setInt('current_duration', duration);
  }

  // Formatting helpers
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
