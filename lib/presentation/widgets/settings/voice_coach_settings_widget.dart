import 'package:flutter/material.dart';
import 'package:running_app/utils/logger.dart';

// TODO: Populate dropdowns with actual data (languages, intervals)

class VoiceCoachSettingsWidget extends StatelessWidget {
  // Current Settings Values
  final bool isEnabled;
  final double distanceIntervalKm;
  final double timeIntervalMinutes;
  final bool announcePace;
  final bool announceSplits;
  final bool announceHeartRate;
  final String? currentLanguage;
  final double? currentRate;
  final double? currentPitch;

  // Callbacks to update settings
  final ValueChanged<bool> onEnableChanged;
  final ValueChanged<double> onDistanceIntervalChanged;
  final ValueChanged<double> onTimeIntervalChanged;
  final ValueChanged<bool> onAnnouncePaceChanged;
  final ValueChanged<bool> onAnnounceSplitsChanged;
  final ValueChanged<bool> onAnnounceHeartRateChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<double> onPitchChanged;


  const VoiceCoachSettingsWidget({
    required this.isEnabled,
    required this.distanceIntervalKm,
    required this.timeIntervalMinutes,
    required this.announcePace,
    required this.announceSplits,
    required this.announceHeartRate,
    required this.currentLanguage,
    required this.currentRate,
    required this.currentPitch,
    required this.onEnableChanged,
    required this.onDistanceIntervalChanged,
    required this.onTimeIntervalChanged,
    required this.onAnnouncePaceChanged,
    required this.onAnnounceSplitsChanged,
    required this.onAnnounceHeartRateChanged,
    required this.onLanguageChanged,
    required this.onRateChanged,
    required this.onPitchChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
     final bool controlsEnabled = isEnabled;

    return ListView(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       children: [
          SwitchListTile(
             secondary: const Icon(Icons.volume_up_outlined),
             title: const Text('Enable Voice Coach'),
              value: isEnabled,
              onChanged: onEnableChanged,
          ),
           const Divider(),
            _buildSectionHeader(context, 'Announce Every'),
           ListTile(
              title: const Text('Distance Interval'),
              trailing: _buildDropdown<double>(
                 value: distanceIntervalKm, items: const [0.5, 1.0, 2.0, 5.0, 0.0],
                 displayBuilder: (val) => val == 0 ? 'Disabled' : '${val.toStringAsFixed(1)} km/mi', // TODO: Units
                 onChanged: controlsEnabled ? onDistanceIntervalChanged : null,
              ),
           ),
            ListTile(
               title: const Text('Time Interval'),
               trailing: _buildDropdown<double>(
                  value: timeIntervalMinutes, items: const [1.0, 2.0, 5.0, 10.0, 15.0, 0.0],
                  displayBuilder: (val) => val == 0 ? 'Disabled' : '${val.toInt()} min',
                  onChanged: controlsEnabled ? onTimeIntervalChanged : null,
               ),
            ),
           const Divider(),
            _buildSectionHeader(context, 'Announce Details'),
            _buildSwitch( title: 'Current Pace', value: announcePace, enabled: controlsEnabled, onChanged: onAnnouncePaceChanged, ),
            _buildSwitch( title: 'Split Times', subtitle: '(Every km/mile)', value: announceSplits, enabled: controlsEnabled, onChanged: onAnnounceSplitsChanged, ),
            _buildSwitch( title: 'Heart Rate Zone', subtitle: '(Requires HR Monitor)', value: announceHeartRate, enabled: controlsEnabled, onChanged: onAnnounceHeartRateChanged, ),
           const Divider(),
            _buildSectionHeader(context, 'Voice Options'),
            ListTile(title: const Text('Language'), trailing: Text(currentLanguage ?? 'System Default'), onTap: controlsEnabled ? () { Log.w("Language selection TODO"); } : null),
            ListTile(title: const Text('Speech Rate'), trailing: Text(currentRate?.toStringAsFixed(1) ?? 'Default'), onTap: controlsEnabled ? () { Log.w("Rate slider TODO"); } : null),
            ListTile(title: const Text('Pitch'), trailing: Text(currentPitch?.toStringAsFixed(1) ?? 'Default'), onTap: controlsEnabled ? () { Log.w("Pitch slider TODO"); } : null),
             Padding( padding: const EdgeInsets.all(16.0), child: ElevatedButton.icon( icon: const Icon(Icons.play_circle_outline), label: const Text('Play Sample'), onPressed: controlsEnabled ? () { Log.w("Play sample announcement TODO"); } : null, ), )
       ],
    );
  }

   Widget _buildDropdown<T>({ required T value, required List<T> items, required String Function(T) displayBuilder, required ValueChanged<T?>? onChanged, }) { /* ... (same as before) ... */ }
   Widget _buildSwitch({ required String title, String? subtitle, required bool value, required bool enabled, required ValueChanged<bool> onChanged, }) { /* ... (same as before) ... */ }
   Widget _buildSectionHeader(BuildContext context, String title) { /* ... (same as before) ... */ }
}