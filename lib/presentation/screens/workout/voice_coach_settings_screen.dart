import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/presentation/providers/settings_provider.dart'; // Assuming root provider for settings
// Import the dedicated widget
import 'package:running_app/presentation/widgets/settings/voice_coach_settings_widget.dart';

class VoiceCoachSettingsScreen extends StatelessWidget {
  const VoiceCoachSettingsScreen({super.key});
  static const routeName = '/settings/voice-coach';

  @override
  Widget build(BuildContext context) {
    // If settings become complex, consider a dedicated VoiceCoachSettingsProvider
    // For now, assuming settings are managed within SettingsProvider
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Coach Settings'),
      ),
      // Use the dedicated settings widget for the body
      body: VoiceCoachSettingsWidget(
         // Pass current settings from provider
         // Example: Needs settings added to SettingsProvider first
         // isEnabled: settingsProvider.voiceCoachEnabled,
         // distanceIntervalKm: settingsProvider.voiceCoachDistanceInterval,
         // timeIntervalMinutes: settingsProvider.voiceCoachTimeInterval,
         // announcePace: settingsProvider.voiceCoachAnnouncePace,
         // announceSplits: settingsProvider.voiceCoachAnnounceSplits,
         // announceHeartRate: settingsProvider.voiceCoachAnnounceHR,
         // currentLanguage: settingsProvider.voiceCoachLanguage,
         // currentRate: settingsProvider.voiceCoachRate,
         // currentPitch: settingsProvider.voiceCoachPitch,

         // Placeholder values:
          isEnabled: true,
          distanceIntervalKm: 1.0,
          timeIntervalMinutes: 5.0,
          announcePace: true,
          announceSplits: true,
          announceHeartRate: false,
          currentLanguage: 'en-US',
          currentRate: 0.5,
          currentPitch: 1.0,

         // Callbacks to update settings in the provider
          onEnableChanged: (value) => settingsProvider.setVoiceCoachEnabled(value), // Add methods to SettingsProvider
          onDistanceIntervalChanged: (value) { /* settingsProvider.setVoiceCoachDistanceInterval(value); */ },
          onTimeIntervalChanged: (value) { /* settingsProvider.setVoiceCoachTimeInterval(value); */ },
          onAnnouncePaceChanged: (value) { /* settingsProvider.setVoiceCoachAnnouncePace(value); */ },
          onAnnounceSplitsChanged: (value) { /* ... */ },
          onAnnounceHeartRateChanged: (value) { /* ... */ },
          onLanguageChanged: (value) { /* ... */ },
          onRateChanged: (value) { /* ... */ },
          onPitchChanged: (value) { /* ... */ },
      ),
    );
  }
}