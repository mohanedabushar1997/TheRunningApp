import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:running_app/data/sources/database_helper.dart'; // For column names

class RoutePoint extends Equatable {
  // final int? id; // Database primary key (optional in model)
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed; // meters per second
  final double? accuracy; // meters
  final double? heading; // degrees
  final DateTime timestamp;

  const RoutePoint({
    // this.id,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.accuracy,
    this.heading,
    required this.timestamp,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [
        // id,
        latitude, longitude, altitude, speed, accuracy, heading, timestamp,
      ];

  // Map for Database insertion
  Map<String, dynamic> toMap() {
    return {
      // Don't include DB primary key '_id' here
      DatabaseHelper.columnLatitude: latitude,
      DatabaseHelper.columnLongitude: longitude,
      DatabaseHelper.columnAltitude: altitude,
      DatabaseHelper.columnSpeed: speed,
      DatabaseHelper.columnAccuracy: accuracy,
      DatabaseHelper.columnHeading: heading,
      DatabaseHelper.columnTimestamp: timestamp.toIso8601String(),
      // workout_id is added separately in the DatabaseHelper transaction
    };
  }

  // Factory from Database map
  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      // id: map[DatabaseHelper.columnId] as int?, // Read DB ID if needed
      latitude: (map[DatabaseHelper.columnLatitude] as num?)?.toDouble() ?? 0.0,
      longitude:
          (map[DatabaseHelper.columnLongitude] as num?)?.toDouble() ?? 0.0,
      altitude: (map[DatabaseHelper.columnAltitude] as num?)?.toDouble(),
      speed: (map[DatabaseHelper.columnSpeed] as num?)?.toDouble(),
      accuracy: (map[DatabaseHelper.columnAccuracy] as num?)?.toDouble(),
      heading: (map[DatabaseHelper.columnHeading] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(
              map[DatabaseHelper.columnTimestamp] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
