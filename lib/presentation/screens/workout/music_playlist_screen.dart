import 'package:flutter/material.dart';
// TODO: Import Music Service and Provider
import 'package:running_app/presentation/widgets/common/empty_state_widget.dart';
import 'package:running_app/utils/logger.dart';

class MusicPlaylistScreen extends StatelessWidget {
  const MusicPlaylistScreen({super.key});
  static const routeName = '/workout/music-playlist';

  @override
  Widget build(BuildContext context) {
     // TODO: Get playlists/tracks from MusicProvider/Service
     // final musicProvider = context.watch<MusicProvider>();

     // --- Placeholder Data ---
     final bool loading = false; // Simulate loaded state
     final List<String> playlists = ['Running Hits', 'High Energy', 'Chill Beats', 'My Favorites'];
     final List<Map<String, String>> tracks = [
        {'title': 'Run the World', 'artist': 'Bey'},
        {'title': 'Don\'t Stop Me Now', 'artist': 'Queen'},
        {'title': 'Stronger', 'artist': 'Kanye W.'},
        {'title': 'Uptown Funk', 'artist': 'Mark R. ft. Bruno M.'},
        {'title': 'Lose Yourself', 'artist': 'Eminem'},
     ];
     // --- End Placeholder ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Music'),
         // TODO: Add actions to connect to music services (Spotify, Apple Music)? Or Filter?
          actions: [ IconButton(icon: const Icon(Icons.search), onPressed: () { Log.w("Music search TODO"); }, tooltip: 'Search Music'), ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(
           length: 3, // Example: Playlists, Tracks, Source (e.g., Spotify)
           child: Column(
             children: [
               const TabBar(tabs: [
                  Tab(icon: Icon(Icons.playlist_play), text: 'Playlists'),
                  Tab(icon: Icon(Icons.music_note), text: 'Tracks'),
                   Tab(icon: Icon(Icons.link), text: 'Source'), // Example for service linking
               ]),
               Expanded(child: TabBarView(
                  children: [
                     // --- Playlists Tab ---
                     _buildList(context, playlists, Icons.queue_music, (item) {
                         Log.i("Playlist selected: $item");
                          // TODO: Tell music service to play this playlist
                          // context.read<MusicService>().playPlaylist(item);
                          Navigator.pop(context); // Close selector after choosing
                     }),
                      // --- Tracks Tab ---
                     _buildList(context, tracks, Icons.audiotrack, (item) {
                         Log.i("Track selected: ${item['title']}");
                           // TODO: Tell music service to play this track
                           // context.read<MusicService>().playTrack(item['id']); // Assuming track has an ID
                           Navigator.pop(context);
                     }, isTrack: true),
                      // --- Source Tab ---
                      // TODO: Implement UI to connect/disconnect from music sources (Spotify SDK etc.)
                      const Center(child: Text("Connect to Music Services (TODO)")),
                  ],
               )),
             ],
           ),
         ),
    );
  }

   // Helper to build list view for playlists or tracks
   Widget _buildList(BuildContext context, List items, IconData icon, ValueChanged<dynamic> onTap, {bool isTrack = false}) {
      if (items.isEmpty) {
         return EmptyStateWidget(message: isTrack ? 'No tracks found.' : 'No playlists found.', icon: icon);
      }
      return ListView.builder(
         itemCount: items.length,
         itemBuilder: (context, index) {
            final item = items[index];
            String title = isTrack ? (item['title'] ?? 'Unknown Track') : item;
            String? subtitle = isTrack ? (item['artist'] ?? 'Unknown Artist') : null;

             return ListTile(
                leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
                title: Text(title),
                 subtitle: subtitle != null ? Text(subtitle) : null,
                 onTap: () => onTap(item),
             );
         },
      );
   }
}