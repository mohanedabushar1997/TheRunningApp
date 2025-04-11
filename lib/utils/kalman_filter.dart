/// Kalman filter implementation for location data smoothing
///
/// This filter reduces GPS noise and improves location accuracy by
/// applying statistical methods to predict the most likely position.
class LocationKalmanFilter {
  // State variables
  double _lat;
  double _lng;
  double _alt;
  
  // Uncertainty (error covariance)
  double _errorLat = 10.0;
  double _errorLng = 10.0;
  double _errorAlt = 10.0;
  
  // Process noise (how much we expect the position to change between measurements)
  final double _processNoise;
  
  /// Initialize the filter with starting coordinates
  LocationKalmanFilter({
    required double initialLat,
    required double initialLng,
    required double initialAlt,
    double processNoise = 1.0,
  }) : 
    _lat = initialLat,
    _lng = initialLng,
    _alt = initialAlt,
    _processNoise = processNoise;
  
  /// Update the filter with new measurements
  /// 
  /// Returns a map with the filtered latitude, longitude, and altitude
  Map<String, double> update(
    double measuredLat, 
    double measuredLng, 
    {double? alt, double accuracy = 10.0}
  ) {
    // Increase uncertainty based on process noise
    _errorLat += _processNoise;
    _errorLng += _processNoise;
    _errorAlt += _processNoise;
    
    // Calculate Kalman gain
    // Higher accuracy (lower value) means more weight on the measurement
    // Lower accuracy (higher value) means more weight on the prediction
    double accuracySquared = accuracy * accuracy;
    
    double kLat = _errorLat / (_errorLat + accuracySquared);
    double kLng = _errorLng / (_errorLng + accuracySquared);
    double kAlt = _errorAlt / (_errorAlt + accuracySquared);
    
    // Update state with measurement using Kalman gain
    _lat += kLat * (measuredLat - _lat);
    _lng += kLng * (measuredLng - _lng);
    
    // Update altitude if provided
    if (alt != null) {
      _alt += kAlt * (alt - _alt);
    }
    
    // Update uncertainty
    _errorLat *= (1 - kLat);
    _errorLng *= (1 - kLng);
    _errorAlt *= (1 - kAlt);
    
    // Return filtered values
    return {
      'latitude': _lat,
      'longitude': _lng,
      'altitude': _alt,
    };
  }
  
  /// Reset the filter with new initial values
  void reset({
    required double lat,
    required double lng,
    required double alt,
  }) {
    _lat = lat;
    _lng = lng;
    _alt = alt;
    _errorLat = 10.0;
    _errorLng = 10.0;
    _errorAlt = 10.0;
  }
  
  /// Get the current state of the filter
  Map<String, double> get currentState => {
    'latitude': _lat,
    'longitude': _lng,
    'altitude': _alt,
    'error_lat': _errorLat,
    'error_lng': _errorLng,
    'error_alt': _errorAlt,
  };
}
