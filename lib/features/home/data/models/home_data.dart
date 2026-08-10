import '../../../prayer/data/models/prayer_summary.dart';
import '../../../duas/data/models/dua_models.dart';
import '../../../../app/l10n/app_date_format.dart';

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
}

class HomeData {
  const HomeData({
    required this.location,
    required this.calendar,
    required this.prayer,
    required this.verse,
    this.dailyDua,
    this.morningDua,
    this.eveningDua,
    this.sleepDua,
    this.wakeDua,
  });

  final UserLocation location;
  final IslamicCalendar calendar;
  final PrayerSummary prayer;
  final DailyVerse verse;
  final Dua? dailyDua;
  final Dua? morningDua;
  final Dua? eveningDua;
  final Dua? sleepDua;
  final Dua? wakeDua;
}

class IslamicCalendar {
  const IslamicCalendar({
    required this.gregorianDate,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    this.hijriMonthNameEn,
    this.hijriMonthNameAr,
  });

  final DateTime gregorianDate;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String? hijriMonthNameEn;
  final String? hijriMonthNameAr;

  /// Label grégorien selon la langue choisie (FR / EN / AR).
  String get gregorianLabel => AppDateFormat.weekdayDayMonth(gregorianDate);

  /// Label hijri selon la langue choisie.
  String get hijriLabel {
    if (hijriYear <= 0 || hijriDay <= 0) return '—';
    return AppDateFormat.hijriLabel(
      day: hijriDay,
      month: hijriMonth,
      year: hijriYear,
      englishMonth: hijriMonthNameEn,
      arabicMonth: hijriMonthNameAr,
    );
  }

  factory IslamicCalendar.localToday() {
    final now = DateTime.now();
    return IslamicCalendar(
      gregorianDate: DateTime(now.year, now.month, now.day),
      hijriDay: 0,
      hijriMonth: 1,
      hijriYear: 0,
    );
  }

  factory IslamicCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final gregorian = data['gregorian'] as Map<String, dynamic>;
    final hijri = data['hijri'] as Map<String, dynamic>;

    final year = (gregorian['year'] as num?)?.toInt() ?? DateTime.now().year;
    final month = (gregorian['month'] as num?)?.toInt() ?? DateTime.now().month;
    final day = (gregorian['day'] as num?)?.toInt() ?? DateTime.now().day;

    return IslamicCalendar(
      gregorianDate: DateTime(year, month, day),
      hijriDay: (hijri['day'] as num?)?.toInt() ?? 0,
      hijriMonth: (hijri['month'] as num?)?.toInt() ?? 1,
      hijriYear: (hijri['year'] as num?)?.toInt() ?? 0,
      hijriMonthNameEn: hijri['month_name'] as String?,
      hijriMonthNameAr: hijri['month_name_arabic'] as String?,
    );
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

  static const placeholder = DailyVerse(
    surahNumber: 1,
    ayah: 1,
    surahName: 'Al-Fatiha',
    arabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
    french: 'Au nom d’Allah, le Tout Miséricordieux, le Très Miséricordieux.',
    audioUrl: null,
  );

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
