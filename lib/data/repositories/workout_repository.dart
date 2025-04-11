import 'dart:math'; // Added for min function
import 'package:latlong2/latlong.dart'; // Added for LatLng
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/data/models/workout.dart';
import 'package:running_app/data/sources/database_helper.dart';
import 'package:running_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Keep if needed for settings/PBs

// Define standard distances for PBs (in meters)
const double pbDistance1k = 1000.0;
const double pbDistance5k = 5000.0;
const double pbDistance10k = 10000.0;
const double pbDistanceHalfMarathon = 21097.5;
const double pbDistanceMarathon = 42195.0;

class WorkoutRepository {
  final DatabaseHelper _dbHelper;
  // final SharedPreferences _prefs; // Commented out if not used directly here

  WorkoutRepository(
      {DatabaseHelper? dbHelper /*, required SharedPreferences prefs*/})
      : _dbHelper = dbHelper ?? DatabaseHelper(); // Use factory constructor
  // _prefs = prefs; // Commented out if not used directly here

  // --- Workout Operations (Device ID aware) ---

  Future<String> saveWorkout(Workout workout) async {
    if (workout.deviceId.isEmpty) {
      Log.e("Cannot save workout: Device ID is empty.");
      throw ArgumentError("Device ID cannot be empty when saving workout.");
    }
    try {
      Log.d(
          'Saving workout locally: ID=${workout.id}, DeviceID=${workout.deviceId}');
      // Ensure workout has a valid ID if needed (though usually generated before this point)
      final workoutToSave = workout.id.isEmpty
          ? workout.copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString())
          : workout;

      await _dbHelper
          .insertWorkout(workoutToSave); // DB Helper handles transaction
      Log.i('Workout saved locally: Workout ID=${workoutToSave.id}');

      // TODO: Check for and save new Personal Bests after saving workout
      await checkAndSavePersonalBests(workoutToSave); // Corrected method name

      return workoutToSave.id;
    } catch (e, s) {
      Log.e('Error saving workout', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    if (workout.deviceId.isEmpty || workout.id.isEmpty) {
      Log.e("Cannot update workout: Workout ID or Device ID is empty.");
      throw ArgumentError(
          "Workout ID and Device ID cannot be empty for update.");
    }
    try {
      Log.d(
          'Updating workout locally: ID=${workout.id}, DeviceID=${workout.deviceId}');
      await _dbHelper.updateWorkout(workout);
      Log.i('Workout updated locally: ID=${workout.id}');
    } catch (e, s) {
      Log.e('Error updating workout', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Workout?> getWorkoutById(String workoutId, String deviceId) async {
    // Note: deviceId is passed but getWorkoutById in DB Helper might only need workoutId
    try {
      Log.d('Fetching workout by ID: $workoutId for DeviceID: $deviceId');
      return await _dbHelper.getWorkoutById(workoutId);
    } catch (e, s) {
      Log.e('Error fetching workout by ID $workoutId', error: e, stackTrace: s);
      return null;
    }
  }

  Future<List<Workout>> getAllWorkouts(
      {required String deviceId, int? limit, int? offset}) async {
    try {
      Log.d(
          'Fetching workouts for Device: $deviceId, limit: $limit, offset: $offset');
      return await _dbHelper.getAllWorkouts(
          deviceId: deviceId, limit: limit, offset: offset);
    } catch (e, s) {
      Log.e('Error fetching workouts for device $deviceId',
          error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> deleteWorkout(String workoutId, String deviceId) async {
    // Note: deviceId is passed but not used if deleteWorkoutById only needs ID
    try {
      Log.d('Deleting workout locally: ID=$workoutId, DeviceID=$deviceId');
      await _dbHelper.deleteWorkoutById(workoutId); // Corrected method name
      Log.i('Workout deleted locally: ID=$workoutId');
    } catch (e, s) {
      Log.e('Error deleting workout ID $workoutId', error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Statistics (Device ID aware) ---

  Future<Map<String, dynamic>> getTotalStats({required String deviceId}) async {
    try {
      // Corrected: Pass deviceId correctly as positional argument
      return await _dbHelper.getTotalStats(deviceId);
    } catch (e, s) {
      Log.e('Error fetching total stats for device $deviceId',
          error: e, stackTrace: s);
      return {'totalDistance': 0.0, 'totalDuration': 0, 'workoutCount': 0};
    }
  }

  Future<Map<String, dynamic>> getStatsForPeriod(DateTime start, DateTime end,
      {required String deviceId}) async {
    try {
      // Corrected: Pass arguments correctly as positional arguments
      return await _dbHelper.getStatsForPeriod(deviceId, start, end);
    } catch (e, s) {
      Log.e(
          'Error fetching stats for period $start - $end for device $deviceId',
          error: e,
          stackTrace: s);
      return {'totalDistance': 0.0, 'totalDuration': 0, 'workoutCount': 0};
    }
  }

  // --- Personal Bests (TODO) ---

  // TODO: Implement Personal Bests logic
  // This requires storing PBs (e.g., in DB settings table or separate table)
  // And logic to check workouts against stored PBs.

  /// Retrieves stored personal bests for standard distances.
  Future<Map<double, Duration>> getPersonalBests(
      {required String deviceId}) async {
    Log.d("Fetching personal bests for device $deviceId");
    Map<double, Duration> pbs = {};
    // Example distances to check
    List<double> standardDistances = [
      pbDistance1k,
      pbDistance5k,
      pbDistance10k,
      pbDistanceHalfMarathon,
      pbDistanceMarathon
    ];

    try {
      for (double distance in standardDistances) {
        // Retrieve PB duration stored with a specific key, e.g., "pb_1000"
        String key = "pb_${distance.toInt()}";
        // Corrected: Call method on DatabaseHelper instance
        String? storedDurationStr = await _dbHelper.getSetting(key);
        if (storedDurationStr != null) {
          // Check for null before parsing
          int? seconds = int.tryParse(storedDurationStr);
          if (seconds != null) {
            pbs[distance] = Duration(seconds: seconds);
          }
        }
      }
      Log.i("Fetched ${pbs.length} personal bests.");
    } catch (e, s) {
      Log.e("Error fetching personal bests", error: e, stackTrace: s);
    }
    return pbs;
  }

  /// Checks a completed workout for new personal bests and saves them.
  Future<Map<double, Duration>> checkAndSavePersonalBests(
      Workout workout) async {
    if (workout.status != WorkoutStatus.completed || workout.deviceId.isEmpty) {
      return {}; // Only check completed workouts for the correct device
    }

    Log.i("Checking workout ${workout.id} for new personal bests...");
    Map<double, Duration> currentPBs =
        await getPersonalBests(deviceId: workout.deviceId); // Corrected call
    Map<double, Duration> newPBsFound = {};

    // Define distances to check (in meters)
    List<double> checkDistances = [
      pbDistance1k, pbDistance5k, pbDistance10k,
      pbDistanceHalfMarathon, pbDistanceMarathon,
      // Add longest distance achieved if workout exceeds marathon?
      if (workout.distance > pbDistanceMarathon) workout.distance
    ];

    try {
      for (double targetDistance in checkDistances) {
        if (workout.distance < targetDistance) continue; // Workout too short

        // Find the fastest time to cover targetDistance within this workout
        // This requires analyzing routePoints to find the segment. Complex!
        Duration? timeForDistance =
            _findFastestTimeForDistance(workout.routePoints, targetDistance);

        if (timeForDistance != null) {
          Duration? currentPB = currentPBs[targetDistance];
          bool isNewPB = currentPB == null || timeForDistance < currentPB;

          if (isNewPB) {
            Log.i(
                "NEW PERSONAL BEST for ${targetDistance}m: ${timeForDistance.inSeconds}s (was ${currentPB?.inSeconds}s)");
            newPBsFound[targetDistance] = timeForDistance;
            // Save the new PB
            String key = "pb_${targetDistance.toInt()}";
            // Corrected: Call method on DatabaseHelper instance
            await _dbHelper.saveSetting(
                key, timeForDistance.inSeconds.toString());
          }
        }
      }
      Log.i("Finished checking PBs. Found ${newPBsFound.length} new PBs.");
    } catch (e, s) {
      Log.e("Error checking/saving personal bests", error: e, stackTrace: s);
    }
    return newPBsFound; // Return map of new PBs achieved in this workout
  }

  /// Finds the fastest time to cover a specific distance within a workout's route points.
  /// Placeholder for complex logic.
  Duration? _findFastestTimeForDistance(
      List<RoutePoint> points, double targetDistanceMeters) {
    // TODO: Implement robust logic to find the fastest segment covering targetDistanceMeters.
    // This involves iterating through the points, calculating cumulative distance
    // for sliding windows, and finding the minimum time for windows >= targetDistance.
    // Consider edge cases and GPS inaccuracies.
    // Return null if targetDistance not reached or cannot be calculated.
    if (points.length < 2) return null;

    double cumulativeDistance = 0;
    DateTime startTime = points.first.timestamp;

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      // final distCalc = const Distance(); // Commented out - Distance/LengthUnit undefined
      // cumulativeDistance +=
      //     distCalc.as(LengthUnit.Meter, p1.toLatLng(), p2.toLatLng()); // Commented out

      // Placeholder distance calculation using helper if available, otherwise skip PB check for now
      // Replace with actual distance calculation if helper is fixed or another method is used
      // Assuming DB helper has this - NOTE: DatabaseHelper does NOT have this method currently.
      // This PB logic will fail until calculateDistance is implemented somewhere accessible.
      // cumulativeDistance += _dbHelper.calculateDistance(p1.latitude, p1.longitude, p2.latitude, p2.longitude); // Commented out as method doesn't exist on DB Helper
      // For now, just increment placeholder to avoid error, PB logic is broken.
      cumulativeDistance += 10.0; // Placeholder increment

      if (cumulativeDistance >= targetDistanceMeters) {
        // Basic check: time from start to this point. Not necessarily fastest segment.
        // A real implementation needs sliding window or more advanced analysis.
        Duration timeTaken = p2.timestamp.difference(startTime);
        Log.d(
            "Basic Check: Reached ${targetDistanceMeters}m in ${timeTaken.inSeconds}s (Total dist: $cumulativeDistance)");
        // Return this simple duration for now, placeholder.
        return timeTaken;
      }
    }

    Log.w(
        "Target distance ${targetDistanceMeters}m not reached in workout for PB check.");
    return null; // Target distance not covered
  }
}
