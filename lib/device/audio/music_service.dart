import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

/// Music service for handling music playback during workouts
///
/// This service provides a streamlined interface for controlling music
/// playback during workouts with features like playlist management, volume
/// control, and integration with voice coaching.
class MusicService {
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playlist management
  List<MediaItem> _playlist = [];
  int _currentIndex = 0;

  // Settings
  bool _enabled = true;
  bool _shuffleEnabled = false;
  double _volume = 1.0;

  // Status
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Streams
  final _playerStateController = StreamController<PlaybackState>.broadcast();
  final _currentSongController = StreamController<MediaItem?>.broadcast();

  // Getters
  Stream<PlaybackState> get playerStateStream => _playerStateController.stream;
  Stream<MediaItem?> get currentSongStream => _currentSongController.stream;
  List<MediaItem> get playlist => List.unmodifiable(_playlist);
  MediaItem? get currentSong =>
      _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isEnabled => _enabled;
  bool get isShuffleEnabled => _shuffleEnabled;
  double get volume => _volume;

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the audio player
      await _audioPlayer.setLoopMode(LoopMode.all);

      // Load saved settings
      await _loadSettings();

      // Set up audio player callbacks
      _audioPlayer.playerStateStream.listen(_handlePlayerStateChange);
      _audioPlayer.currentIndexStream.listen(_handleCurrentIndexChange);

      _isInitialized = true;
      AppLogger.info('Music service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize music service', e, stackTrace);
    }
  }

  // Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _enabled = prefs.getBool('music_enabled') ?? true;
      _shuffleEnabled = prefs.getBool('music_shuffle_enabled') ?? false;
      _volume = prefs.getDouble('music_volume') ?? 1.0;

      // Load saved playlist
      final playlistJson = prefs.getStringList('music_playlist');
      if (playlistJson != null && playlistJson.isNotEmpty) {
        _playlist = playlistJson
            .map((item) => MediaItem.fromJson(Map<String, dynamic>.from({
                  'id': item.split('|')[0],
                  'title': item.split('|')[1],
                  'artist': item.split('|')[2],
                  'url': item.split('|')[3],
                })))
            .toList();

        // Apply shuffle if enabled
        if (_shuffleEnabled) {
          _playlist.shuffle();
        }
      }

      // Apply volume
      await _audioPlayer.setVolume(_volume);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load music settings', e, stackTrace);
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('music_enabled', _enabled);
      await prefs.setBool('music_shuffle_enabled', _shuffleEnabled);
      await prefs.setDouble('music_volume', _volume);

      // Save playlist (in simple format to avoid complex serialization)
      final playlistStrings = _playlist
          .map((item) =>
              '${item.id}|${item.title}|${item.artist ?? "Unknown"}|${item.extras?['url'] ?? ""}')
          .toList();

      await prefs.setStringList('music_playlist', playlistStrings);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save music settings', e, stackTrace);
    }
  }

  // Handle player state changes
  void _handlePlayerStateChange(PlayerState state) {
    _isPlaying = state.playing;

    final playbackState = PlaybackState(
      playing: state.playing,
      processingState: _convertProcessingState(state.processingState),
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );

    _playerStateController.add(playbackState);
  }

  // Handle current index changes
  void _handleCurrentIndexChange(int? index) {
    if (index != null && index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      _currentSongController.add(_playlist[index]);
    } else {
      _currentSongController.add(null);
    }
  }

  // Convert processing state
  AudioProcessingState _convertProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  // Set the playlist for the music service
  Future<void> setPlaylist(List<MediaItem> items) async {
    if (items.isEmpty) return;

    _playlist = List.from(items);

    if (_shuffleEnabled) {
      _playlist.shuffle();
    }

    // Create ConcatenatingAudioSource from playlist
    final playlist = ConcatenatingAudioSource(
      children: _playlist
          .map((item) => AudioSource.uri(Uri.parse(item.extras?['url'] ?? '')))
          .toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: 0);
    _currentIndex = 0;
    _currentSongController.add(_playlist.isNotEmpty ? _playlist[0] : null);

    await _saveSettings();
  }

  // Add songs to playlist
  Future<void> addToPlaylist(List<MediaItem> items) async {
    if (items.isEmpty) return;

    final wasEmpty = _playlist.isEmpty;
    _playlist.addAll(items);

    if (_shuffleEnabled) {
      _playlist.shuffle();
    }

    // If playlist was previously empty, set as new playlist
    if (wasEmpty) {
      await setPlaylist(_playlist);
    } else {
      // Otherwise, recreate the playlist with the new items added
      final audioSources = items
          .map((item) => AudioSource.uri(Uri.parse(item.extras?['url'] ?? '')))
          .toList();

      // Get current audio source as ConcatenatingAudioSource
      if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
        // Create a new playlist with all sources to replace the current one
        final newPlaylist = ConcatenatingAudioSource(
          children: [
            ...(_audioPlayer.audioSource as ConcatenatingAudioSource).children,
            ...audioSources,
          ],
        );

        // Preserve current position and index
        final position = _audioPlayer.position;
        final index = _audioPlayer.currentIndex ?? 0;

        // Set the new source
        await _audioPlayer.setAudioSource(newPlaylist, initialIndex: index);
        await _audioPlayer.seek(position, index: index);
      }

      await _saveSettings();
    }
  }

  // Remove a song from the playlist
  Future<void> removeFromPlaylist(String id) async {
    final index = _playlist.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _playlist.removeAt(index);

      // Recreate the playlist without the removed item
      if (_playlist.isNotEmpty) {
        final newPlaylist = ConcatenatingAudioSource(
          children: _playlist
              .map((item) =>
                  AudioSource.uri(Uri.parse(item.extras?['url'] ?? '')))
              .toList(),
        );

        // Determine the new index after removal
        final newIndex = index <= _currentIndex
            ? (_currentIndex > 0 ? _currentIndex - 1 : 0)
            : _currentIndex;

        // Preserve position if possible
        final position = _audioPlayer.position;

        // Set the new source
        await _audioPlayer.setAudioSource(newPlaylist, initialIndex: newIndex);

        // Seek to the previous position if the current song wasn't removed
        if (index != _currentIndex) {
          await _audioPlayer.seek(position, index: newIndex);
        }

        // Update current index
        _currentIndex = newIndex;
      } else {
        // Clear player if no more songs
        await _audioPlayer.stop();
        await _audioPlayer
            .setAudioSource(ConcatenatingAudioSource(children: []));
        _currentSongController.add(null);
      }

      await _saveSettings();
    }
  }

  // Clear the playlist
  Future<void> clearPlaylist() async {
    _playlist.clear();
    await _audioPlayer.stop();
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
    _currentSongController.add(null);
    await _saveSettings();
  }

  // Play music
  Future<void> play() async {
    if (!_enabled || _playlist.isEmpty) return;

    try {
      await _audioPlayer.play();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to play music', e, stackTrace);
    }
  }

  // Pause music
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to pause music', e, stackTrace);
    }
  }

  // Stop music
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop music', e, stackTrace);
    }
  }

  // Skip to next song
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    try {
      await _audioPlayer.seekToNext();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to skip to next song', e, stackTrace);
    }
  }

  // Skip to previous song
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    try {
      await _audioPlayer.seekToPrevious();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to skip to previous song', e, stackTrace);
    }
  }

  // Skip to specific song by index
  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    try {
      await _audioPlayer.seek(Duration.zero, index: index);
      _currentIndex = index;
      _currentSongController.add(_playlist[index]);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to skip to index $index', e, stackTrace);
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    if (volume < 0) volume = 0;
    if (volume > 1) volume = 1;

    _volume = volume;
    await _audioPlayer.setVolume(volume);
    await _saveSettings();
  }

  // Temporarily lower volume (for voice coaching)
  Future<void> lowerVolume() async {
    await _audioPlayer.setVolume(_volume * 0.3);
  }

  // Restore volume to normal level
  Future<void> restoreVolume() async {
    await _audioPlayer.setVolume(_volume);
  }

  // Enable/disable music
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;

    if (!enabled && _isPlaying) {
      await pause();
    }

    await _saveSettings();
  }

  // Enable/disable shuffle
  Future<void> setShuffle(bool shuffle) async {
    _shuffleEnabled = shuffle;
    await _saveSettings();

    if (shuffle && _playlist.isNotEmpty) {
      // Save current song
      final currentSong =
          _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

      // Shuffle playlist (keeping current song at current position)
      if (currentSong != null) {
        _playlist.removeAt(_currentIndex);
        _playlist.shuffle();
        _playlist.insert(_currentIndex, currentSong);
      } else {
        _playlist.shuffle();
      }

      // Recreate playlist in player
      final playlist = ConcatenatingAudioSource(
        children: _playlist
            .map(
                (item) => AudioSource.uri(Uri.parse(item.extras?['url'] ?? '')))
            .toList(),
      );

      final position = _audioPlayer.position;
      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);
      await _audioPlayer.seek(position, index: _currentIndex);
    }
  }

  // Add a local music file to playlist
  Future<void> addLocalFile(String filePath) async {
    try {
      final fileName = path.basename(filePath);
      final id = 'local-${DateTime.now().millisecondsSinceEpoch}';

      final mediaItem = MediaItem(
        id: id,
        title: fileName,
        artist: 'Local File',
        extras: {'url': filePath},
      );

      await addToPlaylist([mediaItem]);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add local file to playlist', e, stackTrace);
    }
  }

  // Add a list of local music files to playlist
  Future<void> addLocalFiles(List<String> filePaths) async {
    try {
      final mediaItems = filePaths.map((filePath) {
        final fileName = path.basename(filePath);
        final id =
            'local-${DateTime.now().millisecondsSinceEpoch}-${_playlist.length}';

        return MediaItem(
          id: id,
          title: fileName,
          artist: 'Local File',
          extras: {'url': filePath},
        );
      }).toList();

      await addToPlaylist(mediaItems);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add local files to playlist', e, stackTrace);
    }
  }

  // Dispose of resources
  void dispose() {
    _audioPlayer.dispose();
    _playerStateController.close();
    _currentSongController.close();
  }
}

/// Simplified MediaItem class for use with MusicService
class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final Map<String, dynamic>? extras;

  MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.extras,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      extras: json['extras'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'extras': extras,
    };
  }
}

/// Simplified PlaybackState class for use with MusicService
class PlaybackState {
  final bool playing;
  final AudioProcessingState processingState;
  final Duration position;
  final Duration bufferedPosition;
  final double speed;

  PlaybackState({
    required this.playing,
    required this.processingState,
    required this.position,
    required this.bufferedPosition,
    required this.speed,
  });
}

/// Simplified AudioProcessingState enum for use with MusicService
enum AudioProcessingState {
  idle,
  loading,
  buffering,
  ready,
  completed,
}
