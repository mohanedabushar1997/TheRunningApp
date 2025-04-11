import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:running_app/utils/logger.dart';

class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription? _batteryStateSubscription;
  int _lastBatteryLevel = -1;
  BatteryState _lastBatteryState = BatteryState.unknown;

  // Stream controller to broadcast significant changes
  final _batteryChangeController = StreamController<int>.broadcast();
  Stream<int> get onBatteryLevelChange => _batteryChangeController.stream; // Stream for UI updates

   // Stream for critical low battery events
   final _lowBatteryController = StreamController<void>.broadcast();
   Stream<void> get onLowBatteryWarning => _lowBatteryController.stream;

  // --- Initialization ---
  Future<void> initialize() async {
    Log.i("Initializing Battery Service...");
    try {
      _lastBatteryLevel = await _battery.batteryLevel;
      _lastBatteryState = await _battery.batteryState;
       Log.i("Initial Battery Level: $_lastBatteryLevel%, State: $_lastBatteryState");
      _startListening();
    } catch (e, s) {
       Log.e("Failed to get initial battery state", error: e, stackTrace: s);
    }
  }

  void _startListening() {
    _batteryStateSubscription?.cancel(); // Cancel previous subscription if any
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
       Log.d("Battery State Changed: $state");
        _lastBatteryState = state;
        // Optionally notify listeners or perform actions based on state (charging, full, discharging)
         // _batteryChangeController.add(_lastBatteryLevel); // Notify on state change too?
    });

    // Battery level monitoring (battery_plus doesn't have a stream for level)
     // We need to poll it periodically or rely only on state changes.
     // Let's poll less frequently to save battery itself.
     Timer.periodic(const Duration(minutes: 2), (timer) async {
        if (_batteryStateSubscription == null) { // Stop polling if listener stopped
           timer.cancel();
           return;
        }
         try {
            int currentLevel = await _battery.batteryLevel;
             if (currentLevel != _lastBatteryLevel) {
                 Log.i("Battery Level Changed: $_lastBatteryLevel% -> $currentLevel%");
                 _lastBatteryLevel = currentLevel;
                 _batteryChangeController.add(currentLevel); // Notify listeners of level change

                 // --- Low Battery Check ---
                  // TODO: Make low battery threshold configurable (SettingsProvider)
                 int lowBatteryThreshold = 20;
                  if (currentLevel <= lowBatteryThreshold && _lastBatteryState == BatteryState.discharging) {
                      Log.w("Low Battery Warning! Level: $currentLevel%");
                      _lowBatteryController.add(null); // Trigger low battery warning event
                      // TODO: Trigger low battery notification via NotificationService
                       // NotificationService.showLowBatteryWarning(currentLevel);
                  }
             }
         } catch (e) {
            Log.w("Failed to poll battery level: $e");
         }
     });

     Log.i("Started listening to battery state changes.");
  }

  // --- Getters ---
  Future<int> getCurrentBatteryLevel() async {
     try {
        return await _battery.batteryLevel;
     } catch (e) {
         Log.w("Failed to get current battery level: $e");
         return _lastBatteryLevel; // Return last known value
     }
  }

  Future<BatteryState> getCurrentBatteryState() async {
     try {
        return await _battery.batteryState;
     } catch (e) {
          Log.w("Failed to get current battery state: $e");
          return _lastBatteryState; // Return last known value
     }
  }

   Future<bool> isInBatterySaveMode() async {
      try {
         return await _battery.isInBatterySaveMode;
      } catch (e) {
          Log.w("Failed to check battery save mode: $e");
          return false;
      }
   }

  // --- Dispose ---
  void dispose() {
    Log.d("Disposing Battery Service.");
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
     _batteryChangeController.close();
     _lowBatteryController.close();
  }
}