class QuranAyah {
  const QuranAyah({
    required this.surahNumber,
    required this.ayah,
    required this.arabic,
    required this.french,
    required this.surahName,
    this.english,
    this.audioUrl,
    this.transliteration,
  });

  final int surahNumber;
  final int ayah;
  final String arabic;
  final String french;
  final String surahName;
  final String? english;
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
      english: translations['sahih_international'] as String?,
      surahName: surahName,
      audioUrl: audioUrl,
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

class LastReading {
  const LastReading({
    required this.surah,
    required this.ayah,
    required this.surahLatin,
    required this.surahArabic,
    this.label,
    this.updatedAt,
  });

  final int surah;
  final int ayah;
  final String surahLatin;
  final String surahArabic;
  final String? label;
  final DateTime? updatedAt;

  String get subtitle => label ?? 'Verset $ayah';

  Map<String, dynamic> toMap() => {
        'surah': surah,
        'ayah': ayah,
        'surahLatin': surahLatin,
        'surahArabic': surahArabic,
        if (label != null) 'label': label,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory LastReading.fromMap(Map<String, dynamic> map) {
    return LastReading(
      surah: _asInt(map['surah']) ?? 1,
      ayah: _asInt(map['ayah']) ?? 1,
      surahLatin: map['surahLatin'] as String? ?? 'Sourate',
      surahArabic: map['surahArabic'] as String? ?? '',
      label: map['label'] as String?,
      updatedAt: _asDate(map['updatedAt']),
    );
  }

  /// Garde la lecture la plus récente (local vs cloud).
  /// Sans horodatage fiable, préfère [a] (local).
  static LastReading? newer(LastReading? a, LastReading? b) {
    if (a == null) return b;
    if (b == null) return a;
    final at = a.updatedAt;
    final bt = b.updatedAt;
    if (at == null || bt == null) return a;
    return !bt.isAfter(at) ? a : b;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    // Firestore Timestamp (sans importer cloud_firestore ici).
    try {
      final dynamic v = value;
      if (v != null && v.toDate is Function) {
        return v.toDate() as DateTime;
      }
    } catch (_) {}
    return null;
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
