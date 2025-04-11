import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// Service for monitoring battery status and optimizing power usage.
/// Enhanced with real battery monitoring and device-specific optimizations.
class EnhancedBatteryService {
  // Singleton pattern
  static final EnhancedBatteryService _instance = EnhancedBatteryService._internal();
  factory EnhancedBatteryService() => _instance;
  EnhancedBatteryService._internal();

  // Platform battery service
  final Battery _battery = Battery();
  
  // Device info
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Stream controllers for battery level changes
  final _batteryLevelController = StreamController<int>.broadcast();

  // Stream controller for battery state changes
  final _batteryStateController = StreamController<BatteryState>.broadcast();

  // Current battery level
  int _currentBatteryLevel = 85; // Default until we get real data

  // Current battery state
  BatteryState _currentBatteryState = BatteryState.discharging;

  // Flag to check if battery optimization is enabled
  bool _isOptimizationEnabled = true;
  
  // Device-specific settings
  bool _isLowEndDevice = false;
  bool _isHighEndDevice = false;
  String _deviceModel = "unknown";
  
  // Battery drain rate tracking
  int _lastBatteryLevel = 0;
  DateTime _lastBatteryCheckTime = DateTime.now();
  double _batteryDrainRatePerHour = 0.0; // % per hour
  
  // Power saving mode detection
  bool _isPowerSavingModeEnabled = false;

  // Getters
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;
  Stream<BatteryState> get batteryStateStream => _batteryStateController.stream;
  int get currentBatteryLevel => _currentBatteryLevel;
  BatteryState get currentBatteryState => _currentBatteryState;
  bool get isOptimizationEnabled => _isOptimizationEnabled;
  bool get isCharging =>
      _currentBatteryState == BatteryState.charging ||
      _currentBatteryState == BatteryState.full;
  bool get isPowerSavingModeEnabled => _isPowerSavingModeEnabled;
  bool get isLowEndDevice => _isLowEndDevice;
  double get batteryDrainRatePerHour => _batteryDrainRatePerHour;

  /// Initialize the battery service
  Future<void> initialize() async {
    // Get device info to determine device capabilities
    await _detectDeviceCapabilities();
    
    // Get initial battery level
    try {
      _currentBatteryLevel = await _battery.batteryLevel;
      _lastBatteryLevel = _currentBatteryLevel;
      _batteryLevelController.add(_currentBatteryLevel);
    } catch (e) {
      print('Error getting battery level: $e');
    }
    
    // Get initial battery state
    try {
      final batteryState = await _battery.batteryState;
      _updateBatteryState(batteryState);
    } catch (e) {
      print('Error getting battery state: $e');
    }
    
    // Listen for battery level changes
    _battery.onBatteryStateChanged.listen(_updateBatteryState);
    
    // Start periodic battery level checks
    Timer.periodic(const Duration(minutes: 2), (_) async {
      await _updateBatteryLevel();
      _calculateBatteryDrainRate();
      await _checkPowerSavingMode();
    });
    
    // Do an immediate update
    await _updateBatteryLevel();
    await _checkPowerSavingMode();
  }
  
  /// Detect device capabilities to optimize battery usage
  Future<void> _detectDeviceCapabilities() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = androidInfo.model;
        
        // Check if this is a low-end device based on RAM
        // Less than 3GB RAM is considered low-end
        final int ramInGB = androidInfo.totalMemory ~/ (1024 * 1024 * 1024);
        _isLowEndDevice = ramInGB < 3;
        _isHighEndDevice = ramInGB >= 6;
        
        print('Device model: $_deviceModel, RAM: ${ramInGB}GB');
        print('Device classification: ${_isLowEndDevice ? "Low-end" : _isHighEndDevice ? "High-end" : "Mid-range"}');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        
        // Determine device capabilities based on model
        // This is a simplified approach - in a real app, you'd have a more comprehensive list
        final isOlderDevice = _deviceModel.contains('iPhone 6') || 
                             _deviceModel.contains('iPhone 7') || 
                             _deviceModel.contains('iPhone 8');
        
        _isLowEndDevice = isOlderDevice;
        _isHighEndDevice = !isOlderDevice && !_deviceModel.contains('iPhone SE');
        
        print('Device model: $_deviceModel');
        print('Device classification: ${_isLowEndDevice ? "Low-end" : _isHighEndDevice ? "High-end" : "Mid-range"}');
      }
    } catch (e) {
      print('Error detecting device capabilities: $e');
      // Default to mid-range device if detection fails
      _isLowEndDevice = false;
      _isHighEndDevice = false;
    }
  }
  
  /// Update battery state from platform
  void _updateBatteryState(BatteryState state) {
    _currentBatteryState = state;
    _batteryStateController.add(_currentBatteryState);
  }
  
  /// Update battery level from platform
  Future<void> _updateBatteryLevel() async {
    try {
      final newLevel = await _battery.batteryLevel;
      if (newLevel != _currentBatteryLevel) {
        _currentBatteryLevel = newLevel;
        _batteryLevelController.add(_currentBatteryLevel);
      }
    } catch (e) {
      print('Error updating battery level: $e');
    }
  }
  
  /// Calculate battery drain rate
  void _calculateBatteryDrainRate() {
    if (_currentBatteryState == BatteryState.discharging && 
        _lastBatteryLevel > _currentBatteryLevel) {
      final now = DateTime.now();
      final hoursSinceLastCheck = now.difference(_lastBatteryCheckTime).inSeconds / 3600;
      
      if (hoursSinceLastCheck > 0) {
        final levelDrop = _lastBatteryLevel - _currentBatteryLevel;
        _batteryDrainRatePerHour = levelDrop / hoursSinceLastCheck;
        print('Battery drain rate: $_batteryDrainRatePerHour% per hour');
      }
    }
    
    _lastBatteryLevel = _currentBatteryLevel;
    _lastBatteryCheckTime = DateTime.now();
  }
  
  /// Check if power saving mode is enabled
  Future<void> _checkPowerSavingMode() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // On Android, we can detect power saving mode
        // This is a mock implementation - in a real app, you'd use a platform channel
        _isPowerSavingModeEnabled = _currentBatteryLevel < 20;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS doesn't provide direct access to Low Power Mode
        // We'll infer it from battery level and drain rate
        _isPowerSavingModeEnabled = _currentBatteryLevel < 20 || _batteryDrainRatePerHour > 10;
      }
    } catch (e) {
      print('Error checking power saving mode: $e');
    }
  }

  /// Enable or disable battery optimization
  void setBatteryOptimization(bool enabled) {
    _isOptimizationEnabled = enabled;
  }

  /// Get recommended location sampling interval based on battery level and device
  Duration getRecommendedSamplingInterval() {
    if (!_isOptimizationEnabled) {
      return const Duration(seconds: 1); // Default high sampling rate
    }

    // If charging, use higher sampling rate but still consider device capabilities
    if (isCharging) {
      return _isLowEndDevice 
          ? const Duration(seconds: 2) 
          : const Duration(seconds: 1);
    }
    
    // If power saving mode is enabled, use very conservative settings
    if (_isPowerSavingModeEnabled) {
      return const Duration(seconds: 15);
    }

    // Adjust sampling rate based on battery level and device capabilities
    if (_currentBatteryLevel > 50) {
      return _isLowEndDevice 
          ? const Duration(seconds: 3) 
          : const Duration(seconds: 2);
    } else if (_currentBatteryLevel > 25) {
      return _isLowEndDevice 
          ? const Duration(seconds: 5) 
          : const Duration(seconds: 3);
    } else if (_currentBatteryLevel > 15) {
      return _isLowEndDevice 
          ? const Duration(seconds: 8) 
          : const Duration(seconds: 5);
    } else {
      return _isLowEndDevice 
          ? const Duration(seconds: 15) 
          : const Duration(seconds: 10);
    }
  }

  /// Get recommended location distance filter based on battery level and device
  int getRecommendedDistanceFilter() {
    if (!_isOptimizationEnabled) {
      return 3; // Default low distance filter (meters)
    }

    // If charging, use lower distance filter but still consider device capabilities
    if (isCharging) {
      return _isLowEndDevice ? 5 : 3;
    }
    
    // If power saving mode is enabled, use very conservative settings
    if (_isPowerSavingModeEnabled) {
      return 20;
    }

    // Adjust distance filter based on battery level and device capabilities
    if (_currentBatteryLevel > 50) {
      return _isLowEndDevice ? 8 : 5;
    } else if (_currentBatteryLevel > 25) {
      return _isLowEndDevice ? 12 : 8;
    } else if (_currentBatteryLevel > 15) {
      return _isLowEndDevice ? 15 : 10;
    } else {
      return _isLowEndDevice ? 20 : 15;
    }
  }

  /// Get recommended location accuracy based on battery level and device
  LocationAccuracy getRecommendedLocationAccuracy() {
    if (!_isOptimizationEnabled) {
      return _isHighEndDevice 
          ? LocationAccuracy.best 
          : LocationAccuracy.high;
    }

    // If charging, use highest accuracy appropriate for the device
    if (isCharging) {
      return _isHighEndDevice 
          ? LocationAccuracy.best 
          : _isLowEndDevice 
              ? LocationAccuracy.medium 
              : LocationAccuracy.high;
    }
    
    // If power saving mode is enabled, use very conservative settings
    if (_isPowerSavingModeEnabled) {
      return LocationAccuracy.low;
    }

    // Adjust accuracy based on battery level and device capabilities
    if (_currentBatteryLevel > 50) {
      return _isHighEndDevice 
          ? LocationAccuracy.best 
          : _isLowEndDevice 
              ? LocationAccuracy.medium 
              : LocationAccuracy.high;
    } else if (_currentBatteryLevel > 25) {
      return _isHighEndDevice 
          ? LocationAccuracy.high 
          : _isLowEndDevice 
              ? LocationAccuracy.low 
              : LocationAccuracy.medium;
    } else {
      return _isLowEndDevice 
          ? LocationAccuracy.lowest 
          : LocationAccuracy.low;
    }
  }
  
  /// Get estimated remaining battery life in hours based on current drain rate
  double getEstimatedRemainingBatteryLife() {
    if (isCharging || _batteryDrainRatePerHour <= 0) {
      return double.infinity; // Charging or no drain detected
    }
    
    return _currentBatteryLevel / _batteryDrainRatePerHour;
  }
  
  /// Get battery optimization recommendations for the user
  Map<String, String> getBatteryOptimizationTips() {
    final tips = <String, String>{};
    
    if (_batteryDrainRatePerHour > 15) {
      tips['High Battery Drain'] = 'Your battery is draining quickly. Consider reducing location accuracy or increasing the distance filter.';
    }
    
    if (_currentBatteryLevel < 20 && !isCharging) {
      tips['Low Battery'] = 'Battery level is low. Connect to a charger or enable power saving mode.';
    }
    
    if (_isLowEndDevice && _batteryDrainRatePerHour > 10) {
      tips['Device Performance'] = 'Your device may experience performance issues with high-accuracy tracking. Consider using medium accuracy.';
    }
    
    return tips;
  }

  /// Dispose of resources
  void dispose() {
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
