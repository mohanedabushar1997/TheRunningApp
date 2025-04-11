import 'package:flutter/material.dart';
// TODO: Import Music Provider or Service
// import 'package:provider/provider.dart';
// import 'package/running_app/presentation/providers/music_provider.dart';
import 'package/running_app/presentation/widgets/settings/music_settings_widget.dart'; // Import widget

class MusicSettingsScreen extends StatelessWidget {
  const MusicSettingsScreen({super.key});
  static const routeName = '/settings/music'; // Optional route name

  @override
  Widget build(BuildContext context) {
     // TODO: Get actual settings state from provider
     // final musicProvider = context.watch<MusicProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Settings'),
      ),
      // Use the dedicated settings widget
       body: MusicSettingsWidget(
          // Pass current values and callbacks
           // Example values (replace with actual state)
           musicServiceConnected: 'None', // e.g., 'Spotify', 'Apple Music', 'Local Files', 'None'
           duckAudioEnabled: true,
           autoResumeEnabled: false,

           // TODO: Implement callbacks to update provider/service state
            onConnectService: (service) {
                // Handle logic to connect to Spotify/Apple Music SDK etc.
            },
            onDuckAudioChanged: (value) {
                // Update provider/service setting
            },
            onAutoResumeChanged: (value) {
                // Update provider/service setting
            },
       ),
    );
  }
}