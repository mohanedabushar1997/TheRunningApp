import 'package:flutter/material.dart'; // For Icons
import 'package:equatable/equatable.dart';

// Define enums here if not defined elsewhere
enum RunningCategory {
  all('All', Icons.list),
  technique('Technique', Icons.directions_run),
  nutrition('Nutrition', Icons.restaurant),
  gear('Gear', Icons.storefront),
  injuryPrevention('Injury Prevention', Icons.healing),
  training('Training', Icons.fitness_center),
  recovery('Recovery', Icons.self_improvement),
  motivation('Motivation', Icons.emoji_events);
  // TODO: Add 'Mental Strategy', 'Racing' categories?

  const RunningCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

enum TipDifficulty { beginner, intermediate, advanced, any }

class RunningTip extends Equatable {
  final String id;
  final String title;
  final String content;
  final RunningCategory category;
  final TipDifficulty difficulty;
  final bool isFavorite; // Added for TODO

  const RunningTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.difficulty,
    this.isFavorite = false, // Default to not favorite
  });

  @override
  List<Object?> get props => [id, title, content, category, difficulty, isFavorite];

  RunningTip copyWith({
    String? id,
    String? title,
    String? content,
    RunningCategory? category,
    TipDifficulty? difficulty,
    bool? isFavorite,
  }) {
    return RunningTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // --- Serialization (if storing tips in DB or persistence) ---
  // Note: Icons cannot be directly serialized to JSON easily. Store category name.

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.name, // Store enum name
      'difficulty': difficulty.name, // Store enum name
      'isFavorite': isFavorite, // Assuming stored locally (e.g., in SharedPreferences)
    };
  }

  factory RunningTip.fromMap(Map<String, dynamic> map) {
    return RunningTip(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: RunningCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => RunningCategory.all, // Default fallback
      ),
      difficulty: TipDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => TipDifficulty.any, // Default fallback
      ),
      isFavorite: map['isFavorite'] as bool? ?? false, // Load favorite status
    );
  }
}