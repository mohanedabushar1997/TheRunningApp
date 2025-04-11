import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/device/services/battery_service.dart';
import 'package:running_app/utils/logger.dart';

class BatteryUsageWidget extends StatefulWidget {
  const BatteryUsageWidget({super.key});

  @override
  State<BatteryUsageWidget> createState() => _BatteryUsageWidgetState();
}

class _BatteryUsageWidgetState extends State<BatteryUsageWidget> {
   int _batteryLevel = -1;
   StreamSubscription? _batterySubscription;

   @override
   void initState() {
     super.initState();
     _initBatteryLevel();
      try {
         final batteryService = context.read<BatteryService>();
          _batterySubscription = batteryService.onBatteryLevelChange.listen((level) {
             if (mounted) setState(() { _batteryLevel = level; });
          });
      } catch (e) { Log.e("BatteryService not found or failed to subscribe: $e"); }
   }

   Future<void> _initBatteryLevel() async {
      try {
         final batteryService = context.read<BatteryService>();
         final level = await batteryService.getCurrentBatteryLevel();
          if (mounted) setState(() { _batteryLevel = level; });
      } catch (e) {
         Log.w("Failed to get initial battery level for widget: $e");
         if (mounted) setState(() { _batteryLevel = -1; });
      }
   }

   @override
   void dispose() { _batterySubscription?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
     IconData batteryIcon;
     Color iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

      if (_batteryLevel < 0) { batteryIcon = Icons.battery_unknown; }
      else if (_batteryLevel <= 15) { batteryIcon = Icons.battery_alert_rounded; iconColor = Colors.red.shade700; }
      else if (_batteryLevel <= 30) { batteryIcon = Icons.battery_3_bar_rounded; iconColor = Colors.orange.shade700; }
      else if (_batteryLevel <= 50) { batteryIcon = Icons.battery_4_bar_rounded; iconColor = Colors.amber.shade700; }
      else if (_batteryLevel <= 80) { batteryIcon = Icons.battery_5_bar_rounded; iconColor = Colors.lightGreen.shade700; }
      else { batteryIcon = Icons.battery_full_rounded; iconColor = Colors.green.shade700; }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
         Icon(batteryIcon, size: 18, color: iconColor),
          const SizedBox(width: 4),
          Text(
             _batteryLevel >= 0 ? '$_batteryLevel%' : '--%',
             style: Theme.of(context).textTheme.labelMedium?.copyWith(color: iconColor, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}