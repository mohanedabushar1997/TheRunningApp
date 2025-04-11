import 'package:equatable/equatable.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column name reference if needed

// TODO: Add target heart rate zone if HR monitoring is implemented
// TODO: Add actual average heart rate achieved during interval

enum IntervalType { warmup, work, recovery, rest, cooldown }

class WorkoutInterval extends Equatable {
  final Duration duration; // Planned duration
  final double? distance; // Optional distance target (meters)
  final IntervalType type;
  final double? targetPaceMin; // Optional target pace range (seconds per km)
  final double? targetPaceMax; // Optional target pace range (seconds per km)

  // Actual achieved metrics (optional, filled during/after workout)
  final double? actualDistance; // Meters achieved during this interval
  final Duration? actualDuration; // Actual time spent in this interval
  final double? actualPace; // Average pace (seconds per km) during this interval

  const WorkoutInterval({
    required this.duration,
    required this.type,
    this.distance,
    this.targetPaceMin,
    this.targetPaceMax,
    this.actualDistance,
    this.actualDuration,
    this.actualPace,
  });

  @override
  List<Object?> get props => [
        duration, distance, type, targetPaceMin, targetPaceMax,
        actualDistance, actualDuration, actualPace
      ];

  WorkoutInterval copyWith({
    Duration? duration, double? distance, IntervalType? type,
    double? targetPaceMin, double? targetPaceMax, double? actualDistance,
    Duration? actualDuration, double? actualPace,
  }) {
    return WorkoutInterval(
      duration: duration ?? this.duration, type: type ?? this.type,
      distance: distance ?? this.distance, targetPaceMin: targetPaceMin ?? this.targetPaceMin,
      targetPaceMax: targetPaceMax ?? this.targetPaceMax,
      actualDistance: actualDistance ?? this.actualDistance,
      actualDuration: actualDuration ?? this.actualDuration,
      actualPace: actualPace ?? this.actualPace,
    );
  }


  // For JSON serialization (e.g., if storing intervals as JSON in Workout table)
  Map<String, dynamic> toMap() {
    return {
      'duration_seconds': duration.inSeconds,
      'distance': distance,
      'type': type.name,
      'targetPaceMin': targetPaceMin,
      'targetPaceMax': targetPaceMax,
      'actualDistance': actualDistance,
      'actualDuration_seconds': actualDuration?.inSeconds,
      'actualPace': actualPace,
    };
  }

  factory WorkoutInterval.fromMap(Map<String, dynamic> map) {
    return WorkoutInterval(
      duration: Duration(seconds: (map['duration_seconds'] as num?)?.toInt() ?? 0),
      distance: (map['distance'] as num?)?.toDouble(),
      type: IntervalType.values.firstWhere(
        (e) => e.name == map['type'], orElse: () => IntervalType.work),
      targetPaceMin: (map['targetPaceMin'] as num?)?.toDouble(),
      targetPaceMax: (map['targetPaceMax'] as num?)?.toDouble(),
      actualDistance: (map['actualDistance'] as num?)?.toDouble(),
      actualDuration: map['actualDuration_seconds'] != null
          ? Duration(seconds: (map['actualDuration_seconds'] as num).toInt())
          : null,
      actualPace: (map['actualPace'] as num?)?.toDouble(),
    );
  }
}