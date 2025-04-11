import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Enhanced Music Service with playlist support and media control
/// 
/// This service provides music playback functionality during workouts
/// with support for playlists, track navigation, and volume control.
/// It uses just_audio for playback and audio_service for background audio.
class EnhancedMusicService {
  // Singleton pattern
  static final EnhancedMusicService _instance = EnhancedMusicService._internal();
  factory EnhancedMusicService() => _instance;
  EnhancedMusicService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  double _volume = 0.8;
  
  // Playlist support
  ConcatenatingAudioSource? _playlist;
  List<MediaItem> _mediaItems = [];
  int _currentIndex = 0;
  
  // Playback state
  bool _shuffleMode = false;
  LoopMode _loopMode = LoopMode.off;

  /// Initialize the music service
  Future<void> initialize() async {
    if (_initialized) return;

    await _audioPlayer.setVolume(_volume);
    
    // Set up position and state listeners
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
      }
    });
    
    // Handle sequence end
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // If we're at the end of the playlist and not looping
        if (_currentIndex == _mediaItems.length - 1 && _loopMode == LoopMode.off) {
          // Stop playback
          _audioPlayer.stop();
        }
      }
    });
    
    _initialized = true;
  }

  /// Play a single track from URI
  Future<void> playFromUri(Uri uri, {String? title, String? artist, String? albumArt}) async {
    if (!_initialized) await initialize();

    try {
      final mediaItem = MediaItem(
        id: uri.toString(),
        title: title ?? 'Unknown Track',
        artist: artist,
        artUri: albumArt != null ? Uri.parse(albumArt) : null,
      );
      
      _mediaItems = [mediaItem];
      _currentIndex = 0;
      
      await _audioPlayer.setAudioSource(AudioSource.uri(uri));
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Play from a local asset
  Future<void> playFromAsset(String assetPath, {String? title, String? artist}) async {
    if (!_initialized) await initialize();

    try {
      final mediaItem = MediaItem(
        id: assetPath,
        title: title ?? assetPath.split('/').last,
        artist: artist,
      );
      
      _mediaItems = [mediaItem];
      _currentIndex = 0;
      
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
  
  /// Create and play a playlist from URIs
  Future<void> playPlaylist(List<Map<String, dynamic>> tracks) async {
    if (!_initialized) await initialize();
    
    try {
      final audioSources = <AudioSource>[];
      _mediaItems = [];
      
      for (final track in tracks) {
        final uri = Uri.parse(track['uri']);
        final mediaItem = MediaItem(
          id: uri.toString(),
          title: track['title'] ?? 'Unknown Track',
          artist: track['artist'],
          artUri: track['albumArt'] != null ? Uri.parse(track['albumArt']) : null,
        );
        
        _mediaItems.add(mediaItem);
        audioSources.add(AudioSource.uri(uri));
      }
      
      _playlist = ConcatenatingAudioSource(children: audioSources);
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: 0);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing playlist: $e');
    }
  }
  
  /// Create and play a playlist from local files
  Future<void> playLocalPlaylist(List<String> filePaths, {List<String>? titles, List<String>? artists}) async {
    if (!_initialized) await initialize();
    
    try {
      final audioSources = <AudioSource>[];
      _mediaItems = [];
      
      for (int i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        final file = File(path);
        
        if (await file.exists()) {
          final uri = Uri.file(path);
          final mediaItem = MediaItem(
            id: uri.toString(),
            title: titles != null && i < titles.length ? titles[i] : path.split('/').last,
            artist: artists != null && i < artists.length ? artists[i] : null,
          );
          
          _mediaItems.add(mediaItem);
          audioSources.add(AudioSource.uri(uri));
        }
      }
      
      if (audioSources.isNotEmpty) {
        _playlist = ConcatenatingAudioSource(children: audioSources);
        await _audioPlayer.setAudioSource(_playlist!, initialIndex: 0);
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error playing local playlist: $e');
    }
  }
  
  /// Add a track to the current playlist
  Future<void> addToPlaylist(String uri, {String? title, String? artist, String? albumArt}) async {
    if (_playlist == null) {
      // Create a new playlist if none exists
      await playFromUri(Uri.parse(uri), title: title, artist: artist, albumArt: albumArt);
      return;
    }
    
    try {
      final mediaItem = MediaItem(
        id: uri,
        title: title ?? 'Unknown Track',
        artist: artist,
        artUri: albumArt != null ? Uri.parse(albumArt) : null,
      );
      
      _mediaItems.add(mediaItem);
      await _playlist!.add(AudioSource.uri(Uri.parse(uri)));
    } catch (e) {
      print('Error adding to playlist: $e');
    }
  }
  
  /// Remove a track from the playlist
  Future<void> removeFromPlaylist(int index) async {
    if (_playlist == null || index < 0 || index >= _mediaItems.length) {
      return;
    }
    
    try {
      await _playlist!.removeAt(index);
      _mediaItems.removeAt(index);
    } catch (e) {
      print('Error removing from playlist: $e');
    }
  }
  
  /// Skip to the next track
  Future<void> skipToNext() async {
    if (_playlist == null) return;
    
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }
  
  /// Skip to the previous track
  Future<void> skipToPrevious() async {
    if (_playlist == null) return;
    
    try {
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }
  
  /// Skip to a specific track in the playlist
  Future<void> skipToIndex(int index) async {
    if (_playlist == null || index < 0 || index >= _mediaItems.length) {
      return;
    }
    
    try {
      await _audioPlayer.seek(Duration.zero, index: index);
    } catch (e) {
      print('Error skipping to index: $e');
    }
  }
  
  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _shuffleMode = !_shuffleMode;
    await _audioPlayer.setShuffleModeEnabled(_shuffleMode);
  }
  
  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _audioPlayer.setLoopMode(mode);
  }
  
  /// Cycle through loop modes (off -> all -> one -> off)
  Future<void> cycleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        await setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Set volume level
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
  }

  /// Lower volume temporarily for announcements
  Future<double> lowerVolumeForAnnouncement() async {
    final currentVolume = _audioPlayer.volume;
    await _audioPlayer.setVolume(0.2);
    return currentVolume;
  }

  /// Restore volume to previous level
  Future<void> restoreVolume(double originalVolume) async {
    await _audioPlayer.setVolume(originalVolume);
  }
  
  /// Seek to a specific position in the current track
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  /// Fast forward by a specified duration
  Future<void> fastForward(Duration duration) async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition + duration;
    await _audioPlayer.seek(newPosition);
  }
  
  /// Rewind by a specified duration
  Future<void> rewind(Duration duration) async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition - duration;
    await _audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;
  
  /// Get the current track index
  int get currentIndex => _currentIndex;
  
  /// Get the current track information
  MediaItem? get currentMediaItem => 
      _mediaItems.isNotEmpty && _currentIndex < _mediaItems.length 
          ? _mediaItems[_currentIndex] 
          : null;
  
  /// Get the current shuffle mode
  bool get shuffleMode => _shuffleMode;
  
  /// Get the current loop mode
  LoopMode get loopMode => _loopMode;
  
  /// Get the current volume
  double get volume => _volume;
  
  /// Get the playlist length
  int get playlistLength => _mediaItems.length;
  
  /// Get all media items in the playlist
  List<MediaItem> get mediaItems => List.unmodifiable(_mediaItems);

  /// Stream that indicates if audio is playing
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Current playback position
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  
  /// Current track duration
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  /// Current track index
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  
  /// Current processing state
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;
  
  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
