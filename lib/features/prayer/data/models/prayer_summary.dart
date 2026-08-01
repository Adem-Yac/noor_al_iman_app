class PrayerSummary {
  const PrayerSummary({
    required this.currentPrayer,
    required this.nextPrayer,
    required this.timeUntilNext,
    required this.minutesUntilNext,
    required this.prayerTimes,
  });

  /// Ordre des 5 salats (pas sunrise).
  static const salatOrder = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  final String currentPrayer;
  final String nextPrayer;
  final String timeUntilNext;
  final int minutesUntilNext;
  final Map<String, String> prayerTimes;

  bool get hasTimes => prayerTimes.isNotEmpty && nextPrayer.isNotEmpty;

  static const empty = PrayerSummary(
    currentPrayer: '',
    nextPrayer: '',
    timeUntilNext: '--:--',
    minutesUntilNext: 0,
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
    final minutes = resolved.remaining.inMinutes;
    return PrayerSummary(
      currentPrayer: resolved.current,
      nextPrayer: resolved.next,
      timeUntilNext: _formatDuration(resolved.remaining),
      minutesUntilNext: minutes < 0 ? 0 : minutes,
      prayerTimes: prayerTimes,
    );
  }

  /// Calcule prière actuelle / suivante à partir des horaires.
  /// Après Isha (et avant Fajr) → prochaine = Fajr (lendemain).
  static ({String current, String next, Duration remaining}) resolveFromTimes(
    Map<String, String> times, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();

    DateTime? atToday(String key) {
      final raw = times[key];
      if (raw == null) return null;
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return DateTime(n.year, n.month, n.day, h, m);
    }

    for (var i = 0; i < salatOrder.length; i++) {
      final key = salatOrder[i];
      final dt = atToday(key);
      if (dt != null && dt.isAfter(n)) {
        final current = i == 0 ? 'isha' : salatOrder[i - 1];
        return (current: current, next: key, remaining: dt.difference(n));
      }
    }

    // Plus aucune salat aujourd'hui → Fajr demain.
    final fajr = atToday('fajr');
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
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final n = now ?? DateTime.now();
    var when = DateTime(n.year, n.month, n.day, h, m);
    if (!when.isAfter(n)) when = when.add(const Duration(days: 1));
    return when;
  }

  String get currentTime => prayerTimes[currentPrayer] ?? '--:--';
  String get nextTime => prayerTimes[nextPrayer] ?? '--:--';

  /// Temps restant jusqu'à la prochaine prière (horloge appareil).
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

  static String _formatDuration(Duration d) {
    final total = d.isNegative ? Duration.zero : d;
    final h = total.inHours.toString().padLeft(2, '0');
    final m = (total.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
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
