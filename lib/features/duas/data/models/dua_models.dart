import 'dua_main_categories.dart';

class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.count,
  });

  final String id;
  final String name;
  final String description;
  final int count;

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  String get frenchLabel =>
      DuaMainCategories.isMain(id)
          ? DuaMainCategories.frenchLabel(id)
          : _categoryLabelsFr[id] ?? name;

  String get arabicLabel =>
      DuaMainCategories.isMain(id)
          ? DuaMainCategories.arabicLabel(id)
          : _categoryLabelsAr[id] ?? name;

  String get englishLabel =>
      DuaMainCategories.isMain(id)
          ? DuaMainCategories.englishLabel(id)
          : _categoryLabelsEn[id] ?? name;

  static const _categoryLabelsFr = {
    'morning': 'Matin',
    'evening': 'Soir',
    'wudu': 'Ablutions',
    'prayer': 'Pendant la prière',
    'after_prayer': 'Après la prière',
    'sleep': 'Sommeil',
    'food': 'Nourriture',
    'travel': 'Voyage',
    'home': 'Maison',
    'masjid': 'Mosquée',
    'protection': 'Protection',
    'forgiveness': 'Pardon',
    'gratitude': 'Gratitude',
    'distress': 'Détresse',
    'rain': 'Pluie',
    'weather': 'Météo',
    'sickness': 'Maladie',
    'death': 'Décès',
    'general': 'Général',
  };

  static const _categoryLabelsAr = {
    'morning': 'الصباح',
    'evening': 'المساء',
    'wudu': 'الوضوء',
    'prayer': 'أثناء الصلاة',
    'after_prayer': 'بعد الصلاة',
    'sleep': 'النوم',
    'food': 'الطعام',
    'travel': 'السفر',
    'home': 'المنزل',
    'masjid': 'المسجد',
    'protection': 'الحماية',
    'forgiveness': 'الاستغفار',
    'gratitude': 'الشكر',
    'distress': 'الهمّ',
    'rain': 'المطر',
    'weather': 'الطقس',
    'sickness': 'المرض',
    'death': 'الموت',
    'general': 'عام',
  };

  static const _categoryLabelsEn = {
    'morning': 'Morning',
    'evening': 'Evening',
    'wudu': 'Ablution',
    'prayer': 'During prayer',
    'after_prayer': 'After prayer',
    'sleep': 'Sleep',
    'food': 'Food',
    'travel': 'Travel',
    'home': 'Home',
    'masjid': 'Mosque',
    'protection': 'Protection',
    'forgiveness': 'Forgiveness',
    'gratitude': 'Gratitude',
    'distress': 'Distress',
    'rain': 'Rain',
    'weather': 'Weather',
    'sickness': 'Sickness',
    'death': 'Death',
    'general': 'General',
  };
}

class Dua {
  const Dua({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
    required this.repeat,
  });

  final int id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final int repeat;

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String,
      title: json['title'] as String,
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      source: json['source'] as String? ?? '',
      repeat: (json['repeat'] as num?)?.toInt() ?? 1,
    );
  }
}

class DuasHub {
  const DuasHub({required this.categories, required this.duas});

  final List<DuaCategory> categories;
  final List<Dua> duas;

  factory DuasHub.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DuasHub(
      categories: (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DuaCategory.fromJson)
          .toList(),
      duas: (data['duas'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Dua.fromJson)
          .toList(),
    );
  }
}
