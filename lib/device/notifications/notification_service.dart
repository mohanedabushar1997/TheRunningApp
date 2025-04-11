import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart'; // For TargetPlatform, Icons
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph; // Use alias
import 'package:running_app/data/models/running_tip.dart'; // For tip payload
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/utils/logger.dart';
import 'package:timezone/data/latest_all.dart'
    as tz; // Use latest_all for broader timezone support
import 'package:timezone/timezone.dart' as tz;

// --- Notification Actions ---
// Define IDs for notification actions (Android requires these)
const String pauseActionId = 'pause_workout_action';
const String resumeActionId = 'resume_workout_action';
const String stopActionId = 'stop_workout_action';
const String viewActionId = 'view_details_action';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel details
  static const String _workoutChannelId = 'workout_channel';
  static const String _workoutChannelName = 'Workout Status';
  static const String _workoutChannelDesc =
      'Ongoing workout progress and completion alerts.';
  static const String _generalChannelId = 'general_channel';
  static const String _generalChannelName = 'General Notifications';
  static const String _generalChannelDesc =
      'Tips, reminders, achievements, and app updates.';

  // Notification IDs (Use distinct IDs)
  static const int _workoutProgressId = 1001;
  static const int _workoutCompleteId = 1002;
  static const int _milestoneId = 2001;
  static const int _tipOfTheDayId = 3001;
  static const int _reminderIdBase = 4000; // Base ID for reminders
  static const int _warningIdBase = 5000; // Base ID for warnings (GPS, Battery)

  // Navigation Handling (Requires setup in main.dart/App widget)
  static GlobalKey<NavigatorState>? navigatorKey; // Assign in main.dart

  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey; // Store navigator key
    Log.i("Initializing Notification Service...");

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      // Set local timezone (optional but recommended for scheduling)
      // String timeZoneName = await FlutterNativeTimezone.getLocalTimezone(); // Requires flutter_native_timezone package
      // tz.setLocalLocation(tz.getLocation(timeZoneName));
      tz.setLocalLocation(tz.getLocation(
          'Asia/Dubai')); // Set default/local timezone - Using context location
      Log.i("Timezone database initialized. Local Location: ${tz.local.name}");
    } catch (e, s) {
      Log.e("Error initializing timezone database", error: e, stackTrace: s);
    }

    // --- Permissions ---
    await _requestPermissions();

    // --- Initialization Settings ---
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Ensure this icon exists

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission:
          false, // Request permissions separately/explicitly
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      // Define notification categories for actions (iOS 10+)
      notificationCategories: _getDarwinNotificationCategories(),
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // --- Initialize Plugin ---
    bool? initialized = await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
    Log.i("FlutterLocalNotificationsPlugin initialized: $initialized");

    // --- Create Android Notification Channels ---
    await _createNotificationChannels();

    Log.i("Notification Service Initialized Successfully.");
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ Notification Permission
      ph.PermissionStatus status = await ph.Permission.notification.request();
      Log.i("Android Notification Permission Status: $status");
      if (status.isPermanentlyDenied) {
        Log.w(
            "Notification permission permanently denied. User needs to enable in settings.");
        // Consider guiding user to settings here or elsewhere
      }
      // TODO: Consider requesting SCHEDULE_EXACT_ALARM permission if needed for precise scheduling on Android 12+
      // Requires <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" /> in Manifest
      // status = await ph.Permission.scheduleExactAlarm.request();
      // Log.i("Android Schedule Exact Alarm Permission Status: $status");
    } else if (Platform.isIOS) {
      // Request standard iOS notification permissions
      bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      Log.i("iOS Notification Permissions Granted: $granted");
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Workout Channel (High Importance for Foreground Service)
    const AndroidNotificationChannel workoutChannel =
        AndroidNotificationChannel(
      _workoutChannelId,
      _workoutChannelName,
      description: _workoutChannelDesc,
      importance: Importance
          .high, // High importance for foreground service/ongoing task
      playSound: false, // Typically ongoing notifications are silent
      enableVibration: false,
      // Consider channel group if organizing multiple workout-related channels
      // groupId: 'workout_group',
    );
    // General Channel (Default Importance)
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDesc,
      importance: Importance
          .defaultImportance, // Standard importance for tips, reminders etc.
      playSound: true,
      enableVibration: true,
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional custom sound
    );

    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(workoutChannel);
    await plugin?.createNotificationChannel(generalChannel);
    Log.i("Android notification channels created/updated.");
  }

  // Define action categories for iOS
  static List<DarwinNotificationCategory> _getDarwinNotificationCategories() {
    return [
      DarwinNotificationCategory(
        'workout_actions', // Category identifier
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(pauseActionId, 'Pause'),
          DarwinNotificationAction.plain(resumeActionId, 'Resume', options: {
            DarwinNotificationActionOption.foreground
          }), // Resume might need app foreground
          DarwinNotificationAction.plain(stopActionId, 'Stop', options: {
            DarwinNotificationActionOption.destructive,
            DarwinNotificationActionOption.foreground
          }),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.allowAnnouncement,
        },
      ),
      DarwinNotificationCategory(
        'general_actions',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(viewActionId, 'View Details',
              options: {DarwinNotificationActionOption.foreground}),
        ],
      ),
    ];
  }

  // --- Notification Action Handlers ---
  static void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    // Handler for foreground notifications (older iOS versions only)
    Log.i(
        'Foreground notification received (iOS old): id=$id, title=$title, payload=$payload');
    // Typically show an in-app message or ignore if handled by onDidReceiveNotificationResponse
  }

  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    Log.i(
        'Notification tapped: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}');
    _handleNotificationInteraction(response.payload, response.actionId);
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
      NotificationResponse response) {
    Log.i(
        'Background notification tapped: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}');
    // TODO: Handle background taps. Limited capabilities.
    // Might involve:
    // - Storing data in SharedPreferences.
    // - Triggering a background task (WorkManager/BackgroundFetch).
    // - Sending data to the main isolate if running via Background Service.
    _handleNotificationInteraction(
        response.payload,
        response
            .actionId); // Attempt same handling, might fail if app context needed
  }

  // Central handler for interaction logic
  static void _handleNotificationInteraction(
      String? payload, String? actionId) {
    if (payload == null && actionId == null) return;

    // --- Handle Actions ---
    if (actionId != null) {
      Log.i("Handling action: $actionId");
      // TODO: Communicate action to WorkoutProvider or Background Service
      // Example: Use a Stream, MethodChannel, or Background Service communication
      // BackgroundTrackingService.sendCommand({'action': actionId});
      if (actionId == pauseActionId) {
        /* Send pause command */
      } else if (actionId == resumeActionId) {
        /* Send resume command */
      } else if (actionId == stopActionId) {/* Send stop command */}
      return; // Usually don't navigate when an action is tapped, unless action requires it
    }

    // --- Handle Payload (Notification Body Tap) ---
    if (payload != null) {
      Log.i("Handling payload: $payload");
      try {
        Uri uri = Uri.parse(payload); // Use URI-based payloads for navigation
        String? targetScreen = uri.path; // e.g., /workoutSummary, /tipDetail
        String? id = uri.queryParameters['id']; // e.g., workoutId, tipId

        Log.d("Parsed Payload: Screen=$targetScreen, ID=$id");

        // Use Navigator Key to navigate
        if (navigatorKey?.currentState != null) {
          if (targetScreen == WorkoutSummaryScreen.routeName && id != null) {
            // TODO: Fetch workout details using ID before navigating if needed
            // Workout workout = await workoutRepo.getById(id);
            // navigatorKey!.currentState!.pushNamed(targetScreen, arguments: workout);
            Log.w(
                "Navigating to WorkoutSummary: Fetching workout by ID not implemented in notification handler.");
          } else if (targetScreen == TipDetailScreen.routeName && id != null) {
            // TODO: Fetch tip by ID
            // RunningTip tip = await tipsRepo.getById(id);
            // navigatorKey!.currentState!.pushNamed(targetScreen, arguments: tip);
            Log.w(
                "Navigating to TipDetail: Fetching tip by ID not implemented in notification handler.");
          } else if (targetScreen == TipsListScreen.routeName) {
            navigatorKey!.currentState!.pushNamed(TipsListScreen.routeName);
          } else {
            Log.w("Unknown navigation target in payload: $targetScreen");
            // Fallback: Navigate home?
            navigatorKey!.currentState!.popUntil((route) => route.isFirst);
          }
        } else {
          Log.e(
              "Cannot handle payload navigation: NavigatorKey is null or has no state.");
        }
      } catch (e, s) {
        Log.e("Error parsing or handling notification payload '$payload'",
            error: e, stackTrace: s);
      }
    }
  }

  // --- Platform Specific Details ---
  static NotificationDetails _getNotificationDetails(String channelId,
      {Importance importance = Importance.defaultImportance,
      Priority priority = Priority.defaultPriority,
      bool ongoing = false,
      bool autoCancel = true,
      List<AndroidNotificationAction>? androidActions,
      String? darwinCategory}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId), // Helper to get name from ID
        channelDescription: _getChannelDescription(channelId),
        importance: importance,
        priority: priority,
        ongoing: ongoing,
        autoCancel: autoCancel,
        actions: androidActions,
        // TODO: Add other Android specifics like style, progress, icons
        // styleInformation: BigTextStyleInformation(...)
        // showProgress: true, maxProgress: 100, progress: 50,
        // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Requires bitmap conversion
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true, // Show alert when app is foreground for non-ongoing
        presentSound: !ongoing &&
            importance > Importance.low, // Sound for important, non-ongoing
        presentBadge: true, // Allow updating badge
        categoryId: darwinCategory, // Link to defined categories for actions
        // subtitle: 'Optional Subtitle',
        // sound: 'custom_sound.aiff', // Optional custom sound
      ),
    );
  }

  // Helper functions for channel details (avoids repeating strings)
  static String _getChannelName(String channelId) =>
      channelId == _workoutChannelId
          ? _workoutChannelName
          : _generalChannelName;
  static String _getChannelDescription(String channelId) =>
      channelId == _workoutChannelId
          ? _workoutChannelDesc
          : _generalChannelDesc;

  // --- Show Specific Notifications ---

  /// Shows/Updates the ongoing workout progress notification.
  Future<void> showWorkoutProgressNotification(
      String statusText, String progressDetails,
      {bool isPaused = false}) async {
    // Define Android actions based on paused state
    List<AndroidNotificationAction> androidActions = [
      isPaused
          ? const AndroidNotificationAction(resumeActionId, 'Resume',
              showsUserInterface: true) // Might need UI
          : const AndroidNotificationAction(pauseActionId, 'Pause'),
      const AndroidNotificationAction(stopActionId, 'Stop',
          showsUserInterface: true,
          cancelNotification: true), // destructive, needs UI
    ];

    final details = _getNotificationDetails(
      _workoutChannelId,
      importance: Importance.low, // Keep low to be less intrusive
      priority: Priority.low,
      ongoing: true, // Non-dismissible
      autoCancel: false,
      androidActions: androidActions,
      darwinCategory: 'workout_actions', // Use category with actions for iOS
    );

    await _notificationsPlugin.show(
      _workoutProgressId,
      statusText, // e.g., "Running - 5.2 km"
      progressDetails, // e.g., "Duration: 31:10 | Pace: 6:00/km"
      details,
      payload: Uri(path: ActiveWorkoutScreen.routeName)
          .toString(), // Tap to open active workout screen
    );
    Log.v('Showing/Updating workout progress notification: $statusText');
  }

  Future<void> cancelWorkoutProgressNotification() async {
    await _notificationsPlugin.cancel(_workoutProgressId);
    Log.d('Cancelled workout progress notification');
  }

  Future<void> showWorkoutCompleteNotification(Workout workout) async {
    final details = _getNotificationDetails(
      _generalChannelId, // Use general channel for completion alert
      importance: Importance.high,
      priority: Priority.high,
      darwinCategory: 'general_actions', // e.g., with 'View Details' action
    );

    // Simple formatting for notification body
    String distanceStr = FormatUtils.formatDistance(
        workout.distance, false); // Use settings provider eventually
    String durationStr = FormatUtils.formatDuration(workout.durationInSeconds);

    await _notificationsPlugin.show(
      _workoutCompleteId,
      'Workout Complete!',
      '${FormatUtils.formatWorkoutType(workout.workoutType)}: $distanceStr in $durationStr. Well done!',
      details,
      // Payload includes screen and workout ID
      payload: Uri(
          path: WorkoutSummaryScreen.routeName,
          queryParameters: {'id': workout.id}).toString(),
    );
    Log.i(
        'Showing workout complete notification for workout ID: ${workout.id}');
  }

  Future<void> showMilestoneNotification(String title, String body) async {
    final details = _getNotificationDetails(
      _generalChannelId,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      _milestoneId +
          DateTime.now()
              .second, // Use varying ID to ensure it shows if triggered quickly
      title, body, details,
      payload: Uri(path: '/achievements')
          .toString(), // Navigate to achievements screen
    );
    Log.i('Showing milestone notification: $title');
  }

  Future<void> showTipNotification(RunningTip tip) async {
    final details = _getNotificationDetails(
      _generalChannelId,
      importance: Importance.defaultImportance,
    );
    await _notificationsPlugin.show(
      _tipOfTheDayId, // Use fixed ID, will replace previous day's tip
      "Daily Running Tip: ${tip.title}",
      tip.content, // Show full content? Or summary?
      details,
      payload:
          Uri(path: TipDetailScreen.routeName, queryParameters: {'id': tip.id})
              .toString(),
    );
    Log.i('Showing tip notification: ${tip.id}');
  }

  // --- Scheduling ---

  Future<void> scheduleDailyTipNotification(Time time, RunningTip tip) async {
    final details =
        _getNotificationDetails(_generalChannelId, importance: Importance.low);
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(time);

    try {
      await _notificationsPlugin.zonedSchedule(
        _tipOfTheDayId, // Use fixed ID to replace previous schedule
        "Daily Running Tip: ${tip.title}",
        "${tip.content.substring(0, min(tip.content.length, 100))}...", // Summary
        scheduledTime,
        details,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // Needs permission
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Match time daily
        payload: Uri(
            path: TipDetailScreen.routeName,
            queryParameters: {'id': tip.id}).toString(),
      );
      Log.i('Scheduled daily tip notification for $time. Next: $scheduledTime');
    } catch (e, s) {
      Log.e("Error scheduling daily tip", error: e, stackTrace: s);
    }
  }

  Future<void> cancelScheduledTip() async {
    await _notificationsPlugin.cancel(_tipOfTheDayId);
    Log.i("Cancelled scheduled daily tip notification.");
  }

  // TODO: Implement workout reminder scheduling
  // Future<void> scheduleWorkoutReminder(...) async { ... }

  // Helper to calculate next time occurrence in local timezone
  static tz.TZDateTime _nextInstanceOfTime(Time time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, time.hour, time.minute, time.second);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    // Handle potential DST changes - re-check after adding day? Usually okay for daily tasks.
    return scheduledDate;
  }

  // --- Warnings ---
  Future<void> showGpsSignalLostWarning() async {
    final details = _getNotificationDetails(_workoutChannelId,
        importance: Importance.high, priority: Priority.high);
    await _notificationsPlugin.show(
      _warningIdBase + 1, // Unique ID for GPS warning
      "GPS Signal Lost",
      "Tracking may be inaccurate. Trying to reacquire signal.",
      details,
      // payload: ... // Optionally navigate to GPS settings?
    );
    Log.w("Showing GPS signal lost warning notification.");
  }

  Future<void> showLowBatteryWarning(int batteryLevel) async {
    final details = _getNotificationDetails(_generalChannelId,
        importance: Importance.high, priority: Priority.high);
    await _notificationsPlugin.show(
      _warningIdBase + 2, // Unique ID for battery warning
      "Low Battery Warning",
      "Battery at $batteryLevel%. Workout tracking may stop soon.",
      details,
    );
    Log.w("Showing low battery warning notification.");
  }

  // --- Clearing Notifications ---
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    Log.i("Cancelled all notifications.");
  }
}
