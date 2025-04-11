import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/presentation/screens/settings/battery_optimization_screen.dart'; // Link to battery screen
import 'package:running_app/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart' as ph; // To open settings

class BackgroundServiceScreen extends StatelessWidget {
  const BackgroundServiceScreen({super.key});
  static const routeName = '/settings/background-service';

  @override
  Widget build(BuildContext context) {
    // TODO: Get background service settings from SettingsProvider
    final settingsProvider = context.watch<SettingsProvider>();
    // Example setting (add to SettingsProvider)
    // bool backgroundTrackingEnabled = settingsProvider.backgroundTrackingEnabled;
    bool backgroundTrackingEnabled = true; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Tracking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0), // Use less padding for list view
        children: [
           const ListTile(
             leading: Icon(Icons.run_circle_outlined),
             title: Text('How it Works'),
             subtitle: Text('Enabling background tracking allows FitStride to record your workout accurately even if you switch apps or lock your screen. This requires location access "While Using" or "Always" and disabling battery optimization.'),
           ),
           const Divider(),

           SwitchListTile(
              secondary: Icon(backgroundTrackingEnabled ? Icons.toggle_on : Icons.toggle_off, color: backgroundTrackingEnabled ? Theme.of(context).colorScheme.primary : Colors.grey, size: 36,),
              title: const Text('Enable Background Tracking'),
              subtitle: const Text('Allows workout recording when app is not in foreground.'),
               value: backgroundTrackingEnabled,
               onChanged: (value) {
                  Log.i("Setting Background Tracking Enabled: $value");
                   // TODO: Update setting in SettingsProvider
                   // settingsProvider.setBackgroundTrackingEnabled(value);
                   // TODO: Handle starting/stopping the actual service if needed here? Or rely on workout start/stop?
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Background Service control TODO')));
               },
           ),
            const Divider(),

            ListTile(
               leading: const Icon(Icons.battery_alert_outlined, color: Colors.orange),
               title: const Text('Battery Optimization'),
                subtitle: const Text('Disable to prevent tracking interruptions.'),
               trailing: const Icon(Icons.chevron_right),
               onTap: () => Navigator.pushNamed(context, BatteryOptimizationScreen.routeName),
            ),
             ListTile(
               leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
               title: const Text('Location Permissions'),
                subtitle: const Text('Requires "While Using" or "Always" access.'),
               trailing: const Icon(Icons.launch, size: 18),
               onTap: () async { await ph.openAppSettings(); }, // Open app settings directly
            ),
             ListTile(
               leading: const Icon(Icons.notifications_active_outlined, color: Colors.purple),
               title: const Text('Notification Settings'),
                subtitle: const Text('Ensure workout channel notifications are allowed.'),
               trailing: const Icon(Icons.launch, size: 18),
               onTap: () async { await ph.openAppSettings(); }, // Or specific notification settings page if possible
            ),

           // TODO: Add troubleshooting tips? Link to documentation?
        ],
      ),
    );
  }
}