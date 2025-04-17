import 'package:equatable/equatable.dart';
import 'package:running_app/data/models/training_session.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

enum TrainingGoal {
  distance_5k,
  distance_10k,
  distance_half_marathon,
  distance_marathon,
  improve_pace,
  general_fitness
}

class TrainingPlan extends Equatable {
  final String id; // Unique ID for the plan
  final String name;
  final String description;
  final String difficulty; // e.g., Beginner, Intermediate, Advanced
  final int durationWeeks;
  final TrainingGoal goal; // Added goal
  final List<TrainingSession> sessions; // List of sessions in the plan

  const TrainingPlan({
    required this.id,
    required this.name,
    this.description = '',
    required this.difficulty,
    required this.durationWeeks,
    required this.goal,
    required this.sessions,
  });

  // Get total number of sessions
  int get totalSessions => sessions.length;

  // Get sessions for a specific week
  List<TrainingSession> sessionsForWeek(int week) {
    return sessions.where((s) => s.week == week).toList()
      ..sort((a, b) => a.day.compareTo(b.day)); // Ensure sorted by day
  }

  @override
  List<Object?> get props =>
      [id, name, description, difficulty, durationWeeks, goal, sessions];

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? description,
    String? difficulty,
    int? durationWeeks,
    TrainingGoal? goal,
    List<TrainingSession>? sessions,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      goal: goal ?? this.goal,
      sessions: sessions ??
          List<TrainingSession>.from(this.sessions), // Deep copy list
    );
  }

  // For JSON/Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Use simple keys for JSON
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'durationWeeks': durationWeeks,
      'goal': goal.name, // Store enum name
      // Serialize sessions list
      'sessions': sessions.map((s) => s.toMap()).toList(),
    };
  }

  // Factory for JSON Deserialization (used by StatePersistenceManager)
  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    // Deserialize sessions list
    final sessionsList = (map['sessions'] as List<dynamic>?)
            ?.map((sessionMap) =>
                TrainingSession.fromMap(sessionMap as Map<String, dynamic>))
            .toList() ??
        []; // Default to empty list if null

    return TrainingPlan(
      id: map['id'] as String? ??
          map[DatabaseHelper.columnPlanId] as String? ??
          '', // Check both keys for compatibility
      name: map['name'] as String? ??
          map[DatabaseHelper.columnPlanName] as String? ??
          '',
      description: map['description'] as String? ??
          map[DatabaseHelper.columnPlanDescription] as String? ??
          '',
      difficulty: map['difficulty'] as String? ??
          map[DatabaseHelper.columnPlanDifficulty] as String? ??
          '',
      durationWeeks: map['durationWeeks'] as int? ??
          map[DatabaseHelper.columnPlanDurationWeeks] as int? ??
          0,
      goal: TrainingGoal.values.firstWhere(
        (e) => e.name == map['goal'],
        orElse: () => TrainingGoal.general_fitness, // Default goal
      ),
      sessions: sessionsList,
    );
  }

  // Note: A separate fromMap might be needed for DatabaseHelper if it expects
  // different keys or doesn't handle the sessions list directly.
  // The current fromMap prioritizes the JSON keys but falls back to DB keys.
}
