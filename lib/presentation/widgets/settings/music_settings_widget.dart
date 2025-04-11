import 'package:flutter/material.dart';
import 'package:running_app/utils/logger.dart';

class MusicSettingsWidget extends StatelessWidget {
  // --- Settings Values ---
  final String musicServiceConnected; // e.g., 'Spotify', 'Apple Music', 'None'
  final bool duckAudioEnabled; // Lower music volume during voice prompts
  final bool autoResumeEnabled; // Resume music after voice prompt automatically

  // --- Callbacks ---
  final ValueChanged<String> onConnectService; // Trigger connection flow
  final ValueChanged<bool> onDuckAudioChanged;
  final ValueChanged<bool> onAutoResumeChanged;

  const MusicSettingsWidget({
    required this.musicServiceConnected,
    required this.duckAudioEnabled,
    required this.autoResumeEnabled,
    required this.onConnectService,
    required this.onDuckAudioChanged,
    required this.onAutoResumeChanged,
    super.key,
  });

   Widget _buildSectionHeader(BuildContext context, String title) {
     return Padding( padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
        child: Text( title.toUpperCase(), style: TextStyle( color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8, ), ), );
   }

  @override
  Widget build(BuildContext context) {
    return ListView(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
         _buildSectionHeader(context, 'Music Service'),
         // TODO: Implement connection status and connect buttons for Spotify/Apple Music etc.
          ListTile(
             leading: const Icon(Icons.link),
             title: const Text('Connected Service'),
             subtitle: Text(musicServiceConnected == 'None' ? 'No service connected' : 'Connected to $musicServiceConnected'),
             trailing: musicServiceConnected == 'None'
                ? ElevatedButton( child: const Text('Connect'), onPressed: () { Log.w("TODO: Music service connection flow"); /* onConnectService('spotify'); */ } )
                 : TextButton( child: const Text('Disconnect'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () { Log.w("TODO: Music service disconnection"); /* onConnectService('none'); */ } ),
          ),
         const Divider(height: 24),

          _buildSectionHeader(context, 'Playback Options'),
          SwitchListTile(
             secondary: const Icon(Icons.volume_down_outlined),
             title: const Text('Duck Audio'),
             subtitle: const Text('Lower music volume during voice coach announcements.'),
              value: duckAudioEnabled,
              onChanged: onDuckAudioChanged,
          ),
           SwitchListTile(
              secondary: const Icon(Icons.play_arrow_outlined),
              title: const Text('Auto-Resume Music'),
              subtitle: const Text('Automatically resume music after voice announcements.'),
               value: autoResumeEnabled,
               onChanged: onAutoResumeChanged,
           ),

          // TODO: Add other music settings (crossfade, default volume, etc.)?
      ],
    );
  }
}