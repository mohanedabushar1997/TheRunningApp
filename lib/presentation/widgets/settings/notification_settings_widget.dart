import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class NotificationSettingsWidget extends StatelessWidget {
  const NotificationSettingsWidget({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitch({
      required BuildContext context, required IconData icon, required String title,
      String? subtitle, required bool value, required bool enabled, required ValueChanged<bool> onChanged,
   }) {
      return SwitchListTile(
         secondary: Icon(icon, color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey),
         title: Text(title),
         subtitle: subtitle != null ? Text(subtitle) : null,
         value: value,
         onChanged: enabled ? onChanged : null,
         activeColor: Theme.of(context).colorScheme.primary,
         contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      );
   }

  @override
  Widget build(BuildContext context) {
     // TODO: Get actual settings values from SettingsProvider
     // Need to add relevant fields and methods (e.g., setMilestoneNotifications) to SettingsProvider
     final settingsProvider = context.watch<SettingsProvider>();
     bool allEnabled = true; // Placeholder
     bool milestonesEnabled = true; // Placeholder
     bool completionEnabled = true; // Placeholder
     bool progressEnabled = true; // Placeholder
     bool dailyTipEnabled = true; // Placeholder
     bool remindersEnabled = false; // Placeholder

    return ListView(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       children: [
           _buildSectionHeader(context, 'Workout Alerts'),
          _buildSwitch(
             context: context, icon: Icons.emoji_events_outlined,
             title: 'Milestone Alerts', subtitle: 'Notify for new PBs, distance milestones.',
             value: milestonesEnabled, enabled: allEnabled,
             onChanged: (value) { Log.w("TODO: Update milestonesEnabled setting"); /* settingsProvider.setMilestoneNotifications(value); */ },
          ),
          _buildSwitch(
             context: context, icon: Icons.check_circle_outline,
             title: 'Workout Completion', subtitle: 'Show notification when workout saves.',
             value: completionEnabled, enabled: allEnabled,
             onChanged: (value) { Log.w("TODO: Update completionEnabled setting"); /* settingsProvider.setCompletionNotifications(value); */ },
          ),
           _buildSwitch(
              context: context, icon: Icons.timer_outlined,
              title: 'Ongoing Workout Status', subtitle: 'Show persistent notification during workout.',
              value: progressEnabled, enabled: allEnabled,
              onChanged: (value) { Log.w("TODO: Update progressEnabled setting"); /* settingsProvider.setOngoingNotifications(value); */ },
           ),
          const Divider(height: 24),
           _buildSectionHeader(context, 'Reminders & Tips'),
           _buildSwitch(
              context: context, icon: Icons.tips_and_updates_outlined,
              title: 'Daily Tip', subtitle: 'Receive a running tip each day.',
              value: dailyTipEnabled, enabled: allEnabled,
              onChanged: (value) { Log.w("TODO: Update dailyTipEnabled setting & scheduling"); /* settingsProvider.setDailyTipNotifications(value); */ },
           ),
           _buildSwitch(
              context: context, icon: Icons.calendar_today_outlined,
              title: 'Workout Reminders', subtitle: 'Remind for scheduled plan workouts (Coming Soon).',
              value: remindersEnabled, enabled: false,
              onChanged: (value) { /* TODO: Update setting */ },
           ),
          const Divider(height: 24),
           _buildSectionHeader(context, 'System Settings'),
           ListTile(
             leading: const Icon(Icons.settings_outlined),
             title: const Text('Open Notification Settings'),
             subtitle: const Text('Manage app permissions and channels.'),
             trailing: const Icon(Icons.launch, size: 18),
             onTap: () async { Log.i("Opening system app settings..."); try { await ph.openAppSettings(); } catch (e) { Log.e("Could not open app settings: $e"); } },
           ),
       ],
    );
  }
}