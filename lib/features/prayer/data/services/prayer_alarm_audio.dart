import 'package:audioplayers/audioplayers.dart';

import 'prayer_notif_prefs.dart';

/// Lecture takbir / adhan via audioplayers (test + app au premier plan).
class PrayerAlarmAudio {
  PrayerAlarmAudio._();
  static final instance = PrayerAlarmAudio._();

  final _player = AudioPlayer();
  bool _playing = false;

  Future<void> play(PrayerNotifMode mode) async {
    if (mode != PrayerNotifMode.takbir && mode != PrayerNotifMode.adhan) return;

    final asset = switch (mode) {
      PrayerNotifMode.takbir => 'audio/takbir.mp3',
      PrayerNotifMode.adhan => 'audio/adhan.mp3',
      _ => null,
    };
    if (asset == null) return;

    try {
      await _player.stop();
      _playing = true;
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource(asset));
    } catch (_) {
      _playing = false;
    }
  }

  Future<void> stop() async {
    if (!_playing) return;
    await _player.stop();
    _playing = false;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
