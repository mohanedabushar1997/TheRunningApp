import 'package:flutter/material.dart';
import 'package:running_app/presentation/screens/workout/music_playlist_screen.dart';
import 'package:running_app/utils/logger.dart';
// TODO: Import MusicProvider/Service

class MusicControlsWidget extends StatelessWidget {
  const MusicControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Get state from MusicProvider
    // final music = context.watch<MusicProvider>();
    final bool isPlaying = true; // Placeholder
    final String currentTrackTitle = "Don't Stop Me Now"; // Placeholder
    final String currentArtist = "Queen"; // Placeholder
    final bool trackSelected = true; // Placeholder

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material( // Wrap in Material for elevation/ink effects
      elevation: 4,
      color: colorScheme.surfaceContainerHigh, // Elevated surface color
      child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
         height: 65, // Fixed height for controls
         child: Row(
            children: [
               // --- Album Art / Playlist ---
                IconButton(
                   icon: const Icon(Icons.queue_music),
                   tooltip: 'Select Music',
                   iconSize: 28,
                   onPressed: () => Navigator.pushNamed(context, MusicPlaylistScreen.routeName),
                ),

               // --- Track Info ---
               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Text(
                          trackSelected ? currentTrackTitle : 'No Music Selected',
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                        ),
                         if (trackSelected)
                            Text(
                              currentArtist,
                              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                            ),
                     ],
                   ),
                 ),
               ),

               // --- Playback Controls ---
                // TODO: Disable buttons if !trackSelected
               IconButton( icon: const Icon(Icons.skip_previous), iconSize: 30, tooltip: 'Previous', onPressed: !trackSelected ? null : () => Log.d("Music: Previous TODO"), ),
               IconButton(
                  icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                  iconSize: 44, tooltip: isPlaying ? 'Pause' : 'Play',
                  color: colorScheme.primary,
                   onPressed: !trackSelected ? null : () => Log.d("Music: Play/Pause TODO"),
               ),
               IconButton( icon: const Icon(Icons.skip_next), iconSize: 30, tooltip: 'Next', onPressed: !trackSelected ? null : () => Log.d("Music: Next TODO"), ),
            ],
         ),
      ),
    );
  }
}