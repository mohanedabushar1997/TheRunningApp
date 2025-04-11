import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

/// Basic music service for audio playback during workouts
///
/// Provides fundamental functionality for playing, pausing, and controlling audio
/// with volume adjustment capabilities.
class MusicService {
  // Singleton pattern
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  double _volume = 0.8;

  /// Initialize the music service
  Future<void> initialize() async {
    if (_initialized) return;

    await _audioPlayer.setVolume(_volume);
    _initialized = true;
  }

  /// Play audio from a URI
  Future<void> playFromUri(Uri uri) async {
    if (!_initialized) await initialize();

    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(uri));
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Play audio from an asset
  Future<void> playFromAsset(String assetPath) async {
    if (!_initialized) await initialize();

    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Pause audio playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume audio playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// Stop audio playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Set the volume level (0.0 to 1.0)
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

  /// Restore volume to original level
  Future<void> restoreVolume(double originalVolume) async {
    await _audioPlayer.setVolume(originalVolume);
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;

  /// Stream that indicates if audio is playing
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Current playback position
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
