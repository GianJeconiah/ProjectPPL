import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

enum CueDirection { up, down, left, right }

class CueService {
  final AudioPlayer _player = AudioPlayer();

  // Map each direction to a distinct audio asset.
  // Place these files in assets/audio/ and register them in pubspec.yaml:
  //   flutter:
  //     assets:
  //       - assets/audio/cue_up.mp3
  //       - assets/audio/cue_down.mp3
  //       - assets/audio/cue_left.mp3
  //       - assets/audio/cue_right.mp3
  //       - assets/audio/beep.mp3   ← existing general cue
  static const _directionAssets = {
    CueDirection.up: 'audio/cue_up.mp3',
    CueDirection.down: 'audio/cue_down.mp3',
    CueDirection.left: 'audio/cue_left.mp3',
    CueDirection.right: 'audio/cue_right.mp3',
  };

  Future<void> playAudioCue({CueDirection? direction}) async {
    try {
      final asset = direction != null
          ? _directionAssets[direction]!
          : 'audio/beep.mp3';
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Audio not available in simulator
    }
  }

  Future<void> playHapticCue({CueDirection? direction}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      // Give directional cues distinct vibration patterns so athletes can
      // feel the difference even without looking at the screen:
      //   up    → one short pulse
      //   down  → two short pulses
      //   left  → one long pulse
      //   right → two long pulses
      //   none  → default single pulse
      switch (direction) {
        case CueDirection.up:
          Vibration.vibrate(duration: 150);
          break;
        case CueDirection.down:
          Vibration.vibrate(pattern: [0, 150, 100, 150]);
          break;
        case CueDirection.left:
          Vibration.vibrate(duration: 400);
          break;
        case CueDirection.right:
          Vibration.vibrate(pattern: [0, 400, 100, 400]);
          break;
        default:
          Vibration.vibrate(duration: 200);
      }
    } catch (_) {}
  }

  /// Trigger a cue. [direction] is non-null when directional cues are active.
  Future<void> triggerCue(String cueType, {CueDirection? direction}) async {
    switch (cueType) {
      case 'audio':
        await playAudioCue(direction: direction);
        break;
      case 'haptic':
        await playHapticCue(direction: direction);
        break;
      case 'visual':
        // Visual arrow is rendered by the UI; no audio/haptic needed here.
        break;
      case 'all':
        await Future.wait([
          playAudioCue(direction: direction),
          playHapticCue(direction: direction),
        ]);
        break;
    }
  }

  void dispose() {
    _player.dispose();
  }
}