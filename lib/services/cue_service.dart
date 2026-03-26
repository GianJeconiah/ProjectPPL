import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class CueService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAudioCue() async {
    try {
      await _player.play(AssetSource('beep.mp3'));
    } catch (_) {
      // Audio not available in simulator
    }
  }

  Future<void> playHapticCue() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 200);
      }
    } catch (_) {}
  }

  Future<void> triggerCue(String cueType) async {
    switch (cueType) {
      case 'audio':
        await playAudioCue();
        break;
      case 'haptic':
        await playHapticCue();
        break;
      case 'visual':
        // Visual cue is handled by the UI
        break;
      case 'all':
        await playAudioCue();
        await playHapticCue();
        break;
    }
  }

  void dispose() {
    _player.dispose();
  }
}