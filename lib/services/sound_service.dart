import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playDone() async {
    try {
      await _player.play(AssetSource('sounds/done.mp3'));
    } catch (e) {
      // Sound file missing or playback failed — silently skip.
      debugPrint('SoundService: playDone failed: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
