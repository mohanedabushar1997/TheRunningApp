import 'dart:math';
import 'package:vector_math/vector_math.dart'; // Use vector_math for matrix operations
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart'
    as geo;
import 'package:running_app/utils/logger.dart';

// Simple 2D Kalman Filter for Position (Latitude, Longitude)
// Assumes constant velocity model (can be extended)
class KalmanFilter2D {
  // Noise Parameters (tune these based on device/environment)
  final double
      processNoise; // Uncertainty in the state prediction (e.g., random acceleration)
  final double measurementNoise; // Uncertainty in the GPS measurement

  // Constructor
  KalmanFilter2D({
    this.processNoise = 0.1, // Default values
    this.measurementNoise = 10.0,
  });

  // State Vector: [latitude, longitude, lat_velocity, lon_velocity]
  Vector4 _x = Vector4.zero(); // State estimate
  // Covariance Matrix: Uncertainty of the state estimate
  Matrix4 _P = Matrix4.identity() * 500.0; // Initial uncertainty (large)

  // State Transition Matrix (Constant Velocity)
  // [ 1, 0, dt, 0 ]
  // [ 0, 1, 0, dt ]
  // [ 0, 0, 1, 0 ]
  // [ 0, 0, 0, 1 ]
  Matrix4 _F = Matrix4.identity();

  // Measurement Matrix (We only observe position)
  // [ 1, 0, 0, 0 ]
  // [ 0, 1, 0, 0 ]
  // (Create as 2x4, but use Matrix4 and select parts for simplicity here)
  final Matrix4 _H = Matrix4.identity()
    ..setColumn(2, Vector4.zero())
    ..setColumn(3, Vector4.zero());

  // Process Noise Covariance Matrix
  late Matrix4 _Q;

  // Initialize matrices
  void _initializeMatrices() {
    // Initialize process noise covariance matrix
    _Q = Matrix4.identity() * processNoise;
  }

  // Reset filter state
  void reset() {
    _x = Vector4.zero();
    _P = Matrix4.identity() * 500.0;
    _initializeMatrices();
  }

  // Main filtering function
  Map<String, double> filter(
      double latitude, double longitude, double accuracy, double dt) {
    Log.d(
        'KalmanFilter: Input lat=$latitude, lng=$longitude, acc=$accuracy, dt=$dt');

    // If this is the first point, initialize state
    if (_x.x == 0 && _x.y == 0) {
      _x.x = latitude;
      _x.y = longitude;
      _initializeMatrices();
      return {'latitude': latitude, 'longitude': longitude};
    }

    // Update state transition matrix with dt
    _F.setEntry(0, 2, dt);
    _F.setEntry(1, 3, dt);

    // 1. Predict Step
    // State prediction: x = F * x
    Vector4 xPred = _F.transform(_x);

    // Covariance prediction: P = F * P * F^T + Q
    Matrix4 FTranspose = Matrix4.copy(_F)..transpose();
    Matrix4 PPred = _F * _P * FTranspose + _Q;

    // 2. Update Step (Measurement Update)
    // Kalman Gain: K = P * H^T * inv(H * P * H^T + R)
    Matrix4 HTranspose = Matrix4.copy(_H)..transpose();
    Matrix4 S = _H * PPred * HTranspose +
        Matrix4.identity() * (accuracy * measurementNoise);
    Matrix4 SInv = Matrix4.inverted(S);
    Matrix4 K = PPred * HTranspose * SInv;

    // Measurement: z = [lat, lng, 0, 0]
    Vector4 z = Vector4(latitude, longitude, 0, 0);

    // Innovation: y = z - H * x_pred
    Vector4 innovation = z - _H.transform(xPred);

    // State update: x = x_pred + K * y
    _x = xPred + K.transform(innovation);

    // Covariance update: P = (I - K * H) * P_pred
    Matrix4 I = Matrix4.identity();
    _P = (I - K * _H) * PPred;

    // Return filtered position
    Log.d('KalmanFilter: Output lat=${_x.x}, lng=${_x.y}');
    return {'latitude': _x.x, 'longitude': _x.y};
  }
}
