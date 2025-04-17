import 'package:geolocator/geolocator.dart'; // Import the correct Position type

/// Model class for enhanced location data
///
/// Extends basic location data with additional metrics and filtering capabilities
/// for improved accuracy and analysis.
class EnhancedLocationData {
  // Raw position data from the GPS (Uses geolocator's Position)
  final Position rawPosition;

  // Filtered coordinates (after Kalman filtering if enabled)
  final double filteredLatitude;
  final double filteredLongitude;
  final double filteredAltitude;

  // Quality and metrics
  final bool isReliable;
  final double elevationGain;
  final double elevationLoss;
  final double distanceFromPrevious;
  final double calculatedSpeed;
  final int batteryLevel;
  final String activity;

  const EnhancedLocationData({
    required this.rawPosition,
    required this.filteredLatitude,
    required this.filteredLongitude,
    required this.filteredAltitude,
    required this.isReliable,
    this.elevationGain = 0.0,
    this.elevationLoss = 0.0,
    this.distanceFromPrevious = 0.0,
    required this.calculatedSpeed,
    required this.batteryLevel,
    required this.activity,
  });

  /// Get the latitude (filtered if available, raw otherwise)
  double get latitude => filteredLatitude;

  /// Get the longitude (filtered if available, raw otherwise)
  double get longitude => filteredLongitude;

  /// Get the altitude (filtered if available, raw otherwise)
  double get altitude => filteredAltitude;

  /// Get the speed (calculated if available, raw otherwise)
  double get speed => calculatedSpeed > 0 ? calculatedSpeed : rawPosition.speed;

  /// Get the accuracy from the raw position
  double get accuracy => rawPosition.accuracy;

  /// Get the timestamp from the raw position
  DateTime? get timestamp => rawPosition.timestamp;

  /// Create a copy with modified fields
  EnhancedLocationData copyWith({
    Position? rawPosition,
    double? filteredLatitude,
    double? filteredLongitude,
    double? filteredAltitude,
    bool? isReliable,
    double? elevationGain,
    double? elevationLoss,
    double? distanceFromPrevious,
    double? calculatedSpeed,
    int? batteryLevel,
    String? activity,
  }) {
    return EnhancedLocationData(
      rawPosition: rawPosition ?? this.rawPosition,
      filteredLatitude: filteredLatitude ?? this.filteredLatitude,
      filteredLongitude: filteredLongitude ?? this.filteredLongitude,
      filteredAltitude: filteredAltitude ?? this.filteredAltitude,
      isReliable: isReliable ?? this.isReliable,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      distanceFromPrevious: distanceFromPrevious ?? this.distanceFromPrevious,
      calculatedSpeed: calculatedSpeed ?? this.calculatedSpeed,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      activity: activity ?? this.activity,
    );
  }

  @override
  String toString() {
    return 'EnhancedLocationData(lat: $filteredLatitude, lng: $filteredLongitude, alt: $filteredAltitude, speed: $calculatedSpeed, reliable: $isReliable, activity: $activity)';
  }
}

// Removed the conflicting local Position class definition.
// The 'Position' type used above now refers to the one from 'package:geolocator/geolocator.dart'.
