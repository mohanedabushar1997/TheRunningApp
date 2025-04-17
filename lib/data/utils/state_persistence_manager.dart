import 'dart:convert';
import 'dart:convert';
import 'package:running_app/data/models/training_plan.dart'; // Added for TrainingPlan
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/presentation/providers/workout_provider.dart'; // For WorkoutTrackingState enum
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class for managing the persistence of potentially active workout state.
abstract class StatePersistenceManager {
  /// Saves the current workout state (if active or paused).
  Future<void> saveWorkoutState(
      Workout? workout, WorkoutTrackingState trackingState);

  /// Loads the previously saved workout state, if any.
  Future<({Workout? workout, WorkoutTrackingState? trackingState})?>
      loadWorkoutState();

  /// Clears any saved workout state.
  Future<void> clearWorkoutState();
}

/// Implementation using SharedPreferences.
class SharedPreferencesStatePersistenceManager
    implements StatePersistenceManager {
  static const _workoutStateKey =
      'active_workout_state_v3'; // Use versioned key
  static const _selectedPlanKey =
      'selected_training_plan_v1'; // Key for selected plan

  @override
  Future<void> saveWorkoutState(
      Workout? workout, WorkoutTrackingState trackingState) async {
    // Only save if workout is in a resumable state
    if (workout != null &&
        (trackingState == WorkoutTrackingState.active ||
            trackingState == WorkoutTrackingState.paused)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Serialize Workout to JSON map, then encode to string
        final workoutJson = workout.toMap(); // Uses model's toMap
        final stateToStore = {
          'workout': jsonEncode(workoutJson), // Store workout as JSON string
          'trackingStateName': trackingState.name, // Store enum name
        };
        await prefs.setString(_workoutStateKey, jsonEncode(stateToStore));
        Log.d(
            "Saved workout state (State: ${trackingState.name}) to SharedPreferences.");
      } catch (e, s) {
        Log.e("Error saving workout state to SharedPreferences",
            error: e, stackTrace: s);
        await clearWorkoutState(); // Clear potentially corrupted state
      }
    } else {
      // If workout is null or completed/idle/error, clear any existing state
      Log.d(
          "Clearing workout state because current state is not active/paused.");
      await clearWorkoutState();
    }
  }

  @override
  Future<({Workout? workout, WorkoutTrackingState? trackingState})?>
      loadWorkoutState() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final String? stateString = prefs.getString(_workoutStateKey);

      if (stateString != null) {
        final Map<String, dynamic> loadedState = jsonDecode(stateString);
        final String? workoutJsonString = loadedState['workout'] as String?;
        final String? trackingStateName =
            loadedState['trackingStateName'] as String?;

        if (workoutJsonString != null && trackingStateName != null) {
          // Decode workout JSON string back to map, then create Workout object
          final workoutMap =
              jsonDecode(workoutJsonString) as Map<String, dynamic>;
          // IMPORTANT: Workout.fromMap expects points/intervals to be added separately.
          // If they are crucial for resuming, they MUST be included in the JSON saved
          // or re-fetched/re-associated somehow upon loading here.
          // For now, assuming fromMap handles what's needed for basic state resume.
          final workout = Workout.fromMap(workoutMap);

          // Convert tracking state name back to enum
          final trackingState = WorkoutTrackingState.values.firstWhere(
              (e) => e.name == trackingStateName,
              orElse: () => WorkoutTrackingState.idle);

          // Validate loaded state - only return if it's active or paused
          if (trackingState == WorkoutTrackingState.active ||
              trackingState == WorkoutTrackingState.paused) {
            Log.i(
                "Loaded resumable workout state (State: ${trackingState.name}) from SharedPreferences.");
            return (workout: workout, trackingState: trackingState);
          } else {
            Log.w(
                "Loaded state is not resumable ($trackingStateName). Clearing.");
            await clearWorkoutState(); // Clear non-resumable state
            return null;
          }
        } else {
          Log.w(
              "Loaded state string is missing workout or trackingStateName. Clearing.");
          await clearWorkoutState(); // Clear corrupted state
          return null;
        }
      }
      Log.d("No workout state found in SharedPreferences.");
      return null;
    } catch (e, s) {
      Log.e("Error loading workout state from SharedPreferences",
          error: e, stackTrace: s);
      // Clear potentially corrupted state on load error
      if (prefs != null) {
        await prefs.remove(_workoutStateKey);
      }
      return null;
    }
  }

  @override
  Future<void> clearWorkoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool removed = await prefs.remove(_workoutStateKey);
      if (removed) {
        Log.i("Cleared workout state from SharedPreferences.");
      } else {
        Log.d("No workout state found to clear in SharedPreferences.");
      }
    } catch (e, s) {
      Log.e("Error clearing workout state from SharedPreferences",
          error: e, stackTrace: s);
    }
  }

  // --- Static methods for Training Plan Persistence (as used by TrainingPlanProvider) ---

  /// Saves the selected training plan ID and potentially its state.
  static Future<void> saveSelectedPlan(TrainingPlan? plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (plan != null) {
        // Assuming TrainingPlan has toMap method
        final planJson = plan.toMap();
        await prefs.setString(_selectedPlanKey, jsonEncode(planJson));
        Log.d(
            "Saved selected training plan (ID: ${plan.id}) to SharedPreferences.");
      } else {
        await prefs.remove(_selectedPlanKey);
        Log.d("Cleared selected training plan from SharedPreferences.");
      }
    } catch (e, s) {
      Log.e("Error saving selected training plan", error: e, stackTrace: s);
    }
  }

  /// Loads the selected training plan.
  static Future<TrainingPlan?> loadSelectedPlan() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final String? planString = prefs.getString(_selectedPlanKey);
      if (planString != null) {
        final Map<String, dynamic> planMap = jsonDecode(planString);
        // Assuming TrainingPlan has fromMap factory
        final plan = TrainingPlan.fromMap(planMap);
        Log.i(
            "Loaded selected training plan (ID: ${plan.id}) from SharedPreferences.");
        return plan;
      }
      Log.d("No selected training plan found in SharedPreferences.");
      return null;
    } catch (e, s) {
      Log.e("Error loading selected training plan", error: e, stackTrace: s);
      // Clear potentially corrupted state on load error
      if (prefs != null) {
        await prefs.remove(_selectedPlanKey);
      }
      return null;
    }
  }
}
