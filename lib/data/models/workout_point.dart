class WorkoutPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double elevation; // in meters

  WorkoutPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.elevation = 0,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'elevation': elevation,
    };
  }

  // Create from Map from database
  factory WorkoutPoint.fromMap(Map<String, dynamic> map) {
    return WorkoutPoint(
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
      elevation: map['elevation'] ?? 0,
    );
  }
}
