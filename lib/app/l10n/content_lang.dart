import '../../features/duas/data/models/dua_main_categories.dart';
import '../../features/duas/data/models/dua_models.dart';
import '../../features/duas/data/models/dua_titles.dart';
import '../../features/duas/data/models/dua_translations.dart';
import '../../features/hadith/data/models/hadith_models.dart';
import '../../features/home/data/models/home_data.dart';
import '../../features/quran/data/models/quran_models.dart';
import '../../features/quran/data/surahs.dart';
import 'app_lang.dart';
import 'app_strings.dart';

/// Affichage du contenu religieux selon la langue.
abstract final class ContentLang {
  /// Titre doua selon la langue (API = anglais seulement).
  static String duaTitle(Dua dua) {
    return switch (AppLang.current) {
      AppLanguage.fr => DuaTitles.fr(dua.id) ?? dua.title,
      AppLanguage.ar => DuaTitles.ar(dua.id) ?? dua.title,
      AppLanguage.en => dua.title,
    };
  }

  /// Traduction doua — l’API Ummah fournit l’anglais.
  /// FR : dictionnaire local prioritaire, sinon EN (source API).
  static String? duaTranslation(Dua dua) {
    if (!AppLang.showTranslation) return null;
    return switch (AppLang.current) {
      AppLanguage.fr =>
        DuaTranslations.fr(dua.id) ??
            (dua.translation.trim().isEmpty
                ? null
                : dua.translation.trim()),
      AppLanguage.en =>
        dua.translation.trim().isEmpty ? null : dua.translation.trim(),
      AppLanguage.ar => null,
    };
  }

  /// Mention quand la traduction FR manque (fallback API EN).
  static String? duaTranslationSourceNote(Dua dua) {
    if (AppLang.current != AppLanguage.fr) return null;
    if (DuaTranslations.fr(dua.id) != null) return null;
    if (dua.translation.trim().isEmpty) return null;
    return S.translationApiNote;
  }

  /// Afficher la translittération (jamais en arabe).
  static bool get showTransliteration => AppLang.showTranslation;

  static String? hadithTranslation(Hadith hadith) {
    return AppLang.contentTranslation(
      english: hadith.english,
      french: hadith.english,
      fallback: hadith.english,
    );
  }

  static String? ayahTranslation(QuranAyah ayah) {
    return AppLang.contentTranslation(
      french: ayah.french,
      english: ayah.english ?? ayah.french,
      fallback: ayah.french,
    );
  }

  static String? verseTranslation(DailyVerse verse) {
    return AppLang.contentTranslation(
      french: verse.french,
      english: verse.french,
      fallback: verse.french,
    );
  }

  /// Nom de sourate : arabe seul si AR, sinon nom local + arabe.
  static String surahTitle(Surah surah) {
    if (AppLang.isArabic) return surah.arabic;
    final local = switch (AppLang.current) {
      AppLanguage.fr => surah.french,
      AppLanguage.en => surah.latin,
      AppLanguage.ar => surah.arabic,
    };
    return local;
  }

  static String surahSubtitle(Surah surah) {
    if (AppLang.isArabic) return surah.latin;
    return surah.arabic;
  }

  static String categoryLabel(DuaCategory cat) {
    final id = cat.id.toLowerCase().trim();
    // Toujours les labels locaux pour Matin / Soir / Voyage / Autre.
    if (DuaMainCategories.isMain(id)) {
      return switch (AppLang.current) {
        AppLanguage.ar => DuaMainCategories.arabicLabel(id),
        AppLanguage.en => DuaMainCategories.englishLabel(id),
        AppLanguage.fr => DuaMainCategories.frenchLabel(id),
      };
    }
    return switch (AppLang.current) {
      AppLanguage.ar => cat.arabicLabel,
      AppLanguage.en => cat.englishLabel,
      AppLanguage.fr => cat.frenchLabel,
    };
  }

  /// Titre de sourate pour la dernière lecture / favoris.
  static String surahTitleByNumber(int number, {String? fallbackLatin}) {
    final match = kSurahs.where((s) => s.number == number);
    if (match.isEmpty) {
      return fallbackLatin ?? '$number';
    }
    return surahTitle(match.first);
  }

  static String verseLabel(int ayah) {
    return switch (AppLang.current) {
      AppLanguage.ar => 'آية $ayah',
      AppLanguage.en => 'Verse $ayah',
      AppLanguage.fr => 'Verset $ayah',
    };
  }

  static String lastReadingTitle(LastReading? reading) {
    if (reading == null) {
      return surahTitleByNumber(2, fallbackLatin: 'Al-Baqarah');
    }
    return surahTitleByNumber(reading.surah, fallbackLatin: reading.surahLatin);
  }

  static String lastReadingSubtitle(LastReading? reading) {
    if (reading == null) {
      return '${verseLabel(255)} (Ayatul Kursi)';
    }
    return verseLabel(reading.ayah);
  }

  /// Nom de collection hadith selon la langue.
  static String hadithCollectionName(HadithCollection c) {
    if (AppLang.isArabic && c.arabicName.trim().isNotEmpty) {
      return c.arabicName.trim();
    }
    return _collectionName(c.key, fallback: c.name);
  }

  static String hadithCollectionNameByKey(String key, {String? fallback}) {
    return _collectionName(key, fallback: fallback ?? key);
  }

  static String hadithRefLabel(Hadith h) {
    final name = hadithCollectionNameByKey(
      h.collection,
      fallback: h.collectionName,
    );
    return switch (AppLang.current) {
      AppLanguage.ar => '$name · رقم ${h.number}',
      AppLanguage.en => '$name · No. ${h.number}',
      AppLanguage.fr => '$name · n° ${h.number}',
    };
  }

  static String hadithCountLabel(int total) {
    final s = total.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    final n = buf.toString();
    return switch (AppLang.current) {
      AppLanguage.ar => '$n حديث',
      AppLanguage.en => '$n Hadiths',
      AppLanguage.fr => '$n Hadiths',
    };
  }

  static String _collectionName(String key, {required String fallback}) {
    final k = key.toLowerCase().trim();
    final map = switch (AppLang.current) {
      AppLanguage.fr => _collectionsFr,
      AppLanguage.en => _collectionsEn,
      AppLanguage.ar => _collectionsAr,
    };
    return map[k] ?? fallback;
  }

  static const _collectionsFr = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abou Dawoud',
    'tirmidhi': 'Jami at-Tirmidhi',
    'ibnmajah': 'Sunan Ibn Majah',
    'nasai': 'Sunan an-Nasa’i',
    'malik': 'Muwatta Malik',
    'nawawi': 'Les 40 hadiths de Nawawi',
    'qudsi': '40 hadiths Qudsi',
    'dehlawi': 'Les 40 hadiths de Shah Waliullah',
  };

  static const _collectionsEn = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abu Dawud',
    'tirmidhi': 'Jami at-Tirmidhi',
    'ibnmajah': 'Sunan Ibn Majah',
    'nasai': "Sunan an-Nasa'i",
    'malik': 'Muwatta Malik',
    'nawawi': "Nawawi's 40 Hadith",
    'qudsi': '40 Hadith Qudsi',
    'dehlawi': "Shah Waliullah's 40 Hadith",
  };

  static const _collectionsAr = {
    'bukhari': 'صحيح البخاري',
    'muslim': 'صحيح مسلم',
    'abudawud': 'سنن أبي داود',
    'tirmidhi': 'جامع الترمذي',
    'ibnmajah': 'سنن ابن ماجه',
    'nasai': 'سنن النسائي',
    'malik': 'موطأ مالك',
    'nawawi': 'الأربعون النووية',
    'qudsi': 'الأحاديث القدسية',
    'dehlawi': 'الأربعون لولي الله الدهلوي',
  };
}
