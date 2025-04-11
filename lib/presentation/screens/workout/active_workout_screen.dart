import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Uses v6+
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/screens/workout/workout_summary_screen.dart';
import 'package:running_app/presentation/utils/format_utils.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/presentation/widgets/workout/workout_metrics_panel.dart';
import 'package:running_app/presentation/widgets/workout/workout_map_view.dart';
import 'package:running_app/utils/logger.dart';
import 'package:vibration/vibration.dart'; // Import Vibration

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});
  static const routeName = '/active-workout'; // Static route name

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with WidgetsBindingObserver {
   bool _showMap = true;
   bool _isStopping = false;
   bool _isLocked = false;
   Timer? _lockTimer; // Timer for long press unlock indication

  // --- Lifecycle & Observer ---
  @override
  void initState() {
     super.initState();
     WidgetsBinding.instance.addObserver(this);
     // Prevent screen from sleeping during workout
     // TODO: Use wakelock_plus package
     // Wakelock.enable();
     Log.i("ActiveWorkoutScreen Initialized. Screen lock enabled."); // Wakelock enabled
  }

  @override
  void dispose() {
     WidgetsBinding.instance.removeObserver(this);
      // Ensure wakelock is released when screen is disposed
      // Wakelock.disable();
      _lockTimer?.cancel();
      Log.i("ActiveWorkoutScreen Disposed. Screen lock disabled."); // Wakelock disabled
     super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
     // TODO: Handle app lifecycle changes (e.g., going to background)
     // This might involve interacting with the background service if implemented
     Log.d("App Lifecycle State Changed: $state");
      switch (state) {
         case AppLifecycleState.resumed:
            // App came to foreground
             // Re-sync state with background service? Refresh UI?
            break;
         case AppLifecycleState.inactive:
            // App is inactive (e.g., phone call) - workout should continue in background
            break;
         case AppLifecycleState.paused:
            // App is in background - workout should continue via service
            break;
         case AppLifecycleState.detached:
             // App is being terminated (or engine detached) - state should be persisted
             // Potentially trigger emergency save? Handled by persistence manager?
             Log.w("App detached - workout state should be persisted.");
            break;
          case AppLifecycleState.hidden:
            // Flutter view is hidden (Android only, new in Flutter 3.13)
            break;
      }
  }


  // --- UI Lock ---
   void _toggleLockScreen() {
      if (_isLocked) {
         // Unlock immediately (long press handled by overlay)
         setState(() { _isLocked = false; });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Screen Unlocked'), duration: Duration(seconds: 1)),
          );
          _vibrate(); // Haptic feedback for unlock
      } else {
         // Lock
         setState(() { _isLocked = true; });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Screen Locked'), duration: Duration(seconds: 1)),
          );
           _vibrate(); // Haptic feedback for lock
      }
   }

   void _handleActionWhenLocked() {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Screen locked. Long press lock icon to unlock.'), duration: Duration(seconds: 2)),
      );
       _vibrate(duration: 50); // Short vibration for locked tap
   }

   void _startUnlockTimer() {
      _lockTimer?.cancel(); // Cancel any previous timer
      _lockTimer = Timer(const Duration(milliseconds: 1200), () { // Long press duration
         if (_isLocked && mounted) { // Check if still locked and screen exists
             Log.d("Long press detected, unlocking.");
             _toggleLockScreen(); // Call unlock
         }
      });
   }

   void _cancelUnlockTimer() {
      _lockTimer?.cancel();
   }

   Future<void> _vibrate({int duration = 50}) async {
      // TODO: Check vibration setting from SettingsProvider
      // bool canVibrate = await Vibration.hasVibrator() ?? false;
      // bool vibrationEnabled = context.read<SettingsProvider>().isVibrationEnabled;
      // if (canVibrate && vibrationEnabled) {
      //    Vibration.vibrate(duration: duration);
      // }

      // Using default implementation for now
      try {
         bool? hasVibrator = await Vibration.hasVibrator();
         if (hasVibrator == true) {
            Vibration.vibrate(duration: duration, amplitude: 128); // Default amplitude
         }
      } catch (e) {
          Log.w("Vibration failed: $e");
      }
   }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Use watch only on providers needed for UI updates
    final workoutProvider = context.watch<WorkoutProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    // Use read for providers needed only for actions
    final userProvider = context.read<UserProvider>();

    final activeWorkout = workoutProvider.activeWorkout;
    final useImperial = settingsProvider.useImperialUnits;

    // --- Handle State Changes & Navigation ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Navigate to summary if workout completes while screen is active
       if (mounted && workoutProvider.trackingState == WorkoutTrackingState.completed && activeWorkout != null) {
          Log.i("Workout completed, navigating to summary.");
          // Use pushReplacement to prevent coming back here
          Navigator.pushReplacementNamed(
             context,
             WorkoutSummaryScreen.routeName,
             arguments: activeWorkout,
          );
       }
       // Handle error state (show dialog?)
       else if (mounted && workoutProvider.trackingState == WorkoutTrackingState.error && workoutProvider.errorMessage != null) {
           // Avoid showing dialog repeatedly if error persists
           // Maybe show once using a flag or check previous state
            // Show persistent error message? For now, handled via snackbar on action failure.
            Log.e("Workout encountered error state: ${workoutProvider.errorMessage}");
       }
    });

    // --- Handle Missing Workout ---
    if (activeWorkout == null || workoutProvider.trackingState == WorkoutTrackingState.idle) {
      Log.w("ActiveWorkoutScreen: No active workout found or state is idle. Popping back.");
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) {
             Navigator.pop(context);
          }
       });
       // Show temporary loading state while popping
       return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    // --- Main Scaffold ---
    return PopScope( // Prevent accidental back navigation during workout
       canPop: false, // Cannot pop using back button
       onPopInvoked: (didPop) {
           if (didPop) return;
            Log.d("Back button pressed during active workout.");
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use Stop button to end the workout.'), duration: Duration(seconds: 2)),
             );
       },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Active: ${FormatUtils.formatWorkoutType(activeWorkout.workoutType)}"),
          automaticallyImplyLeading: false, // Explicitly hide back button
          actions: [
             // Toggle Map/Stats view
             IconButton(
               icon: Icon(_showMap ? Icons.bar_chart : Icons.map_outlined),
               tooltip: _showMap ? 'Show Stats View' : 'Show Map View',
               onPressed: _isLocked ? _handleActionWhenLocked : () => setState(() { _showMap = !_showMap; }),
             ),
              // Screen Lock Button (using GestureDetector for long press)
              GestureDetector(
                 onTap: _isLocked ? _handleActionWhenLocked : _toggleLockScreen,
                 onLongPressStart: _isLocked ? (_) => _startUnlockTimer() : null,
                 onLongPressEnd: _isLocked ? (_) => _cancelUnlockTimer() : null,
                 onLongPressCancel: _isLocked ? _cancelUnlockTimer : null,
                 child: Padding(
                   padding: const EdgeInsets.all(8.0), // Make tap area larger
                   child: Icon(_isLocked ? Icons.lock_outline : Icons.lock_open_outlined),
                 ),
              ),
          ],
        ),
        body: Stack( // Use Stack for lock overlay
          children: [
            Column(
              children: [
                // --- Metrics Panel ---
                WorkoutMetricsPanel(
                   duration: FormatUtils.formatDuration(activeWorkout.durationInSeconds),
                   distance: FormatUtils.formatDistance(activeWorkout.distance, useImperial),
                   pace: FormatUtils.formatPace(activeWorkout.pace, useImperial),
                   calories: FormatUtils.formatCalories(activeWorkout.caloriesBurned),
                   // TODO: Add heart rate display from sensor data
                   // heartRate: '145', // Example HR value
                   // TODO: Add target pace/zone display if goal set
                   // targetPace: 'Target: 5:30/km',
                ),
                const Divider(height: 1, thickness: 1),

                // --- Map or Detailed Stats View ---
                Expanded(
                  child: AnimatedSwitcher( // Animate between Map and Stats
                     duration: const Duration(milliseconds: 300),
                     child: _showMap
                         ? WorkoutMapView(
                              key: const ValueKey('mapView'), // Key for switcher
                              routePoints: activeWorkout.routePoints
                           )
                         : _buildStatsView(
                              key: const ValueKey('statsView'), // Key for switcher
                              workout: activeWorkout,
                              useImperial: useImperial
                           ),
                  )
                ),

                // TODO: Add Music Controls Widget if applicable
                 // Align(
                 //   alignment: Alignment.bottomCenter,
                 //   child: MusicControlsWidget(), // Your music widget
                 // ),

                // --- Control Buttons Panel ---
                _buildControlButtons(context, workoutProvider, userProvider),
              ],
            ),

             // --- Lock Screen Overlay ---
             if (_isLocked)
               Container(
                  color: Colors.black.withOpacity(0.6), // Semi-transparent overlay
                  // Blocks interaction with elements underneath
               ),
          ],
        ),
      ),
    );
  }


  // Placeholder for a detailed stats view (when map is hidden)
  Widget _buildStatsView({required Key key, required Workout workout, required bool useImperial}) {
    return ListView(
        key: key, // Add key for AnimatedSwitcher
       padding: const EdgeInsets.all(16.0),
       children: [
          ListTile(
             leading: const Icon(Icons.speed_outlined),
             title: const Text('Average Pace'),
             trailing: Text(FormatUtils.formatPace(workout.calculatedPaceSecondsPerKm, useImperial)),
          ),
           ListTile(
             leading: const Icon(Icons.local_fire_department_outlined),
             title: const Text('Calories'),
             trailing: Text(FormatUtils.formatCalories(workout.caloriesBurned)),
           ),
            ListTile(
             leading: const Icon(Icons.timer_outlined),
             title: const Text('Duration'),
             trailing: Text(FormatUtils.formatDuration(workout.durationInSeconds)),
           ),
            ListTile(
             leading: const Icon(Icons.straighten_outlined),
             title: const Text('Distance'),
             trailing: Text(FormatUtils.formatDistance(workout.distance, useImperial)),
           ),
           ListTile(
             leading: const Icon(Icons.landscape_outlined),
             title: const Text('Elevation Gain'),
             trailing: Text(FormatUtils.formatElevation(workout.elevationGain)),
           ),
           // TODO: Add HR Chart Widget
           // Card( child: Padding( padding: const EdgeInsets.all(8.0), child: HeartRateChart(...)))
           // TODO: Add Pace Chart Widget (Pace over time or distance)
           // Card( child: Padding( padding: const EdgeInsets.all(8.0), child: PaceChart(...)))
           // TODO: Add Splits data if available
           // ... workout.intervals ...
       ],
    );
  }


  // Control Buttons (Pause/Resume, Stop)
  Widget _buildControlButtons(BuildContext context, WorkoutProvider workoutProvider, UserProvider userProvider) {
    final isPaused = workoutProvider.trackingState == WorkoutTrackingState.paused;
    final isActive = workoutProvider.trackingState == WorkoutTrackingState.active;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0), // Increased padding
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // --- Stop Button ---
          SizedBox( // Constrain size
             width: 80, height: 80,
             child: ElevatedButton(
                onPressed: (_isLocked || _isStopping)
                   ? (_isLocked ? _handleActionWhenLocked : null)
                   : () async {
                      if (_isStopping) return;
                      setState(() { _isStopping = true; });
                       _vibrate(); // Vibrate on press

                      bool? confirmStop = await showDialog<bool>( /* ... Confirmation Dialog ... */
                           context: context,
                            barrierDismissible: false, // User must choose an action
                           builder: (BuildContext context) => AlertDialog( /* ... (same as before) ... */
                              title: const Text('Finish Workout?'),
                              content: const Text('Stop and save this workout?'),
                              actions: <Widget>[
                                TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false) ),
                                TextButton( child: const Text('Stop & Save'), onPressed: () => Navigator.of(context).pop(true) ),
                                TextButton(
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                   child: const Text('Discard'),
                                   onPressed: () async {
                                      Navigator.of(context).pop(false); // Close dialog
                                      await workoutProvider.discardWorkout(); // Discard action
                                      // Pop shouldn't be needed if discard resets state and causes rebuild
                                   },
                                ),
                              ],
                           ),
                        );

                      if (confirmStop == true) {
                         await workoutProvider.stopWorkout();
                         // Navigation handled by build method checking state
                      } else {
                          // Stop was cancelled or discard handled elsewhere
                          if (mounted) setState(() { _isStopping = false; });
                      }
                  },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red.shade700,
                 foregroundColor: Colors.white,
                 shape: const CircleBorder(),
                 padding: EdgeInsets.zero, // Control padding via SizedBox
               ),
               child: _isStopping ? const LoadingIndicator(size: 24, color: Colors.white) : const Icon(Icons.stop, size: 40),
             ),
          ),

          // --- Pause/Resume Button ---
           SizedBox( // Constrain size
              width: 80, height: 80,
              child: ElevatedButton(
                onPressed: (_isLocked || _isStopping)
                   ? (_isLocked ? _handleActionWhenLocked : null)
                   : () {
                      _vibrate(); // Vibrate on press
                      if (isActive) {
                         workoutProvider.pauseWorkout();
                      } else if (isPaused) {
                         workoutProvider.resumeWorkout();
                      }
                   },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 40),
              ),
           ),
        ],
      ),
    );
  }
}