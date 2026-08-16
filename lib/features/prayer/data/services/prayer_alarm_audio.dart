import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'prayer_notif_prefs.dart';

/// Lecture takbir / adhan via audioplayers (app au premier plan).
class PrayerAlarmAudio {
  PrayerAlarmAudio._();
  static final instance = PrayerAlarmAudio._();

  final _player = AudioPlayer();
  Timer? _maxTimer;

  static const _takbirMax = Duration(seconds: 20);

  Future<void> play(PrayerNotifMode mode) async {
    if (mode != PrayerNotifMode.takbir && mode != PrayerNotifMode.adhan) return;
    await stop();
    final asset = switch (mode) {
      PrayerNotifMode.takbir => 'audio/takbir.mp3',
      PrayerNotifMode.adhan => 'audio/adhan.mp3',
      _ => null,
    };
    if (asset == null) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource(asset));
      if (mode == PrayerNotifMode.takbir) {
        _maxTimer = Timer(_takbirMax, () {
          unawaited(stop());
        });
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    _maxTimer?.cancel();
    _maxTimer = null;
    try {
      await _player.stop();
    } catch (_) {}
  }
}
