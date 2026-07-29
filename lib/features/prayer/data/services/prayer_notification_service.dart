import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_summary.dart';
import 'prayer_notif_prefs.dart';

/// Planifie les notifications de prière à partir des horaires API.
class PrayerNotificationService {
  PrayerNotificationService._();
  static final instance = PrayerNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Nouveaux IDs de canal : Android ignore le son si le canal existait déjà.
  static const _chVibration = 'prayer_vib_v2';
  static const _chTakbir = 'prayer_takbir_v2';
  static const _chAdhan = 'prayer_adhan_v2';

  static const _ids = {
    'fajr': 101,
    'sunrise': 102,
    'dhuhr': 103,
    'asr': 104,
    'maghrib': 105,
    'isha': 106,
  };

  static const _labels = {
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  Future<void> init() async {
    if (kIsWeb) return;
    if (_ready) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

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

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chVibration,
        'Prière — Vibration',
        description: 'Vibration uniquement à l’heure de la prière',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chTakbir,
        'Prière — Takbir',
        description: 'Son takbir à l’heure de la prière',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('takbir'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chAdhan,
        'Prière — Adhan',
        description: 'Son adhan à l’heure de la prière',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

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

    return notif.isGranted || notif.isLimited;
  }

  /// Replanifie toutes les notifs à partir des horaires UmmahAPI du jour.
  Future<void> rescheduleFromApi(PrayerSummary prayer) async {
    if (!_ready) await init();
    if (kIsWeb) return;

    await cancelAll();
    final modes = await PrayerNotifPrefs.getAllModes();
    final now = tz.TZDateTime.now(tz.local);

    for (final entry in prayer.prayerTimes.entries) {
      final key = entry.key.toLowerCase();
      final mode = modes[key] ?? PrayerNotifMode.off;
      if (mode == PrayerNotifMode.off) continue;

      final id = _ids[key];
      if (id == null) continue;

      final when = _todayAt(entry.value);
      if (when == null || !when.isAfter(now)) continue;

      await _schedule(
        id: id,
        prayerKey: key,
        when: when,
        mode: mode,
      );
    }
  }

  Future<void> cancelAll() async {
    for (final id in _ids.values) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _schedule({
    required int id,
    required String prayerKey,
    required tz.TZDateTime when,
    required PrayerNotifMode mode,
  }) async {
    final name = _labels[prayerKey] ?? prayerKey;
    final body = switch (mode) {
      PrayerNotifMode.vibration => 'Heure de $name — vibration',
      PrayerNotifMode.takbir => 'Takbir — il est l’heure de $name',
      PrayerNotifMode.adhan => 'Adhan — il est l’heure de $name',
      PrayerNotifMode.off => '',
    };

    await _plugin.zonedSchedule(
      id: id,
      title: 'Noor Al-Iman · $name',
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: _androidDetails(mode),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: mode != PrayerNotifMode.vibration,
          sound: switch (mode) {
            PrayerNotifMode.takbir => 'takbir.mp3',
            PrayerNotifMode.adhan => 'adhan.mp3',
            _ => null,
          },
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$prayerKey:${mode.name}',
    );
  }

  AndroidNotificationDetails _androidDetails(PrayerNotifMode mode) {
    return switch (mode) {
      PrayerNotifMode.vibration => const AndroidNotificationDetails(
        _chVibration,
        'Prière — Vibration',
        channelDescription: 'Vibration uniquement',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      PrayerNotifMode.takbir => const AndroidNotificationDetails(
        _chTakbir,
        'Prière — Takbir',
        channelDescription: 'Son takbir',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('takbir'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      PrayerNotifMode.adhan => const AndroidNotificationDetails(
        _chAdhan,
        'Prière — Adhan',
        channelDescription: 'Son adhan',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      PrayerNotifMode.off => const AndroidNotificationDetails(
        _chVibration,
        'Prière — Vibration',
      ),
    };
  }

  tz.TZDateTime? _todayAt(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
  }
}
