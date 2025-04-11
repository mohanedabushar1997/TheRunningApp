/// Model class for training intervals
class TrainingInterval {
  final String type; // "run", "walk", "sprint", "rest", "warmup", "cooldown", etc.
  final int duration; // Duration in minutes
  final String? intensity; // "low", "medium", "high", "very high", etc.

  const TrainingInterval({
    required this.type,
    required this.duration,
    this.intensity,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'duration': duration,
      'intensity': intensity,
    };
  }

  // Create from Map from database
  factory TrainingInterval.fromMap(Map<String, dynamic> map) {
    return TrainingInterval(
      type: map['type'] as String,
      duration: map['duration'] as int,
      intensity: map['intensity'] as String?,
    );
  }

  // Create a copy with modified fields
  TrainingInterval copyWith({
    String? type,
    int? duration,
    String? intensity,
  }) {
    return TrainingInterval(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  String toString() {
    return 'TrainingInterval(type: $type, duration: $duration, intensity: $intensity)';
  }
}
