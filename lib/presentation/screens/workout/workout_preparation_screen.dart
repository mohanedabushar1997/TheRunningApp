import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/device/gps/location_service.dart'; // Import LocationService
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/providers/user_provider.dart';
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/screens/workout/active_workout_screen.dart';
import 'package:running_app/presentation/utils/format_utils.dart'; // For formatting workout type
import 'package:running_app/utils/logger.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart'; // For loading state

// Enum for GPS Status display
enum GpsStatus { unknown, searching, ready, error, disabled, permissionDenied }

class WorkoutPreparationScreen extends StatefulWidget {
  const WorkoutPreparationScreen({super.key});
  static const routeName = '/prepare-workout'; // Static route name

  @override
  State<WorkoutPreparationScreen> createState() => _WorkoutPreparationScreenState();
}

class _WorkoutPreparationScreenState extends State<WorkoutPreparationScreen> {
  WorkoutType _selectedWorkoutType = WorkoutType.run;
  bool _isStarting = false;
  GpsStatus _gpsStatus = GpsStatus.unknown;
  Timer? _gpsStatusTimer; // Timer to periodically check GPS status

  @override
  void initState() {
    super.initState();
     // Check GPS status immediately and then periodically
    _checkGpsStatus();
    _gpsStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkGpsStatus());
  }

  @override
  void dispose() {
    _gpsStatusTimer?.cancel(); // Cancel timer when screen is disposed
    super.dispose();
  }

  // --- GPS Status Check ---
  Future<void> _checkGpsStatus() async {
     if (!mounted) return; // Don't run if widget is disposed

     final locationService = context.read<LocationService>();
     GpsStatus currentStatus = GpsStatus.unknown;

     try {
        final serviceEnabled = await locationService.isLocationServiceEnabled();
        if (!serviceEnabled) {
           currentStatus = GpsStatus.disabled;
        } else {
           final hasPerm = await locationService.hasPermission();
           if (!hasPerm) {
              currentStatus = GpsStatus.permissionDenied;
           } else {
              // Attempt to get current position as readiness check
               setState(() { _gpsStatus = GpsStatus.searching; }); // Show searching while checking
               final position = await locationService.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.medium); // Medium accuracy check is faster
              if (position != null && (position.accuracy ?? 1000) < 100) { // Check if position valid and reasonably accurate
                  currentStatus = GpsStatus.ready;
              } else {
                  currentStatus = GpsStatus.searching; // Still searching or poor signal
              }
           }
        }
     } catch (e) {
        Log.e("Error checking GPS status: $e");
        currentStatus = GpsStatus.error;
     }

     if (mounted) { // Check again before setting state
        setState(() { _gpsStatus = currentStatus; });
     }
  }


  // --- Start Workout Logic ---
  Future<void> _startWorkout() async {
    if (_isStarting || _gpsStatus != GpsStatus.ready) {
        if (_gpsStatus != GpsStatus.ready) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(_getGpsErrorMessage()), backgroundColor: Colors.orange),
            );
        }
        return; // Don't start if already starting or GPS not ready
    }

    setState(() { _isStarting = true; });
    final workoutProvider = context.read<WorkoutProvider>();

    try {
      Log.i("Starting workout of type: $_selectedWorkoutType");
      // Start the workout using the provider (UserProvider implicitly provides deviceId)
      await workoutProvider.startWorkout(type: _selectedWorkoutType);

      // Navigate on success
      if (mounted && workoutProvider.trackingState == WorkoutTrackingState.active) {
        Navigator.pushReplacementNamed(context, ActiveWorkoutScreen.routeName);
      } else if (mounted) {
          // Handle potential errors during startWorkout
          final errorMsg = workoutProvider.errorMessage ?? "Unknown error starting workout.";
          Log.e("Start workout failed: $errorMsg");
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
          setState(() { _isStarting = false; }); // Reset button state on error
      }
    } catch (e, s) {
       Log.e("Exception during start workout navigation/call", error: e, stackTrace: s);
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
          setState(() { _isStarting = false; }); // Reset button state
       }
    }
    // Note: _isStarting doesn't need to be reset on success because the screen is replaced.
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepare Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center, // Align content center? Or top?
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Workout Type Selection ---
            Text('Select Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<WorkoutType>( // Use FormField for better integration/padding
              value: _selectedWorkoutType,
              decoration: const InputDecoration(
                 border: OutlineInputBorder(),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: WorkoutType.values.map((WorkoutType type) {
                return DropdownMenuItem<WorkoutType>(
                  value: type,
                  child: Row( // Add icon to dropdown item
                     children: [
                        Icon(_getWorkoutIcon(type), size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(FormatUtils.formatWorkoutType(type)),
                     ],
                  ),
                );
              }).toList(),
              onChanged: (WorkoutType? newValue) {
                if (newValue != null) {
                  setState(() { _selectedWorkoutType = newValue; });
                }
              },
            ),
            const SizedBox(height: 24),

            // --- GPS Status ---
            _buildGpsStatusIndicator(),
            const SizedBox(height: 24),

            // TODO: Add Target Goal Setting (Distance/Duration) Widget
            // ListTile(
            //    leading: Icon(Icons.flag_outlined),
            //    title: Text('Set Goal (Optional)'),
            //    subtitle: Text('Distance: None'), // Show current goal
            //    trailing: Icon(Icons.chevron_right),
            //    onTap: () { /* Open goal setting dialog/screen */ }
            // ),
            // const SizedBox(height: 16),

            // TODO: Add Shoe Selection Widget (if gear tracking implemented)
            // ListTile(
            //    leading: Icon(Icons.directions_run), // Placeholder icon
            //    title: Text('Select Shoes (Optional)'),
            //    subtitle: Text('Default Shoes'), // Show selected shoe
            //    trailing: Icon(Icons.chevron_right),
            //    onTap: () { /* Open shoe selection dialog/screen */ }
            // ),

            const Spacer(), // Pushes button to the bottom

            // --- Start Button ---
            ElevatedButton.icon(
              icon: _isStarting
                  ? const LoadingIndicator(size: 20, color: Colors.white)
                  : const Icon(Icons.play_arrow),
              label: Text(_isStarting ? 'Starting...' : 'Start'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: (_gpsStatus == GpsStatus.ready && !_isStarting)
                   ? Colors.green.shade700 // Green when ready
                   : Colors.grey, // Greyed out if not ready or starting
                foregroundColor: Colors.white,
              ),
              onPressed: _startWorkout,
            ),
            const SizedBox(height: 16), // Spacing at the bottom
          ],
        ),
      ),
    );
  }


  // --- Helper Widgets ---
  Widget _buildGpsStatusIndicator() {
    IconData icon;
    Color color;
    String text;

    switch (_gpsStatus) {
      case GpsStatus.ready:
        icon = Icons.gps_fixed;
        color = Colors.green.shade600;
        text = 'GPS Ready';
        break;
      case GpsStatus.searching:
         icon = Icons.gps_not_fixed;
         color = Colors.orange.shade600;
         text = 'Acquiring GPS...';
         break;
      case GpsStatus.permissionDenied:
         icon = Icons.gps_off;
         color = Colors.red.shade600;
         text = 'Location Permission Denied';
         break;
      case GpsStatus.disabled:
         icon = Icons.location_disabled;
         color = Colors.red.shade600;
         text = 'Location Services Disabled';
         break;
      case GpsStatus.error:
      case GpsStatus.unknown:
      default:
         icon = Icons.gps_off;
         color = Colors.grey.shade600;
         text = 'Checking GPS...';
         break;
    }

    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
       ),
       child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(icon, color: color, size: 20),
             const SizedBox(width: 10),
             Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
             // Add button to fix issue if possible
              if (_gpsStatus == GpsStatus.disabled || _gpsStatus == GpsStatus.permissionDenied) ...[
                 const Spacer(),
                 TextButton(
                    onPressed: () async {
                       if (_gpsStatus == GpsStatus.disabled) {
                          await context.read<LocationService>().openLocationSettings();
                       } else if (_gpsStatus == GpsStatus.permissionDenied) {
                           await context.read<LocationService>().openAppSettings();
                       }
                        await Future.delayed(const Duration(milliseconds: 500)); // Delay before re-checking
                        _checkGpsStatus(); // Re-check status after potentially opening settings
                    },
                    child: Text(_gpsStatus == GpsStatus.disabled ? 'Enable' : 'Settings'),
                 ),
              ]
          ],
       ),
    );
  }

  String _getGpsErrorMessage() {
     switch (_gpsStatus) {
       case GpsStatus.searching: return 'Waiting for better GPS signal...';
       case GpsStatus.permissionDenied: return 'Please grant location permission in settings.';
       case GpsStatus.disabled: return 'Please enable location services.';
       case GpsStatus.error: return 'Could not check GPS status. Try again.';
       case GpsStatus.unknown: return 'Checking GPS status...';
       case GpsStatus.ready: return ''; // Should not happen if button disabled
     }
  }

   IconData _getWorkoutIcon(WorkoutType type) {
     switch (type) {
       case WorkoutType.run: return Icons.directions_run;
       case WorkoutType.walk: return Icons.directions_walk;
       case WorkoutType.cycle: return Icons.directions_bike;
       case WorkoutType.treadmill: return Icons.fitness_center; // Example icon
       default: return Icons.run_circle_outlined;
     }
  }
}
This completes Batch 4. Let me know when you're ready for the next batch of 5 files (Batch 5).





proceed with the next batch, and tell me how many batches are left



Show thinking
Okay, proceeding with the next batch of 5 files.

Based on the previous batches, we are now providing files 31-35. After this batch, there will likely be around 3-4 more batches of 5 files each to cover the remaining screens, widgets, and service implementations.

Batch 5 of 10 Files