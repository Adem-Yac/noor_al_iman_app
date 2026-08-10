import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/l10n/app_strings.dart';
import '../models/prayer_summary.dart';
import 'prayer_alarm_audio.dart';
import 'prayer_notif_prefs.dart';

/// Planifie les notifications de prière et d’adhkar.
class PrayerNotificationService {
  PrayerNotificationService._();
  static final instance = PrayerNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  final List<Timer> _inAppTimers = [];

  static const _notifColor = Color(0xFF003D33);

  /// Nouveaux IDs : Android ignore le son si le canal existait déjà.
  static const _chVibration = 'prayer_vib_v5';
  static const _chTakbir = 'prayer_takbir_v6';
  static const _chAdhan = 'prayer_adhan_v5';
  static const _chDua = 'adhkar_daily_v3';

  static const _legacyChannels = [
    'prayer_vib_v1',
    'prayer_vib_v2',
    'prayer_vib_v3',
    'prayer_vib_v4',
    'prayer_takbir_v1',
    'prayer_takbir_v2',
    'prayer_takbir_v3',
    'prayer_takbir_v4',
    'prayer_takbir_v5',
    'prayer_adhan_v1',
    'prayer_adhan_v2',
    'prayer_adhan_v3',
    'prayer_adhan_v4',
    'dua_daily_v1',
    'dua_daily_v2',
  ];

  static const _ids = {
    'fajr': 101,
    'sunrise': 102,
    'dhuhr': 103,
    'asr': 104,
    'maghrib': 105,
    'isha': 106,
  };

  static const _duaWakeId = 201;
  static const _duaEveningId = 202;
  static const _duaSleepId = 203;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_ready) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await Future.wait([
      for (final id in _legacyChannels)
        Future(() async {
          await androidPlugin?.deleteNotificationChannel(channelId: id);
        }),
    ]);

    final prayerChannel = S.notifChannelPrayer;
    final adhkarChannel = S.notifChannelAdhkar;

    await Future.wait([
      Future(() async {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            _chVibration,
            prayerChannel,
            description: S.notifPrayerTime,
            importance: Importance.high,
            playSound: false,
            enableVibration: true,
          ),
        );
      }),
      Future(() async {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            _chTakbir,
            '$prayerChannel — ${S.notifTakbir}',
            description: S.notifTakbir,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            sound: const RawResourceAndroidNotificationSound('takbir'),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            bypassDnd: true,
          ),
        );
      }),
      Future(() async {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            _chAdhan,
            '$prayerChannel — ${S.notifAdhan}',
            description: S.notifAdhan,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            sound: const RawResourceAndroidNotificationSound('adhan'),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            bypassDnd: true,
          ),
        );
      }),
      Future(() async {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            _chDua,
            adhkarChannel,
            description: adhkarChannel,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }),
    ]);

    _ready = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final notif = await Permission.notification.request();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final granted = notif.isGranted || notif.isLimited;
    if (!granted) {
      await openAppSettings();
    }
    return granted;
  }

  Future<void> rescheduleFromApi(PrayerSummary prayer) async {
    if (!_ready) await init();
    if (kIsWeb) return;

    await cancelPrayerNotifs();
    final modes = await PrayerNotifPrefs.getAllModes();

    for (final entry in prayer.prayerTimes.entries) {
      final key = entry.key.toLowerCase();
      final mode = modes[key] ?? PrayerNotifMode.off;
      if (mode == PrayerNotifMode.off) continue;

      final id = _ids[key];
      if (id == null) continue;

      final when = _nextTz(entry.value);
      if (when == null) continue;

      await _schedule(
        id: id,
        prayerKey: key,
        timeRaw: entry.value,
        when: when,
        mode: mode,
      );
    }

    _scheduleInAppAudio(prayer, modes);
  }

  Future<void> cancelAll() async {
    await cancelPrayerNotifs();
    await cancelDuaNotifs();
    for (final id in const [900, 901, 902, 903]) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelPrayerNotifs() async {
    _clearInAppTimers();
    for (final id in _ids.values) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelDuaNotifs() async {
    await _plugin.cancel(id: _duaWakeId);
    await _plugin.cancel(id: _duaEveningId);
    await _plugin.cancel(id: _duaSleepId);
  }

  /// Réveil @ Fajr · Soir @ Maghrib · Sommeil @ Isha.
  Future<void> scheduleDailyDuas({
    required PrayerSummary prayer,
    String? wakeTitle,
    String? wakeBody,
    String? eveningTitle,
    String? eveningBody,
    String? sleepTitle,
    String? sleepBody,
  }) async {
    if (!_ready) await init();
    if (kIsWeb) return;

    await cancelDuaNotifs();
    unawaited(requestPermissions());

    final fajr = _nextTz(prayer.prayerTimes['fajr'] ?? '');
    if (fajr != null && wakeBody != null) {
      await _scheduleDua(
        id: _duaWakeId,
        title: wakeTitle ?? S.notifAdhkarWake,
        body: wakeBody,
        when: fajr,
        timeLabel: _formatTimeLabel(prayer.prayerTimes['fajr'] ?? ''),
      );
    }

    final maghrib = _nextTz(prayer.prayerTimes['maghrib'] ?? '');
    if (maghrib != null && eveningBody != null) {
      await _scheduleDua(
        id: _duaEveningId,
        title: eveningTitle ?? S.notifAdhkarEvening,
        body: eveningBody,
        when: maghrib,
        timeLabel: _formatTimeLabel(prayer.prayerTimes['maghrib'] ?? ''),
      );
    }

    final isha = _nextTz(prayer.prayerTimes['isha'] ?? '');
    if (isha != null && sleepBody != null) {
      await _scheduleDua(
        id: _duaSleepId,
        title: sleepTitle ?? S.notifAdhkarSleep,
        body: sleepBody,
        when: isha,
        timeLabel: _formatTimeLabel(prayer.prayerTimes['isha'] ?? ''),
      );
    }
  }

  Future<void> _scheduleDua({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String timeLabel,
  }) async {
    final lines = body.split('\n');
    final duaTitle = lines.isNotEmpty ? lines.first.trim() : title;
    final arabic = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    final bigText = arabic.isEmpty ? duaTitle : '$duaTitle\n\n$arabic';

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: duaTitle,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _chDua,
          S.notifChannelAdhkar,
          channelDescription: S.notifChannelAdhkar,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: _notifColor,
          colorized: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          subText: timeLabel,
          styleInformation: BigTextStyleInformation(
            bigText,
            contentTitle: title,
            summaryText: 'Noor Al-Iman',
          ),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: timeLabel,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'dua:$id',
    );
  }

  Future<void> _schedule({
    required int id,
    required String prayerKey,
    required String timeRaw,
    required tz.TZDateTime when,
    required PrayerNotifMode mode,
  }) async {
    final name = PrayerNotifPrefs.labelFr(prayerKey);
    final timeLabel = _formatTimeLabel(timeRaw);
    final content = _prayerContent(
      name: name,
      timeLabel: timeLabel,
      mode: mode,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: content.title,
      body: content.body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          mode,
          bigText: content.bigText,
          subText: content.subText,
          contentTitle: content.title,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: mode != PrayerNotifMode.vibration,
          sound: switch (mode) {
            PrayerNotifMode.takbir => 'takbir.mp3',
            PrayerNotifMode.adhan => 'adhan.mp3',
            _ => null,
          },
          subtitle: content.subText,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$prayerKey:${mode.name}',
    );
  }

  ({
    String title,
    String body,
    String bigText,
    String subText,
  }) _prayerContent({
    required String name,
    required String timeLabel,
    required PrayerNotifMode mode,
  }) {
    final subText = timeLabel;

    switch (mode) {
      case PrayerNotifMode.vibration:
        return (
          title: name,
          body: '${S.notifPrayerTime} · $timeLabel',
          bigText: '${S.notifPrayerTime}\n$name\n$timeLabel',
          subText: subText,
        );
      case PrayerNotifMode.takbir:
        return (
          title: name,
          body: '${S.notifTakbir} · $timeLabel',
          bigText: '${S.notifTakbir}\n$name\n$timeLabel',
          subText: subText,
        );
      case PrayerNotifMode.adhan:
        return (
          title: name,
          body: '${S.notifAdhan} · $timeLabel',
          bigText: '${S.notifAdhan}\n$name\n$timeLabel',
          subText: subText,
        );
      case PrayerNotifMode.off:
        return (
          title: name,
          body: '',
          bigText: '',
          subText: subText,
        );
    }
  }

  AndroidNotificationDetails _androidDetails(
    PrayerNotifMode mode, {
    required String bigText,
    required String subText,
    required String contentTitle,
  }) {
    final style = BigTextStyleInformation(
      bigText,
      contentTitle: contentTitle,
      summaryText: 'Noor Al-Iman',
    );

    final common = (
      color: _notifColor,
      colorized: true,
      visibility: NotificationVisibility.public,
      subText: subText,
      styleInformation: style,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    final channelLabel = S.notifChannelPrayer;

    return switch (mode) {
      PrayerNotifMode.vibration => AndroidNotificationDetails(
        _chVibration,
        channelLabel,
        channelDescription: S.notifPrayerTime,
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        color: common.color,
        colorized: common.colorized,
        visibility: common.visibility,
        subText: common.subText,
        styleInformation: common.styleInformation,
        largeIcon: common.largeIcon,
      ),
      PrayerNotifMode.takbir => AndroidNotificationDetails(
        _chTakbir,
        '$channelLabel — ${S.notifTakbir}',
        channelDescription: S.notifTakbir,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('takbir'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        color: common.color,
        colorized: common.colorized,
        visibility: common.visibility,
        subText: common.subText,
        styleInformation: common.styleInformation,
        largeIcon: common.largeIcon,
      ),
      PrayerNotifMode.adhan => AndroidNotificationDetails(
        _chAdhan,
        '$channelLabel — ${S.notifAdhan}',
        channelDescription: S.notifAdhan,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        color: common.color,
        colorized: common.colorized,
        visibility: common.visibility,
        subText: common.subText,
        styleInformation: common.styleInformation,
        largeIcon: common.largeIcon,
      ),
      PrayerNotifMode.off => AndroidNotificationDetails(
        _chVibration,
        channelLabel,
        color: common.color,
      ),
    };
  }

  void _scheduleInAppAudio(
    PrayerSummary prayer,
    Map<String, PrayerNotifMode> modes,
  ) {
    _clearInAppTimers();
    final now = DateTime.now();

    for (final entry in prayer.prayerTimes.entries) {
      final key = entry.key.toLowerCase();
      final mode = modes[key] ?? PrayerNotifMode.off;
      if (mode != PrayerNotifMode.takbir && mode != PrayerNotifMode.adhan) {
        continue;
      }

      final when = PrayerSummary.nextOccurrence(entry.value, now: now);
      if (when == null) continue;

      final delay = when.difference(now);
      if (delay <= Duration.zero) continue;
      final timer = Timer(delay, () => PrayerAlarmAudio.instance.play(mode));
      _inAppTimers.add(timer);
    }
  }

  void _clearInAppTimers() {
    for (final t in _inAppTimers) {
      t.cancel();
    }
    _inAppTimers.clear();
  }

  String _formatTimeLabel(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final isPm = hour >= 12;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${h12.toString().padLeft(2, '0')}:$minute ${isPm ? 'PM' : 'AM'}';
  }

  tz.TZDateTime? _nextTz(String hhmm) {
    final when = PrayerSummary.nextOccurrence(hhmm);
    if (when == null) return null;
    final delay = when.difference(DateTime.now());
    if (delay.isNegative) return null;
    return tz.TZDateTime.now(tz.local).add(delay);
  }
}
