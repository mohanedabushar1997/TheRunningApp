import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For IconData

enum AchievementType {
  distanceTotal, // Total distance run (e.g., 100km, 500km, 1000km)
  distanceSingle, // Longest single run
  durationTotal, // Total time spent running
  durationSingle, // Longest single run duration
  countWorkouts, // Number of workouts completed
  paceBest, // Fastest pace for standard distances (1k, 5k, 10k, HM, M)
  streakConsecutiveDays, // Running streak
  elevationTotalGain, // Total elevation gain
  specialEvent, // e.g., Completed Marathon, Ran on New Year's Day
  // Add more types as needed
}

class Achievement extends Equatable {
  final String id; // Unique identifier (e.g., "total_dist_100k")
  final String name; // User-facing name (e.g., "100 km Club")
  final String
      description; // How to earn it (e.g., "Run a total distance of 100 kilometers")
  final IconData icon; // Icon representing the achievement
  final AchievementType type; // Category/Type
  final double threshold; // Value needed to unlock (e.g., 100000 for 100km)
  final DateTime? dateEarned; // When the achievement was unlocked
  final String? workoutId; // Optional: Workout ID that unlocked it

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.threshold,
    this.dateEarned,
    this.workoutId,
  });

  bool get isEarned => dateEarned != null;

  @override
  List<Object?> get props =>
      [id, name, description, icon, type, threshold, dateEarned, workoutId];

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    AchievementType? type,
    double? threshold,
    DateTime? dateEarned,
    bool clearDateEarned = false, // Flag to explicitly set dateEarned to null
    String? workoutId,
    bool clearWorkoutId = false, // Flag to explicitly set workoutId to null
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      dateEarned: clearDateEarned ? null : dateEarned ?? this.dateEarned,
      workoutId: clearWorkoutId ? null : workoutId ?? this.workoutId,
    );
  }

  // TODO: Implement toMap/fromMap if storing achievements in DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_code': icon.codePoint, // Store icon codepoint
      'icon_font_family': icon.fontFamily, // Store font family
      'icon_font_package': icon.fontPackage, // Store font package
      'type': type.name,
      'threshold': threshold,
      'dateEarned': dateEarned?.toIso8601String(),
      'workoutId': workoutId,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: IconData(
        map['icon_code'] as int? ?? Icons.star_border.codePoint, // Default icon
        fontFamily: map['icon_font_family'] as String?,
        fontPackage: map['icon_font_package'] as String?,
      ),
      type: AchievementType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => AchievementType.specialEvent),
      threshold: (map['threshold'] as num?)?.toDouble() ?? 0.0,
      dateEarned: map['dateEarned'] != null
          ? DateTime.tryParse(map['dateEarned'] as String)
          : null,
      workoutId: map['workoutId'] as String?,
    );
  }
}

// --- Predefined Achievements List (Example) ---
// This list could be defined here, loaded from assets, or generated
// TODO: Define a comprehensive list of achievements
final List<Achievement> predefinedAchievements = [
  const Achievement(
      id: 'total_dist_10k',
      name: '10 Kilometers',
      description: 'Run a total of 10 kilometers.',
      icon: Icons.directions_run,
      type: AchievementType.distanceTotal,
      threshold: 10000),
  const Achievement(
      id: 'total_dist_100k',
      name: '100 km Club',
      description: 'Run a total distance of 100 kilometers.',
      icon: Icons.emoji_events_outlined,
      type: AchievementType.distanceTotal,
      threshold: 100000),
  const Achievement(
      id: 'single_dist_10k',
      name: 'First 10k',
      description: 'Complete a single run of 10 kilometers or more.',
      icon: Icons.looks_one,
      type: AchievementType.distanceSingle,
      threshold: 10000),
  const Achievement(
      id: 'single_dist_hm',
      name: 'Half Marathoner',
      description: 'Complete a single run of 21.1 kilometers or more.',
      icon: Icons.military_tech_outlined,
      type: AchievementType.distanceSingle,
      threshold: 21097.5),
  const Achievement(
      id: 'count_workouts_10',
      name: 'Getting Started',
      description: 'Complete 10 workouts.',
      icon: Icons.fitness_center,
      type: AchievementType.countWorkouts,
      threshold: 10),
  // ... Add many more achievements ...
];
