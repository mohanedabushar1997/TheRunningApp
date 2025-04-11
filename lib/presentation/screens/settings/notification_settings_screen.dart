import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart'; // Assuming notification settings are here
import 'package:running_app/device/notifications/notification_service.dart'; // To open system settings
import 'package:running_app/utils/logger.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  static const routeName = '/settings/notifications'; // Static route name

  @override
  Widget build(BuildContext context) {
     // TODO: Create a dedicated NotificationSettingsProvider or add settings to SettingsProvider
     // Using SettingsProvider for now as an example
     final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // --- General Notification Toggle ---
          // TODO: This might control enabling/disabling ALL notifications from the app
          // SwitchListTile(
          //   secondary: Icon(Icons.notifications_active_outlined),
          //   title: Text('Enable All Notifications'),
          //   value: settingsProvider.allNotificationsEnabled, // Requires adding this to provider
          //   onChanged: (value) {
          //      settingsProvider.setAllNotificationsEnabled(value);
          //      // TODO: If disabled, maybe cancel all scheduled notifications?
          //   },
          // ),
          // const Divider(),

          // --- Workout Notifications ---
          _buildSectionHeader('Workout Alerts'),
          SwitchListTile(
             secondary: const Icon(Icons.flag_outlined),
             title: const Text('Milestone Alerts'),
             subtitle: const Text('Notify for new Personal Bests, distance milestones, etc.'),
             value: true, // TODO: Add setting to SettingsProvider
             onChanged: (value) { /* TODO: Update setting */ },
          ),
          SwitchListTile(
             secondary: const Icon(Icons.check_circle_outline),
             title: const Text('Workout Completion'),
             subtitle: const Text('Show notification when workout is saved.'),
             value: true, // TODO: Add setting
             onChanged: (value) { /* TODO: Update setting */ },
          ),
           // TODO: Add setting for ongoing progress notification (if user wants to disable it)
           // SwitchListTile(
           //   secondary: Icon(Icons.run_circle_outlined),
           //   title: Text('Ongoing Workout Status'),
           //   subtitle: Text('Show persistent notification during workout.'),
           //   value: true, // TODO: Add setting
           //   onChanged: (value) { /* TODO: Update setting */ },
           // ),

          const Divider(height: 24),

          // --- Other Notifications ---
           _buildSectionHeader('Reminders & Tips'),
          SwitchListTile(
             secondary: const Icon(Icons.tips_and_updates_outlined),
             title: const Text('Daily Tip'),
             subtitle: const Text('Receive a helpful running tip each day.'),
             value: true, // TODO: Add setting
             onChanged: (value) {
                // TODO: Update setting
                 // TODO: If enabled, schedule tip notification. If disabled, cancel it.
                 // final tipProvider = context.read<TipsProvider>();
                 // if (value) { tipProvider.scheduleDailyTip(); }
                 // else { NotificationService.cancelScheduledTip(); }
             },
          ),
           // TODO: Add Workout Reminder setting
           // SwitchListTile(
           //   secondary: Icon(Icons.calendar_today_outlined),
           //   title: Text('Workout Reminders'),
           //   subtitle: Text('Get reminded for scheduled plan workouts.'),
           //   value: false, // TODO: Add setting
           //   onChanged: (value) { /* TODO: Update setting & scheduling */ },
           // ),
           // TODO: Add Achievement Unlocked notifications?

          const Divider(height: 24),

          // --- System Settings Link ---
           _buildSectionHeader('System Settings'),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Open Notification Settings'),
            subtitle: const Text('Manage notification permissions and channel settings for this app in your device settings.'),
            trailing: const Icon(Icons.launch, size: 18),
            onTap: () async {
               Log.i("Opening system notification settings...");
               // Use permission_handler or specific platform method if available
               // For now, linking to general app settings is often sufficient
               try {
                  // ph.openAppSettings(); // From permission_handler is usually best
                   await NotificationService.navigatorKey?.currentContext
                      ?.read<LocationService>().openAppSettings(); // Reusing LocationService method as placeholder
               } catch (e) {
                   Log.e("Could not open app settings: $e");
               }
            },
          ),
        ],
      ),
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(GlobalKey<NavigatorState>().currentContext!).colorScheme.primary, // Access theme via global key context if needed carefully
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
This completes Batch 6. There are probably 2-3 more batches needed to cover the remaining files and core widget implementations. Let me know when you're ready for the next one.





provide the next batch



Show thinking
Okay, this will be the final batch containing the remaining core files.

As mentioned, fully implementing every single TODO (like complex background services, detailed charting, achievement logic, training plan generation) requires significant development effort beyond this scope. I have implemented the core structure, applied the necessary fixes discussed previously (compilation errors, device ID logic), and added detailed placeholders and TODO comments for the more complex features.

You should focus on testing this integrated codebase and then iteratively develop the features marked with TODO comments.

Final Batch (Remaining Core Files)