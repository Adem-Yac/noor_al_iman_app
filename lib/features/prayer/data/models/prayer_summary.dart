class PrayerSummary {
  const PrayerSummary({
    required this.currentPrayer,
    required this.nextPrayer,
    required this.timeUntilNext,
    required this.minutesUntilNext,
    required this.prayerTimes,
  });

  final String currentPrayer;
  final String nextPrayer;
  final String timeUntilNext;
  final int minutesUntilNext;
  final Map<String, String> prayerTimes;

  factory PrayerSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final status = data['current_status'] as Map<String, dynamic>;
    final times = data['prayer_times'] as Map<String, dynamic>;

    return PrayerSummary(
      currentPrayer: status['current_prayer'] as String,
      nextPrayer: status['next_prayer'] as String,
      timeUntilNext: status['time_until_next'] as String,
      minutesUntilNext: status['minutes_until_next'] as int,
      prayerTimes: times.map((key, value) => MapEntry(key, value as String)),
    );
  }

  String get currentTime => prayerTimes[currentPrayer] ?? '--:--';
  String get nextTime => prayerTimes[nextPrayer] ?? '--:--';

  List<MapEntry<String, String>> get displayTimes => [
    for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
      if (prayerTimes.containsKey(key)) MapEntry(key, prayerTimes[key]!),
  ];

  double get progress {
    final start = _minutes(currentTime);
    var end = _minutes(nextTime);
    if (end <= start) end += 24 * 60;
    final interval = end - start;
    if (interval <= 0) return 0;
    return (1 - minutesUntilNext / interval).clamp(0.0, 1.0).toDouble();
  }

  int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
