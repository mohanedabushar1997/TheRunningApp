import 'package:equatable/equatable.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

// TODO: Add fields like target zones (pace, HR), actual achieved metrics if tracked

class TrainingSession extends Equatable {
  final String id; // Unique ID for the session
  // final String planId; // Not needed in model if linked in DB
  final int week;
  final int day; // Day within the week (e.g., 1-7)
  final String description; // e.g., "30 min Easy Run", "6x400m Intervals"
  final String
      type; // e.g., 'Easy Run', 'Intervals', 'Long Run', 'Rest', 'Cross-Train'
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
  List<Object?> get props =>
      [id, week, day, description, type, duration, distance, completed];

  TrainingSession copyWith({
    String? id,
    int? week,
    int? day,
    String? description,
    String? type,
    Duration? duration,
    double? distance,
    bool? completed,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      week: week ?? this.week,
      day: day ?? this.day,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      completed: completed ?? this.completed,
    );
  }

  // For JSON Serialization (used by StatePersistenceManager)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week': week,
      'day': day,
      'description': description,
      'type': type,
      'durationSeconds': duration.inSeconds, // Store duration as seconds
      'distance': distance,
      'completed': completed, // Store as boolean
    };
  }

  // For JSON Deserialization (used by StatePersistenceManager)
  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      id: map['id'] as String? ?? '',
      week: map['week'] as int? ?? 0,
      day: map['day'] as int? ?? 0,
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? '',
      duration: Duration(
          seconds: map['durationSeconds'] as int? ?? 0), // Recreate Duration
      distance:
          (map['distance'] as num?)?.toDouble(), // Handle potential null or int
      completed: map['completed'] as bool? ?? false, // Handle potential null
    );
  }

  // Note: Database-specific toMap/fromMap logic might be better placed
  // in the DatabaseHelper or Repository layer if needed separately.
}
