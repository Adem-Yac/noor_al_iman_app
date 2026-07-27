class QuranAyah {
  const QuranAyah({
    required this.surahNumber,
    required this.ayah,
    required this.arabic,
    required this.french,
    required this.surahName,
    this.audioUrl,
    this.transliteration,
  });

  final int surahNumber;
  final int ayah;
  final String arabic;
  final String french;
  final String surahName;
  final String? audioUrl;
  final String? transliteration;

  String get key => '$surahNumber:$ayah';
  String get reference => '$surahName $ayah';

  factory QuranAyah.fromSurahVerse(
    Map<String, dynamic> verse, {
    required int surahNumber,
    required String surahName,
  }) {
    final translations = verse['translations'] as Map<String, dynamic>? ?? {};
    final audio = verse['audio'];
    String? audioUrl;
    if (audio is Map<String, dynamic>) {
      audioUrl = audio['ayah_audio'] as String?;
    }
    audioUrl ??= everyAyahAudioUrl(surahNumber, verse['ayah'] as int);

    return QuranAyah(
      surahNumber: surahNumber,
      ayah: verse['ayah'] as int,
      arabic: verse['arabic'] as String,
      french:
          translations['french'] as String? ??
          translations['sahih_international'] as String? ??
          '',
      surahName: surahName,
      audioUrl: audioUrl,
      transliteration: verse['transliteration'] as String?,
    );
  }

  factory QuranAyah.fromJuzVerse(Map<String, dynamic> verse) {
    final key = verse['verse_key'] as String;
    final parts = key.split(':');
    final surahNumber = int.parse(parts[0]);
    final ayah = verse['ayah'] as int? ?? int.parse(parts[1]);
    final translations = verse['translations'] as Map<String, dynamic>? ?? {};

    return QuranAyah(
      surahNumber: surahNumber,
      ayah: ayah,
      arabic: verse['arabic'] as String,
      french:
          translations['french'] as String? ??
          translations['sahih_international'] as String? ??
          '',
      surahName: verse['surah_name'] as String? ?? 'Sourate $surahNumber',
      audioUrl: everyAyahAudioUrl(surahNumber, ayah),
      transliteration: verse['transliteration'] as String?,
    );
  }
}

class SurahContent {
  const SurahContent({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
    required this.ayahs,
    this.surahAudioUrl,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;
  final List<QuranAyah> ayahs;
  final String? surahAudioUrl;

  factory SurahContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final surah = data['surah'] as Map<String, dynamic>;
    final number = surah['number'] as int;
    final nameEnglish = surah['name_english'] as String;
    final verses = (data['verses'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final audioList = data['audio'] as List<dynamic>? ?? const [];
    final firstAudio = audioList.isEmpty
        ? null
        : (audioList.first as Map<String, dynamic>)['surah_audio'] as String?;

    return SurahContent(
      number: number,
      nameArabic: surah['name_arabic'] as String,
      nameEnglish: nameEnglish,
      versesCount: surah['verses_count'] as int,
      surahAudioUrl: firstAudio,
      ayahs: [
        for (final v in verses)
          QuranAyah.fromSurahVerse(
            v,
            surahNumber: number,
            surahName: nameEnglish,
          ),
      ],
    );
  }
}

class JuzContent {
  const JuzContent({
    required this.number,
    required this.totalVerses,
    required this.versesMapping,
    required this.ayahs,
  });

  final int number;
  final int totalVerses;
  final Map<String, String> versesMapping;
  final List<QuranAyah> ayahs;

  factory JuzContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final mapping = (data['verses_mapping'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    );
    final verses = (data['verses'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return JuzContent(
      number: data['juz_number'] as int,
      totalVerses: data['total_verses'] as int,
      versesMapping: mapping,
      ayahs: [for (final v in verses) QuranAyah.fromJuzVerse(v)],
    );
  }
}

class LastReading {
  const LastReading({
    required this.surah,
    required this.ayah,
    required this.surahLatin,
    required this.surahArabic,
    this.label,
  });

  final int surah;
  final int ayah;
  final String surahLatin;
  final String surahArabic;
  final String? label;

  String get subtitle => label ?? 'Verset $ayah';

  Map<String, dynamic> toMap() => {
    'surah': surah,
    'ayah': ayah,
    'surahLatin': surahLatin,
    'surahArabic': surahArabic,
    if (label != null) 'label': label,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  factory LastReading.fromMap(Map<String, dynamic> map) {
    return LastReading(
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      surahLatin: map['surahLatin'] as String? ?? 'Sourate',
      surahArabic: map['surahArabic'] as String? ?? '',
      label: map['label'] as String?,
    );
  }
}

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.type,
    required this.surah,
    required this.surahLatin,
    required this.surahArabic,
    this.ayah,
    this.arabicPreview,
  });

  /// `surah:1` or `ayah:2:255`
  final String id;
  final String type; // surah | ayah
  final int surah;
  final int? ayah;
  final String surahLatin;
  final String surahArabic;
  final String? arabicPreview;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'surah': surah,
    'ayah': ayah,
    'surahLatin': surahLatin,
    'surahArabic': surahArabic,
    'arabicPreview': arabicPreview,
  };

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      type: map['type'] as String,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int?,
      surahLatin: map['surahLatin'] as String? ?? '',
      surahArabic: map['surahArabic'] as String? ?? '',
      arabicPreview: map['arabicPreview'] as String?,
    );
  }

  static String surahId(int surah) => 'surah:$surah';
  static String ayahId(int surah, int ayah) => 'ayah:$surah:$ayah';
}

String everyAyahAudioUrl(int surah, int ayah) {
  final s = surah.toString().padLeft(3, '0');
  final a = ayah.toString().padLeft(3, '0');
  return 'https://everyayah.com/data/Alafasy_128kbps/$s$a.mp3';
}

/// Métadonnées des 30 juz (début / fin).
const List<({int number, String start, String end, int startSurah, int startAyah})>
kJuzMeta = [
  (number: 1, start: '1:1', end: '2:141', startSurah: 1, startAyah: 1),
  (number: 2, start: '2:142', end: '2:252', startSurah: 2, startAyah: 142),
  (number: 3, start: '2:253', end: '3:92', startSurah: 2, startAyah: 253),
  (number: 4, start: '3:93', end: '4:23', startSurah: 3, startAyah: 93),
  (number: 5, start: '4:24', end: '4:147', startSurah: 4, startAyah: 24),
  (number: 6, start: '4:148', end: '5:81', startSurah: 4, startAyah: 148),
  (number: 7, start: '5:82', end: '6:110', startSurah: 5, startAyah: 82),
  (number: 8, start: '6:111', end: '7:87', startSurah: 6, startAyah: 111),
  (number: 9, start: '7:88', end: '8:40', startSurah: 7, startAyah: 88),
  (number: 10, start: '8:41', end: '9:92', startSurah: 8, startAyah: 41),
  (number: 11, start: '9:93', end: '11:5', startSurah: 9, startAyah: 93),
  (number: 12, start: '11:6', end: '12:52', startSurah: 11, startAyah: 6),
  (number: 13, start: '12:53', end: '14:52', startSurah: 12, startAyah: 53),
  (number: 14, start: '15:1', end: '16:128', startSurah: 15, startAyah: 1),
  (number: 15, start: '17:1', end: '18:74', startSurah: 17, startAyah: 1),
  (number: 16, start: '18:75', end: '20:135', startSurah: 18, startAyah: 75),
  (number: 17, start: '21:1', end: '22:78', startSurah: 21, startAyah: 1),
  (number: 18, start: '23:1', end: '25:20', startSurah: 23, startAyah: 1),
  (number: 19, start: '25:21', end: '27:55', startSurah: 25, startAyah: 21),
  (number: 20, start: '27:56', end: '29:45', startSurah: 27, startAyah: 56),
  (number: 21, start: '29:46', end: '33:30', startSurah: 29, startAyah: 46),
  (number: 22, start: '33:31', end: '36:27', startSurah: 33, startAyah: 31),
  (number: 23, start: '36:28', end: '39:31', startSurah: 36, startAyah: 28),
  (number: 24, start: '39:32', end: '41:46', startSurah: 39, startAyah: 32),
  (number: 25, start: '41:47', end: '45:37', startSurah: 41, startAyah: 47),
  (number: 26, start: '46:1', end: '51:30', startSurah: 46, startAyah: 1),
  (number: 27, start: '51:31', end: '57:29', startSurah: 51, startAyah: 31),
  (number: 28, start: '58:1', end: '66:12', startSurah: 58, startAyah: 1),
  (number: 29, start: '67:1', end: '77:50', startSurah: 67, startAyah: 1),
  (number: 30, start: '78:1', end: '114:6', startSurah: 78, startAyah: 1),
];
