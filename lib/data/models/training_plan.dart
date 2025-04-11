import 'package:equatable/equatable.dart';
import 'package:running_app/data/models/training_session.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

enum TrainingGoal { distance_5k, distance_10k, distance_half_marathon, distance_marathon, improve_pace, general_fitness }

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
  List<Object?> get props => [id, name, description, difficulty, durationWeeks, goal, sessions];

  // Note: copyWith might be complex if sessions need deep copying/modification

   // For Database storage
   Map<String, dynamic> toMap() {
     return {
       DatabaseHelper.columnPlanId: id,
       DatabaseHelper.columnPlanName: name,
       DatabaseHelper.columnPlanDescription: description,
       DatabaseHelper.columnPlanDifficulty: difficulty,
       DatabaseHelper.columnPlanDurationWeeks: durationWeeks,
       'goal': goal.name, // Store enum name
       // Sessions are stored in a separate table, linked by planId
     };
   }

   // Factory used by DatabaseHelper extension
   // fromMap logic is now in DatabaseHelper extension to handle session joining
}