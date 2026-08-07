class PrayerSummary {
  const PrayerSummary({
    required this.currentPrayer,
    required this.nextPrayer,
    required this.prayerTimes,
  });

  /// Ordre des 5 salats (pas sunrise).
  static const salatOrder = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  final String currentPrayer;
  final String nextPrayer;
  final Map<String, String> prayerTimes;

  bool get hasTimes => prayerTimes.isNotEmpty && nextPrayer.isNotEmpty;

  static const empty = PrayerSummary(
    currentPrayer: '',
    nextPrayer: '',
    prayerTimes: {},
  );

  factory PrayerSummary.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final timesRaw =
        (data['prayer_times'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PrayerSummary.fromTimes({
      for (final e in timesRaw.entries)
        if (e.value != null) e.key.toLowerCase(): e.value.toString(),
    });
  }

  factory PrayerSummary.fromTimes(Map<String, String> prayerTimes) {
    final resolved = resolveFromTimes(prayerTimes);
    return PrayerSummary(
      currentPrayer: resolved.current,
      nextPrayer: resolved.next,
      prayerTimes: prayerTimes,
    );
  }

  /// Après Isha (et avant Fajr) → prochaine = Fajr (lendemain).
  static ({String current, String next, Duration remaining}) resolveFromTimes(
    Map<String, String> times, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();

    for (var i = 0; i < salatOrder.length; i++) {
      final key = salatOrder[i];
      final dt = _todayAt(times[key], n);
      if (dt != null && dt.isAfter(n)) {
        final current = i == 0 ? 'isha' : salatOrder[i - 1];
        return (current: current, next: key, remaining: dt.difference(n));
      }
    }

    final fajr = _todayAt(times['fajr'], n);
    if (fajr != null) {
      final tomorrowFajr = fajr.add(const Duration(days: 1));
      return (
        current: 'isha',
        next: 'fajr',
        remaining: tomorrowFajr.difference(n),
      );
    }

    return (current: '', next: '', remaining: Duration.zero);
  }

  /// Prochaine occurrence locale d'un horaire HH:mm (aujourd'hui ou demain).
  static DateTime? nextOccurrence(String? hhmm, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final when = _todayAt(hhmm, n);
    if (when == null) return null;
    if (when.isAfter(n)) return when;
    return when.add(const Duration(days: 1));
  }

  static DateTime? _todayAt(String? hhmm, DateTime day) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  String get currentTime => prayerTimes[currentPrayer] ?? '--:--';
  String get nextTime => prayerTimes[nextPrayer] ?? '--:--';

  Duration get remainingUntilNext {
    if (!hasTimes) return Duration.zero;
    return resolveFromTimes(prayerTimes).remaining;
  }

  List<MapEntry<String, String>> get displayTimes => [
    for (final key in salatOrder)
      if (prayerTimes.containsKey(key)) MapEntry(key, prayerTimes[key]!),
  ];

  double get progress {
    if (!hasTimes) return 0;
    final start = _minutes(currentTime);
    var end = _minutes(nextTime);
    if (start == null || end == null) return 0;
    if (end <= start) end += 24 * 60;
    final interval = end - start;
    if (interval <= 0) return 0;
    final left = remainingUntilNext.inMinutes;
    return (1 - left / interval).clamp(0.0, 1.0).toDouble();
  }

  int? _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
