import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/data/models/workout.dart'; // For WorkoutType
import 'package:running_app/presentation/providers/workout_provider.dart';
import 'package:running_app/presentation/widgets/common/loading_indicator.dart';
import 'package:running_app/presentation/utils/format_utils.dart'; // For formatting time
import 'dart:async'; // For Timer

// TODO: Implement sensor integration (Pedometer, potentially others?)
// TODO: Implement manual distance/duration/speed controls

class TreadmillWorkoutScreen extends StatefulWidget {
  const TreadmillWorkoutScreen({super.key});
  static const routeName = '/workout/treadmill'; // Optional route name

  @override
  State<TreadmillWorkoutScreen> createState() => _TreadmillWorkoutScreenState();
}

class _TreadmillWorkoutScreenState extends State<TreadmillWorkoutScreen> {
  // --- State for manual tracking ---
  Duration _elapsedTime = Duration.zero;
  double _manualDistanceKm = 0.0; // Track distance manually entered
  double? _currentSpeedKph; // Optional: If treadmill reports speed
  Timer? _timer;
  bool _isRunning = false;
  bool _isSaving = false;

  // TODO: Integrate with Pedometer package for step count/cadence?
  // StreamSubscription<StepCount>? _stepCountSubscription;
  // int _stepCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    // _stepCountSubscription?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
     _timer?.cancel(); // Cancel existing timer
     setState(() { _isRunning = true; });
     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isRunning) {
           timer.cancel();
           return;
        }
        setState(() {
           _elapsedTime += const Duration(seconds: 1);
        });
     });
      // TODO: Start pedometer stream if using
  }

  void _pauseStopwatch() {
     setState(() { _isRunning = false; });
      _timer?.cancel();
       // TODO: Pause pedometer stream if using
  }

  void _resetStopwatch() {
     _timer?.cancel();
     setState(() {
        _isRunning = false;
        _elapsedTime = Duration.zero;
        _manualDistanceKm = 0.0;
        _currentSpeedKph = null;
        // _stepCount = 0;
     });
      // TODO: Reset pedometer stream if using
  }

  // --- TODO: Implement Manual Adjustment Dialogs ---
  Future<void> _adjustDistance() async {
     // Show dialog to enter/adjust distance manually
     // Update _manualDistanceKm state
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adjust distance TODO')));
  }
   Future<void> _adjustDuration() async {
      // Show dialog to enter/adjust duration manually
      // Update _elapsedTime state
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adjust duration TODO')));
   }

   // --- Save Workout ---
   Future<void> _saveWorkout() async {
      if (_elapsedTime == Duration.zero && _manualDistanceKm == 0.0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No workout data to save.')));
          return;
      }
      setState(() { _isSaving = true; });
       final workoutProvider = context.read<WorkoutProvider>();
       final userProvider = context.read<UserProvider>();

      // TODO: Create a Workout object from manual data
      final workout = Workout(
         id: const Uuid().v4(), // Use uuid package
         deviceId: userProvider.deviceId ?? '', // Get device ID
         date: DateTime.now().subtract(_elapsedTime), // Approx start time
         distance: _manualDistanceKm * 1000.0, // Convert km to meters
         duration: _elapsedTime,
         workoutType: WorkoutType.treadmill,
         status: WorkoutStatus.completed,
          // Calculate pace/calories if possible
          pace: (_manualDistanceKm > 0 && _elapsedTime.inSeconds > 0)
             ? _elapsedTime.inSeconds / _manualDistanceKm // sec/km
             : null,
          calories: context.read<WorkoutUseCases>().calculateCaloriesBurned(
              duration: _elapsedTime,
              userWeightKg: userProvider.userProfile?.weight ?? 70.0,
              metValue: context.read<WorkoutUseCases>().getMetValueForActivity(WorkoutType.treadmill)
           ),
           routePoints: [], // No route points for treadmill
      );

      try {
         await workoutProvider.saveManualWorkout(workout); // Add specific method in provider?
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treadmill workout saved!'), backgroundColor: Colors.green));
             _resetStopwatch(); // Reset after successful save
         }
      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
          }
      } finally {
         if (mounted) setState(() { _isSaving = false; });
      }

   }


  @override
  Widget build(BuildContext context) {
     final textTheme = Theme.of(context).textTheme;
     final displayTime = FormatUtils.formatDuration(_elapsedTime.inSeconds);
      // TODO: Format distance based on imperial/metric setting
      final displayDistance = _manualDistanceKm.toStringAsFixed(2) + " km";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treadmill Workout'),
      ),
      body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
              // --- Big Timer Display ---
              Text(
                 displayTime,
                 style: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 72),
                 textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

               // --- Distance Display ---
               Text(
                  displayDistance,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
               ),
               TextButton.icon( // Button to adjust distance
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Adjust Distance'),
                   onPressed: _isRunning ? _adjustDistance : null, // Only allow adjust while running? Or always?
               ),

               // TODO: Display Current Speed (if available from input/sensor)
               // TODO: Display Step Count / Cadence (if pedometer used)

               const Spacer(), // Push controls to bottom

               // --- Control Buttons ---
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                    // Reset Button
                    IconButton(
                       icon: const Icon(Icons.replay), tooltip: 'Reset', iconSize: 28,
                        onPressed: (_elapsedTime > Duration.zero && !_isRunning) ? _resetStopwatch : null, // Enable only when paused and time > 0
                     ),
                    // Start/Pause Button
                    ElevatedButton(
                       onPressed: _isRunning ? _pauseStopwatch : _startStopwatch,
                       style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(), padding: const EdgeInsets.all(24),
                           backgroundColor: _isRunning ? Colors.orange.shade700 : Colors.green.shade700,
                           foregroundColor: Colors.white,
                       ),
                       child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 40),
                    ),
                     // Save/Finish Button
                     IconButton(
                        icon: Icon(Icons.save_alt_outlined, color: Theme.of(context).colorScheme.primary), tooltip: 'Save Workout', iconSize: 28,
                         onPressed: (_elapsedTime > Duration.zero && !_isRunning) ? (_isSaving ? null : _saveWorkout) : null, // Enable only when paused and time > 0
                      ),
                 ],
               ),

              if (_isSaving) const Padding(padding: EdgeInsets.only(top: 16), child: LoadingIndicator()),

               const SizedBox(height: 20), // Bottom padding
           ],
         ),
      ),
    );
  }
}

// --- Need to add Uuid package ---
// import 'package:uuid/uuid.dart';
class Uuid { const Uuid(); String v4() => DateTime.now().millisecondsSinceEpoch.toString(); } // Placeholder

// --- Need to add saveManualWorkout to WorkoutProvider ---
extension WorkoutProviderManual on WorkoutProvider {
   Future<void> saveManualWorkout(Workout workout) async {
      // Similar logic to stopWorkout's save part, but using the provided manual workout object
       Log.i("Saving manual workout: ID=${workout.id}");
        try {
           await _workoutRepository.saveWorkout(workout); // Use injected repository
            await fetchWorkouts(); // Refresh list
        } catch(e) {
           Log.e("Error saving manual workout: $e");
           throw Exception("Failed to save manual workout."); // Rethrow to UI
        }
   }
}