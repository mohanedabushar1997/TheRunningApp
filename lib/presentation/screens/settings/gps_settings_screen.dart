import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart';
import 'package:running_app/utils/logger.dart';
// Import LocationService if showing live accuracy/status
// import 'package:running_app/device/gps/location_service.dart';
// import 'package:geolocator/geolocator.dart';

class GpsSettingsScreen extends StatelessWidget {
  const GpsSettingsScreen({super.key});
  static const routeName = '/settings/gps'; // Static route name

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    // final locationService = context.read<LocationService>(); // Optional: For live status

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // --- GPS Accuracy Preference ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Tracking Accuracy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                 color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          RadioListTile<GpsAccuracyPreference>(
            title: const Text('High Accuracy'),
            subtitle: const Text('Best for precise tracking (uses more battery).'),
            value: GpsAccuracyPreference.high,
            groupValue: settingsProvider.gpsAccuracy,
            onChanged: (value) {
              if (value != null) settingsProvider.setGpsAccuracy(value);
            },
          ),
          RadioListTile<GpsAccuracyPreference>(
            title: const Text('Balanced'),
            subtitle: const Text('Good accuracy with moderate battery use.'),
            value: GpsAccuracyPreference.balanced,
            groupValue: settingsProvider.gpsAccuracy,
            onChanged: (value) {
              if (value != null) settingsProvider.setGpsAccuracy(value);
            },
          ),
          RadioListTile<GpsAccuracyPreference>(
            title: const Text('Power Saving'),
            subtitle: const Text('Lower accuracy, saves battery.'),
            value: GpsAccuracyPreference.low,
            groupValue: settingsProvider.gpsAccuracy,
            onChanged: (value) {
              if (value != null) settingsProvider.setGpsAccuracy(value);
            },
          ),
          const Divider(height: 24),

          // --- Distance Filter ---
          // TODO: Implement Distance Filter setting
          // ListTile(
          //    leading: Icon(Icons.filter_alt_outlined),
          //    title: Text('Distance Filter'),
          //    subtitle: Text('Receive updates every X meters (0 = disabled)'),
          //    // Add Slider or Number Input
          // ),
          // const Divider(height: 24),


          // --- Current Status (Example) ---
           // TODO: Show current GPS status/accuracy (requires LocationService stream/state)
           // Padding(
           //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
           //   child: Text(
           //     'Current Status',
           //     style: Theme.of(context).textTheme.titleMedium?.copyWith(
           //       color: Theme.of(context).colorScheme.primary,
           //     ),
           //   ),
           // ),
           // StreamBuilder<Position>( // Example using stream
           //    stream: locationService.getPositionStream( /* temporary settings? */ ),
           //    builder: (context, snapshot) {
           //       String statusText = 'Checking...';
           //       IconData statusIcon = Icons.gps_not_fixed;
           //       Color statusColor = Colors.grey;
           //
           //       if (snapshot.hasError) {
           //          statusText = 'Error: ${snapshot.error}';
           //          statusIcon = Icons.gps_off;
           //          statusColor = Colors.red;
           //       } else if (snapshot.hasData) {
           //          statusText = 'Accuracy: ${snapshot.data!.accuracy.toStringAsFixed(1)}m';
           //          statusIcon = Icons.gps_fixed;
           //          statusColor = Colors.green;
           //           if (snapshot.data!.accuracy > 50) statusColor = Colors.orange; // Example threshold
           //       }
           //
           //       return ListTile(
           //          leading: Icon(statusIcon, color: statusColor),
           //          title: Text(statusText),
           //          subtitle: const Text('Live GPS status (approximate)'),
           //       );
           //    },
           // ),

           // --- Settings Link ---
           ListTile(
             leading: const Icon(Icons.settings_outlined),
             title: const Text('Open Device Location Settings'),
             trailing: const Icon(Icons.launch, size: 18),
             onTap: () async {
                try {
                   await context.read<LocationService>().openLocationSettings();
                } catch (e) {
                   Log.e("Failed to open location settings: $e");
                }
             },
           ),
        ],
      ),
    );
  }
}
This completes Batch 5. There are approximately 2-3 more batches remaining (around 10-15 files, including screens like workout_details, tips, profile, onboarding, splash, various widgets, and potentially the background service). Let me know when you're ready for the next batch.





in the next batch provide me all the files left



Show thinking
Okay, I will provide the remaining core files in this final batch. Please note that due to the large number of remaining files and the complexity of implementing every single TODO comprehensively (especially those requiring extensive UI charting, background service logic, or complex algorithms like achievements and training plan generation), this batch focuses on:

Key Screens: Implementing the structure and essential logic for remaining primary screens (WorkoutDetails, Tips, Profile, Settings sub-screens, Onboarding, Splash).
Essential Widgets: Providing the code for common widgets used across screens.
Service Placeholders: Outlining the structure for background tracking and battery services with TODOs for detailed implementation.
Data Models: Basic structure for Achievement.
Provider Structure: Placeholder for TrainingPlanProvider.
Charting Placeholders: Placeholder widgets for charts using fl_chart.
You will need to further develop the placeholder implementations (marked with TODO) based on your specific requirements and testing.

There are still other minor widgets, utility files, or specific feature implementations mentioned in TODOs throughout the code that are not included here due to length constraints and the focus on core functionality.

Final Batch (Remaining Core Files)