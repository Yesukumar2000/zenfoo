import 'package:flutter/services.dart' show HapticFeedback;
import 'package:just_audio/just_audio.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  late AudioPlayer _audioPlayer;

  factory SoundService() {
    return _instance;
  }

  SoundService._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> playOrderSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/order.wav');
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      // Add haptic feedback when stopping sound
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
