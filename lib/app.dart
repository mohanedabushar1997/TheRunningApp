import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/screens/home/home_screen.dart';
import 'package:running_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:running_app/presentation/screens/profile/profile_screen.dart';
import 'package:running_app/presentation/screens/settings/app_settings_screen.dart';
import 'package:running_app/presentation/screens/settings/data_management_screen.dart';
import 'package:running_app/presentation/screens/settings/gps_settings_screen.dart';
import 'package:running_app/presentation/screens/settings/notification_settings_screen.dart';
import 'package:running_app/presentation/screens/splash_screen.dart';
import 'package:running_app/presentation/screens/tips/tips_list_screen.dart';
import 'package:running_app/presentation/screens/workout/active_workout_screen.dart';
import 'package:running_app/presentation/screens/workout/workout_preparation_screen.dart';
import 'package:running_app/presentation/screens/workout/workout_summary_screen.dart';
import 'package:running_app/presentation/theme/app_theme.dart';
import 'package:running_app/utils/logger.dart'; // Use custom logger
import 'package:running_app/data/models/workout.dart'; // For WorkoutSummaryScreen argument type

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'FitStride', // App name
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      debugShowCheckedModeBanner: false,

      // --- Routing ---
      initialRoute: AppStartWrapper.routeName, // Start with the wrapper
      routes: {
         AppStartWrapper.routeName: (context) => const AppStartWrapper(),
         SplashScreen.routeName: (context) => const SplashScreen(), // Optional explicit splash route
         OnboardingScreen.routeName: (context) => const OnboardingScreen(),
         HomeScreen.routeName: (context) => const HomeScreen(),
         AppSettingsScreen.routeName: (context) => const AppSettingsScreen(),
         GpsSettingsScreen.routeName: (context) => const GpsSettingsScreen(),
         NotificationSettingsScreen.routeName: (context) => const NotificationSettingsScreen(),
         DataManagementScreen.routeName: (context) => const DataManagementScreen(),
         TipsListScreen.routeName: (context) => const TipsListScreen(),
         ProfileScreen.routeName: (context) => const ProfileScreen(),
         // Workout related screens (can also be pushed directly without named routes)
          WorkoutPreparationScreen.routeName: (context) => const WorkoutPreparationScreen(),
          ActiveWorkoutScreen.routeName: (context) => const ActiveWorkoutScreen(),
         // WorkoutSummaryScreen needs argument, handle in onGenerateRoute
         // Add other routes...
      },
       onGenerateRoute: (settings) {
         Log.d("Navigating via onGenerateRoute: ${settings.name}");
         // Handle routes that need arguments
         if (settings.name == WorkoutSummaryScreen.routeName) {
            final workout = settings.arguments as Workout?;
            if (workout != null) {
               return MaterialPageRoute(
                  builder: (context) => WorkoutSummaryScreen(workout: workout),
               );
            } else {
                // Handle error: argument missing
                 Log.e("WorkoutSummaryScreen requires a Workout argument, but none provided.");
                 return MaterialPageRoute(builder: (context) => const ErrorScreen(message: "Workout data missing.")); // Example error screen
            }
         }
         // Handle TipDetailScreen argument
         if (settings.name == TipDetailScreen.routeName) {
            // ... similar argument handling ...
         }
         // Handle other dynamic routes...
         return null; // Let onUnknownRoute handle it if not defined
       },
       onUnknownRoute: (settings) {
         Log.e("Unknown route: ${settings.name}");
         return MaterialPageRoute(builder: (context) => const ErrorScreen(message: "Page not found")); // Example error screen
       },
    );
  }
}


// Wrapper Widget to decide initial screen
class AppStartWrapper extends StatelessWidget {
  const AppStartWrapper({super.key});
  static const routeName = '/'; // Initial route

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Use a FutureBuilder to wait for settings to load initially
    return FutureBuilder(
      // Assuming loadSettings returns a Future<void> and updates notifyListeners
      // If loadSettings isn't async, this FutureBuilder might not be necessary
      future: settingsProvider.ensureSettingsLoaded(), // Add this method to SettingsProvider
      builder: (context, settingsSnapshot) {
        // Also check if UserProvider is done loading the profile/device ID
        final userLoading = userProvider.isLoading;
        final settingsLoading = settingsSnapshot.connectionState != ConnectionState.done;

        Log.d("AppStartWrapper: UserLoading=$userLoading, SettingsLoading=$settingsLoading, OnboardingComplete=${settingsProvider.isOnboardingComplete}");

        if (userLoading || settingsLoading) {
          // Show splash screen while loading profile OR settings
          return const SplashScreen();
        } else {
          // Profile and Settings loaded
          if (!settingsProvider.isOnboardingComplete) {
            Log.i("AppStartWrapper: Navigating to OnboardingScreen.");
            // Use pushReplacement to prevent going back to splash/wrapper
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (ModalRoute.of(context)?.settings.name == AppStartWrapper.routeName) { // Avoid multiple pushes
                  Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
               }
            });
            return const SplashScreen(); // Show splash briefly while navigating
          } else {
            Log.i("AppStartWrapper: Navigating to HomeScreen.");
             // Use pushReplacement
             WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.settings.name == AppStartWrapper.routeName) {
                   Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                }
             });
            return const SplashScreen(); // Show splash briefly while navigating
          }
        }
      },
    );
  }
}


// Simple Error Screen Placeholder
class ErrorScreen extends StatelessWidget {
   final String message;
   const ErrorScreen({super.key, required this.message});

   @override
   Widget build(BuildContext context) {
      return Scaffold(
         appBar: AppBar(title: const Text("Error")),
         body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
         ),
      );
   }
}


// HomeScreen needs a static routeName
extension HomeScreenRoute on HomeScreen {
   static const routeName = '/home';
}
// Add similar extensions for other screens used in named routes if needed
extension OnboardingScreenRoute on OnboardingScreen {
   static const routeName = '/onboarding';
}
extension WorkoutPreparationScreenRoute on WorkoutPreparationScreen {
   static const routeName = '/prepare-workout';
}
extension ActiveWorkoutScreenRoute on ActiveWorkoutScreen {
   static const routeName = '/active-workout';
}
// WorkoutSummaryScreen already has routeName
// ProfileScreen needs routeName
extension ProfileScreenRoute on ProfileScreen {
   static const routeName = '/profile';
}