class UserLocation {
  const UserLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.fromGps = false,
  });

  final String label;
  final double latitude;
  final double longitude;
  final bool fromGps;

  static const fallback = UserLocation(
    label: 'Paris, FR',
    latitude: 48.8566,
    longitude: 2.3522,
  );
}

class HomeData {
  const HomeData({
    required this.location,
    required this.calendar,
    required this.prayer,
    required this.verse,
  });

  final UserLocation location;
  final IslamicCalendar calendar;
  final PrayerSummary prayer;
  final DailyVerse verse;
}

class IslamicCalendar {
  const IslamicCalendar({
    required this.gregorianLabel,
    required this.hijriLabel,
  });

  final String gregorianLabel;
  final String hijriLabel;

  factory IslamicCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final gregorian = data['gregorian'] as Map<String, dynamic>;
    final hijri = data['hijri'] as Map<String, dynamic>;

    return IslamicCalendar(
      gregorianLabel: _formatGregorian(gregorian),
      hijriLabel: '${hijri['day']} ${hijri['month_name']} ${hijri['year']}',
    );
  }

  static String _formatGregorian(Map<String, dynamic> g) {
    const weekdays = {
      'Monday': 'Lundi',
      'Tuesday': 'Mardi',
      'Wednesday': 'Mercredi',
      'Thursday': 'Jeudi',
      'Friday': 'Vendredi',
      'Saturday': 'Samedi',
      'Sunday': 'Dimanche',
    };
    const months = {
      'January': 'Janvier',
      'February': 'Février',
      'March': 'Mars',
      'April': 'Avril',
      'May': 'Mai',
      'June': 'Juin',
      'July': 'Juillet',
      'August': 'Août',
      'September': 'Septembre',
      'October': 'Octobre',
      'November': 'Novembre',
      'December': 'Décembre',
    };

    final weekday = weekdays[g['day_of_week']] ?? g['day_of_week'];
    final month = months[g['month_name']] ?? g['month_name'];
    return '$weekday ${g['day']} $month';
  }
}

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

class DailyVerse {
  const DailyVerse({
    required this.surahNumber,
    required this.ayah,
    required this.surahName,
    required this.arabic,
    required this.french,
    required this.audioUrl,
  });

  final int surahNumber;
  final int ayah;
  final String surahName;
  final String arabic;
  final String french;
  final String? audioUrl;

  String get reference => '$surahName: $ayah';

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final surah = data['surah'] as Map<String, dynamic>;
    final verse = data['verse'] as Map<String, dynamic>;
    final translations = verse['translations'] as Map<String, dynamic>;
    final audio = data['audio'] as List<dynamic>? ?? const [];

    return DailyVerse(
      surahNumber: surah['number'] as int,
      ayah: verse['ayah'] as int,
      surahName: surah['name_english'] as String,
      arabic: verse['arabic'] as String,
      french:
          translations['french'] as String? ??
          translations['sahih_international'] as String,
      audioUrl: audio.isEmpty
          ? null
          : (audio.first as Map<String, dynamic>)['ayah_audio'] as String?,
    );
  }
}
