import 'package:equatable/equatable.dart';
import 'package:running_app/data/models/route_point.dart';
import 'package:running_app/data/models/workout_interval.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

enum WorkoutType { run, cycle, walk, treadmill }
enum WorkoutStatus { pending, active, paused, completed, discarded }

class Workout extends Equatable {
  final String id; // Unique ID for the workout itself
  final String deviceId; // Identifier for the device this workout belongs to
  final DateTime date;
  final double distance; // Always in meters
  final Duration duration;
  final double? pace; // Seconds per kilometer (nullable if not calculated/applicable)
  final WorkoutType workoutType;
  final WorkoutStatus status;
  final int? caloriesBurned;
  final List<RoutePoint> routePoints;
  final List<WorkoutInterval> intervals; // For splits/intervals feature
  final double? elevationGain; // Meters
  final double? elevationLoss; // Meters

  // Calculated properties (Examples - use FormatUtils for presentation)
  int get durationInSeconds => duration.inSeconds;
  double get distanceInKm => distance / 1000.0;
  double get distanceInMiles => distance * 0.000621371;
  double? get calculatedPaceSecondsPerKm {
    if (distance <= 0 || duration.inSeconds <= 0) return null;
    return (duration.inSeconds / (distance / 1000.0));
  }

  const Workout({
    required this.id,
    required this.deviceId,
    required this.date,
    required this.distance,
    required this.duration,
    this.pace,
    required this.workoutType,
    required this.status,
    this.caloriesBurned,
    this.routePoints = const [],
    this.intervals = const [],
    this.elevationGain,
    this.elevationLoss,
  });

  @override
  List<Object?> get props => [
        id, deviceId, date, distance, duration, pace, workoutType, status,
        caloriesBurned, routePoints, intervals, elevationGain, elevationLoss,
      ];

  Workout copyWith({
    String? id, String? deviceId, DateTime? date, double? distance, Duration? duration,
    double? Function()? pace, WorkoutType? workoutType, WorkoutStatus? status,
    int? Function()? caloriesBurned, List<RoutePoint>? routePoints,
    List<WorkoutInterval>? intervals, double? Function()? elevationGain,
    double? Function()? elevationLoss,
  }) {
    return Workout(
      id: id ?? this.id, deviceId: deviceId ?? this.deviceId, date: date ?? this.date,
      distance: distance ?? this.distance, duration: duration ?? this.duration,
      pace: pace != null ? pace() : this.pace, workoutType: workoutType ?? this.workoutType,
      status: status ?? this.status,
      caloriesBurned: caloriesBurned != null ? caloriesBurned() : this.caloriesBurned,
      routePoints: routePoints ?? this.routePoints, intervals: intervals ?? this.intervals,
      elevationGain: elevationGain != null ? elevationGain() : this.elevationGain,
      elevationLoss: elevationLoss != null ? elevationLoss() : this.elevationLoss,
    );
  }

  // Map for Database insertion (excludes points/intervals)
  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnWorkoutId: id, // workout_id for the table
      DatabaseHelper.columnDeviceId: deviceId,
      DatabaseHelper.columnDate: date.toIso8601String(),
      DatabaseHelper.columnDistance: distance,
      DatabaseHelper.columnDurationSeconds: duration.inSeconds,
      DatabaseHelper.columnPace: pace,
      DatabaseHelper.columnWorkoutType: workoutType.name,
      DatabaseHelper.columnStatus: status.name,
      DatabaseHelper.columnCaloriesBurned: caloriesBurned,
      DatabaseHelper.columnElevationGain: elevationGain,
      DatabaseHelper.columnElevationLoss: elevationLoss,
      // Store intervals as JSON? Or handle in DB helper transaction.
      // DatabaseHelper.columnIntervalsJson: jsonEncode(intervals.map((i) => i.toMap()).toList()),
    };
  }

  // Factory from Database map (points/intervals added separately)
  factory Workout.fromMap(Map<String, dynamic> map) {
     String resolvedId = map[DatabaseHelper.columnWorkoutId] as String? ?? '';
     String deviceId = map[DatabaseHelper.columnDeviceId] as String? ?? '';
     DateTime date = DateTime.tryParse(map[DatabaseHelper.columnDate] as String? ?? '') ?? DateTime.now();
     double distance = (map[DatabaseHelper.columnDistance] as num?)?.toDouble() ?? 0.0;
     int durationSeconds = (map[DatabaseHelper.columnDurationSeconds] as num?)?.toInt() ?? 0;
     double? pace = (map[DatabaseHelper.columnPace] as num?)?.toDouble();
     int? caloriesBurned = (map[DatabaseHelper.columnCaloriesBurned] as num?)?.toInt();
     double? elevationGain = (map[DatabaseHelper.columnElevationGain] as num?)?.toDouble();
     double? elevationLoss = (map[DatabaseHelper.columnElevationLoss] as num?)?.toDouble();
     WorkoutType workoutType = WorkoutType.values.firstWhere(
        (e) => e.name == map[DatabaseHelper.columnWorkoutType], orElse: () => WorkoutType.run);
     WorkoutStatus status = WorkoutStatus.values.firstWhere(
        (e) => e.name == map[DatabaseHelper.columnStatus], orElse: () => WorkoutStatus.completed);
      // Decode intervals from JSON if stored that way
      // List<WorkoutInterval> intervals = [];
      // final intervalsJson = map[DatabaseHelper.columnIntervalsJson] as String?;
      // if (intervalsJson != null) {
      //    intervals = (jsonDecode(intervalsJson) as List).map((iMap) => WorkoutInterval.fromMap(iMap)).toList();
      // }

     return Workout(
        id: resolvedId, deviceId: deviceId, date: date, distance: distance,
        duration: Duration(seconds: durationSeconds), pace: pace, workoutType: workoutType,
        status: status, caloriesBurned: caloriesBurned, elevationGain: elevationGain,
        elevationLoss: elevationLoss,
        // intervals: intervals, // Assign decoded intervals
        // routePoints are added via copyWith after initial creation
     );
  }
}