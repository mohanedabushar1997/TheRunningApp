import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Mock enum to replace battery_plus's BatteryState enum
enum BatteryState { full, charging, discharging, unknown }

/// Service for monitoring battery status and optimizing power usage.
/// This is a basic implementation that uses mock data for demonstration purposes.
class BatteryService {
  // Singleton pattern
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  // Stream controllers for battery level changes
  final _batteryLevelController = StreamController<int>.broadcast();

  // Stream controller for battery state changes
  final _batteryStateController = StreamController<BatteryState>.broadcast();

  // Current battery level
  int _currentBatteryLevel = 85; // Mock starting battery level

  // Current battery state
  BatteryState _currentBatteryState = BatteryState.discharging;

  // Flag to check if battery optimization is enabled
  bool _isOptimizationEnabled = true;

  // Mock battery drain timer
  Timer? _batteryDrainTimer;

  // Getters
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;
  Stream<BatteryState> get batteryStateStream => _batteryStateController.stream;
  int get currentBatteryLevel => _currentBatteryLevel;
  BatteryState get currentBatteryState => _currentBatteryState;
  bool get isOptimizationEnabled => _isOptimizationEnabled;
  bool get isCharging =>
      _currentBatteryState == BatteryState.charging ||
      _currentBatteryState == BatteryState.full;

  /// Initialize the battery service
  Future<void> initialize() async {
    // Simulate battery level changes
    _startMockBatteryLevelChanges();

    // Broadcast initial values
    _batteryLevelController.add(_currentBatteryLevel);
    _batteryStateController.add(_currentBatteryState);
  }

  /// Start simulating battery level changes for demo purposes
  void _startMockBatteryLevelChanges() {
    // Cancel any existing timer
    _batteryDrainTimer?.cancel();

    // Simulate battery drain every 20 seconds in discharging state
    // Simulate battery charge every 15 seconds in charging state
    _batteryDrainTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (_currentBatteryState == BatteryState.discharging) {
        // Simulate battery drain
        _currentBatteryLevel = max(0, _currentBatteryLevel - 1);

        // Random charging event (10% chance)
        if (Random().nextDouble() < 0.1) {
          _currentBatteryState = BatteryState.charging;
          _batteryStateController.add(_currentBatteryState);
        }

        // If battery gets too low, simulate plugging in
        if (_currentBatteryLevel < 15 && Random().nextDouble() < 0.3) {
          _currentBatteryState = BatteryState.charging;
          _batteryStateController.add(_currentBatteryState);
        }
      } else if (_currentBatteryState == BatteryState.charging) {
        // Simulate battery charging
        _currentBatteryLevel = min(100, _currentBatteryLevel + 2);

        // Random unplug event (5% chance)
        if (Random().nextDouble() < 0.05) {
          _currentBatteryState = BatteryState.discharging;
          _batteryStateController.add(_currentBatteryState);
        }

        // If battery gets full, change state to full
        if (_currentBatteryLevel >= 100) {
          _currentBatteryLevel = 100;
          _currentBatteryState = BatteryState.full;
          _batteryStateController.add(_currentBatteryState);
        }
      } else if (_currentBatteryState == BatteryState.full) {
        // Random unplug event (15% chance when full)
        if (Random().nextDouble() < 0.15) {
          _currentBatteryState = BatteryState.discharging;
          _batteryStateController.add(_currentBatteryState);
        }
      }

      // Broadcast battery level
      _batteryLevelController.add(_currentBatteryLevel);
    });
  }

  /// Enable or disable battery optimization
  void setBatteryOptimization(bool enabled) {
    _isOptimizationEnabled = enabled;
  }

  /// Get recommended location sampling interval based on battery level
  Duration getRecommendedSamplingInterval() {
    if (!_isOptimizationEnabled) {
      return const Duration(seconds: 1); // Default high sampling rate
    }

    // If charging, use higher sampling rate
    if (isCharging) {
      return const Duration(seconds: 1);
    }

    // Adjust sampling rate based on battery level
    if (_currentBatteryLevel > 50) {
      return const Duration(seconds: 2);
    } else if (_currentBatteryLevel > 25) {
      return const Duration(seconds: 3);
    } else if (_currentBatteryLevel > 15) {
      return const Duration(seconds: 5);
    } else {
      return const Duration(
        seconds: 10,
      ); // Low battery, reduce sampling rate significantly
    }
  }

  /// Get recommended location distance filter based on battery level
  int getRecommendedDistanceFilter() {
    if (!_isOptimizationEnabled) {
      return 3; // Default low distance filter (meters)
    }

    // If charging, use lower distance filter
    if (isCharging) {
      return 3;
    }

    // Adjust distance filter based on battery level
    if (_currentBatteryLevel > 50) {
      return 5;
    } else if (_currentBatteryLevel > 25) {
      return 8;
    } else if (_currentBatteryLevel > 15) {
      return 10;
    } else {
      return 15; // Low battery, increase distance filter to reduce updates
    }
  }

  /// Get recommended location accuracy based on battery level
  LocationAccuracy getRecommendedLocationAccuracy() {
    if (!_isOptimizationEnabled) {
      return LocationAccuracy.best;
    }

    // If charging, use highest accuracy
    if (isCharging) {
      return LocationAccuracy.best;
    }

    // Adjust accuracy based on battery level
    if (_currentBatteryLevel > 50) {
      return LocationAccuracy.high;
    } else if (_currentBatteryLevel > 25) {
      return LocationAccuracy.medium;
    } else {
      return LocationAccuracy.low; // Low battery, reduce accuracy to save power
    }
  }

  /// Dispose of resources
  void dispose() {
    _batteryDrainTimer?.cancel();
    _batteryLevelController.close();
    _batteryStateController.close();
  }
}

/// Extension on LocationAccuracy enum to get string representation
extension LocationAccuracyExtension on LocationAccuracy {
  String get name {
    switch (this) {
      case LocationAccuracy.lowest:
        return 'Lowest';
      case LocationAccuracy.low:
        return 'Low';
      case LocationAccuracy.medium:
        return 'Medium';
      case LocationAccuracy.high:
        return 'High';
      case LocationAccuracy.best:
        return 'Best';
      case LocationAccuracy.reduced:
        return 'Reduced';
      default:
        return 'Unknown';
    }
  }
}
