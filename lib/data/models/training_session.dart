import 'package:equatable/equatable.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

// TODO: Add fields like target zones (pace, HR), actual achieved metrics if tracked

class TrainingSession extends Equatable {
  final String id; // Unique ID for the session
  // final String planId; // Not needed in model if linked in DB
  final int week;
  final int day; // Day within the week (e.g., 1-7)
  final String description; // e.g., "30 min Easy Run", "6x400m Intervals"
  final String type; // e.g., 'Easy Run', 'Intervals', 'Long Run', 'Rest', 'Cross-Train'
  final Duration duration; // Planned duration
  final double? distance; // Optional planned distance (meters)
  final bool completed;

  const TrainingSession({
    required this.id,
    // required this.planId,
    required this.week,
    required this.day,
    required this.description,
    required this.type,
    required this.duration,
    this.distance,
    this.completed = false,
  });

  @override
  List<Object?> get props => [id, week, day, description, type, duration, distance, completed];

   // For Database storage
   Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnSessionId: id,
      // DatabaseHelper.columnSessionPlanId is added in DB Helper during insertion
      DatabaseHelper.columnSessionWeek: week,
      DatabaseHelper.columnSessionDay: day,
      DatabaseHelper.columnSessionDescription: description,
      DatabaseHelper.columnSessionType: type,
      DatabaseHelper.columnSessionDuration: duration.inSeconds,
      DatabaseHelper.columnSessionDistance: distance,
      DatabaseHelper.columnSessionCompleted: completed ? 1 : 0,
    };
  }

  // fromMap logic is now in DatabaseHelper extension
}