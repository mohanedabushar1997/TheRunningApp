import 'dart:math' as math;

/// Model class for location data
///
/// Represents a single location point with latitude, longitude, altitude,
/// speed, accuracy, and timestamp information.
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  /// Convert LocationData to JSON map
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create LocationData from JSON map
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] is int
          ? (json['latitude'] as int).toDouble()
          : json['latitude'] as double,
      longitude: json['longitude'] is int
          ? (json['longitude'] as int).toDouble()
          : json['longitude'] as double,
      altitude: json['altitude'] != null
          ? (json['altitude'] is int
              ? (json['altitude'] as int).toDouble()
              : json['altitude'] as double)
          : null,
      speed: json['speed'] is int
          ? (json['speed'] as int).toDouble()
          : json['speed'] as double,
      accuracy: json['accuracy'] is int
          ? (json['accuracy'] as int).toDouble()
          : json['accuracy'] as double,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  /// Calculate distance between two points using the Haversine formula
  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper methods for the Haversine formula
  static double _toRadians(double degrees) => degrees * (math.pi / 180);

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, alt: $altitude, speed: $speed, accuracy: $accuracy, time: $timestamp)';
  }
}
