import 'package:intl/intl.dart';

import 'app_lang.dart';

/// Dates / mois / jours selon la langue de l’app (FR · EN · AR).
abstract final class AppDateFormat {
  static String get localeTag => switch (AppLang.current) {
        AppLanguage.fr => 'fr',
        AppLanguage.en => 'en',
        AppLanguage.ar => 'ar',
      };

  /// Ex. « lundi 10 août » / « Monday 10 August » / « الاثنين 10 أغسطس »
  static String weekdayDayMonth(DateTime date) {
    return DateFormat('EEEE d MMMM', localeTag).format(date);
  }

  /// Ex. « août 2026 » / « August 2026 » / « أغسطس 2026 »
  static String monthYear(DateTime date) {
    return DateFormat('MMMM y', localeTag).format(date);
  }

  /// Abréviation jour (LUN / Mon / إثن)
  static String weekdayShort(DateTime date) {
    return DateFormat('EEE', localeTag).format(date);
  }

  static String weekdayShortFromWeekday(int weekday) {
    // DateTime.monday = 1 … sunday = 7
    final d = DateTime(2024, 1, weekday); // 2024-01-01 = Monday
    return weekdayShort(d);
  }

  /// Mois hijri 1–12 selon la langue.
  static String hijriMonthName(int month, {String? englishFallback, String? arabicFallback}) {
    final m = month.clamp(1, 12);
    return switch (AppLang.current) {
      AppLanguage.ar =>
        (arabicFallback != null && arabicFallback.trim().isNotEmpty)
            ? arabicFallback.trim()
            : _hijriAr[m - 1],
      AppLanguage.en =>
        (englishFallback != null && englishFallback.trim().isNotEmpty)
            ? englishFallback.trim()
            : _hijriEn[m - 1],
      AppLanguage.fr => _hijriFr[m - 1],
    };
  }

  static String hijriLabel({
    required int day,
    required int month,
    required int year,
    String? englishMonth,
    String? arabicMonth,
  }) {
    final name = hijriMonthName(
      month,
      englishFallback: englishMonth,
      arabicFallback: arabicMonth,
    );
    return '$day $name $year';
  }

  static const _hijriEn = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhul Qi'dah",
    'Dhul Hijjah',
  ];

  static const _hijriFr = [
    'Mouharram',
    'Safar',
    'Rabi’ al-awwal',
    'Rabi’ ath-thani',
    'Joumada al-oula',
    'Joumada ath-thania',
    'Rajab',
    'Chaabane',
    'Ramadan',
    'Chawwal',
    'Dhou al-qi’da',
    'Dhou al-hijja',
  ];

  static const _hijriAr = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع ٱلْأَوَّل',
    'رَبِيع ٱلثَّانِي',
    'جُمَادَىٰ ٱلْأُولَىٰ',
    'جُمَادَىٰ ٱلْآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو ٱلْقَعْدَة',
    'ذُو ٱلْحِجَّة',
  ];
}
