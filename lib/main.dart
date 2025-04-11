import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // REMOVED
import 'package:provider/provider.dart';
import 'package:running_app/app.dart';
import 'package:running_app/data/repositories/tips_repository.dart';
import 'package:running_app/data/repositories/workout_repository.dart';
import 'package:running_app/data/sources/database_helper.dart';
import 'package:running_app/data/utils/state_persistence_manager.dart';
import 'package:running_app/device/audio/voice_coaching_service.dart';
import 'package:running_app/device/background/background_tracking_service.dart';
import 'package:running_app/device/gps/location_service.dart';
import 'package:running_app/device/notifications/notification_service.dart';
import 'package:running_app/domain/use_cases/workout_use_cases.dart';
// import 'package:running_app/presentation/providers/auth_provider.dart'; // REMOVED
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/tips_provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/services/device_id_service.dart';
import 'package:running_app/utils/logger.dart'; // Use custom logger
// import 'firebase_options.dart'; // REMOVED

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Logging (using logger package) ---
  Log.initialize(level: kDebugMode ? Level.debug : Level.info);
  Log.i("------------------------------------------");
  Log.i("Application Starting...");
  Log.i("Timestamp: ${DateTime.now()}");
  Log.i("------------------------------------------");

  // --- REMOVED Firebase Initialization ---

  // --- Initialize Services ---
  try {
    await NotificationService.initialize();
    Log.i("Notification Service Initialized.");
  } catch (e, s) {
    Log.e("Notification Service Initialization Failed", error: e, stackTrace: s);
  }

  // Initialize Background Service (if running continuously)
  // This needs careful setup and should only be called if background tracking is enabled
  // await BackgroundTrackingService.initializeService(); // Consider conditional init

  final voiceCoachService = VoiceCoachingService();
  // Initialize eagerly or lazily in provider/widget
  await voiceCoachService.initialize();
  Log.i("Voice Coaching Service Initialized.");

  final locationService = GeolocatorLocationService();
  final dbHelper = DatabaseHelper.instance;
  final deviceIdService = DeviceIdService();

  // --- Ensure Device ID is available ---
  String deviceId;
  try {
    deviceId = await deviceIdService.getDeviceId();
    Log.i("Using Device ID: $deviceId");
  } catch (e, s) {
    Log.e("CRITICAL: Failed to get Device ID", error: e, stackTrace: s);
    // Handle critical failure - maybe show an error screen or exit
    // For now, we proceed but UserProvider/WorkoutProvider might fail
    deviceId = "error_device_id";
  }

  // --- Initialize Repositories & Use Cases ---
  final workoutRepository = WorkoutRepository(dbHelper: dbHelper);
  final tipsRepository = TipsRepository(); // Consider loading from DB/Asset
  final workoutUseCases = WorkoutUseCases();
  final persistenceManager = SharedPreferencesStatePersistenceManager();

  runApp(
    MultiProvider(
      providers: [
        // --- Core Services ---
        Provider.value(value: deviceIdService),
        Provider.value(value: locationService),
        Provider.value(value: voiceCoachService),
        Provider.value(value: workoutUseCases),
        Provider.value(value: persistenceManager),
        Provider.value(value: dbHelper), // Provide DB Helper if needed elsewhere
        Provider.value(value: workoutRepository), // Provide Repositories
        Provider.value(value: tipsRepository),

        // --- Settings & User Profile ---
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()), // Load settings on init
        ChangeNotifierProvider( // UserProvider now only needs DB and DeviceIdService
           create: (context) => UserProvider(
               dbHelper: context.read<DatabaseHelper>(),
               deviceIdService: context.read<DeviceIdService>(),
            )..loadUserProfile(), // Load profile using device ID
        ),

        // --- Feature Providers ---
        ChangeNotifierProvider(
           create: (context) => TipsProvider(
               tipsRepository: context.read<TipsRepository>()
            )..fetchTipOfTheDay(), // Fetch initial tip
        ),
        ChangeNotifierProxyProvider<UserProvider, WorkoutProvider>(
           create: (context) => WorkoutProvider(
              workoutRepository: context.read<WorkoutRepository>(),
              locationService: context.read<LocationService>(),
              workoutUseCases: context.read<WorkoutUseCases>(),
              persistenceManager: context.read<StatePersistenceManager>(),
              userProvider: context.read<UserProvider>(),
           ),
           update: (_, userProvider, previous) => previous!..updateUserProvider(userProvider), // Update internal reference if needed
         ),
         // TODO: Add TrainingPlanProvider, AchievementProvider etc.
      ],
      child: const RunningApp(), // Your main App widget
    ),
  );
}