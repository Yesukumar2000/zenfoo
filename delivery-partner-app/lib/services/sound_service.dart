import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Service to manage sound playback for app events
class SoundService {
  static final SoundService _instance = SoundService._internal();
  late AudioPlayer _audioPlayer;

  factory SoundService() {
    return _instance;
  }

  SoundService._internal() {
    _audioPlayer = AudioPlayer();
    debugPrint('✅ SoundService initialized');
  }

  /// Play order received sound with retry logic
  Future<void> playOrderSound() async {
    try {
      debugPrint('🔊 Playing order notification sound...');

      // Stop any currently playing sound first
      try {
        await _audioPlayer.stop();
      } catch (e) {
        debugPrint('⚠️ Error stopping previous sound: $e');
      }

      // Try to load and play the audio
      try {
        // Use just_audio asset loading with package prefix
        await _audioPlayer.setAudioSource(
          AudioSource.asset('sounds/order.wav'),
          initialPosition: Duration.zero,
        );

        debugPrint('✅ Audio source set successfully');

        // Play sound
        await _audioPlayer.play();
        debugPrint('✅ Order sound played successfully');
      } catch (loadError) {
        debugPrint('❌ Error loading audio source: $loadError');
        debugPrint('⚠️ Attempting alternative asset path...');

        // Try alternative approach: release and recreate player
        try {
          await _audioPlayer.dispose();
          _audioPlayer = AudioPlayer();

          await _audioPlayer.setAudioSource(
            AudioSource.asset('assets/sounds/order.wav'),
            initialPosition: Duration.zero,
          );

          await _audioPlayer.play();
          debugPrint('✅ Order sound played successfully (retry)');
        } catch (retryError) {
          debugPrint('❌ Retry failed: $retryError');
          debugPrint('💡 Ensure assets/sounds/ is declared in pubspec.yaml');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in playOrderSound: $e');
    }
  }

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    try {
      debugPrint('🔇 Stopping sound...');
      await _audioPlayer.stop();
      debugPrint('✅ Sound stopped successfully');
    } catch (e) {
      debugPrint('❌ Error stopping sound: $e');
    }
  }

  /// Check if sound is currently playing
  bool isPlaying() {
    return _audioPlayer.playing;
  }

  /// Dispose of audio resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      debugPrint('✅ SoundService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing SoundService: $e');
    }
  }
}
