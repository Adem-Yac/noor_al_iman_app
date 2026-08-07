class HadithCollection {
  const HadithCollection({
    required this.key,
    required this.name,
    required this.arabicName,
    required this.author,
    required this.totalHadiths,
  });

  final String key;
  final String name;
  final String arabicName;
  final String author;
  final int totalHadiths;

  factory HadithCollection.fromJson(Map<String, dynamic> json) {
    return HadithCollection(
      key: json['key'] as String,
      name: json['name'] as String,
      arabicName: json['arabic_name'] as String? ?? '',
      author: json['author'] as String? ?? '',
      totalHadiths: (json['total_hadiths'] as num?)?.toInt() ?? 0,
    );
  }

  String get countLabel {
    final s = totalHadiths.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} Hadiths';
  }
}

class Hadith {
  const Hadith({
    required this.id,
    required this.collection,
    required this.collectionName,
    required this.number,
    required this.arabic,
    required this.english,
    this.grade,
  });

  final String id;
  final String collection;
  final String collectionName;
  final int number;
  final String arabic;
  final String english;
  final String? grade;

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String? ??
          '${json['collection']}-${json['hadithnumber']}',
      collection: json['collection'] as String? ?? '',
      collectionName: json['collection_name'] as String? ?? '',
      number: (json['hadithnumber'] as num?)?.toInt() ?? 0,
      arabic: json['arabic'] as String? ?? '',
      english: json['english'] as String? ?? '',
      grade: json['grade'] as String?,
    );
  }

  String get refLabel => '$collectionName · n° $number';

  String get arabicPreview {
    final t = arabic.trim();
    if (t.isEmpty) return quotePreview;
    if (t.length <= 120) return t;
    return '${t.substring(0, 120).trimRight()}…';
  }

  String get arabicShort {
    final t = arabic.trim();
    if (t.isEmpty) return quotePreview;
    if (t.length <= 80) return t;
    return '${t.substring(0, 80).trimRight()}…';
  }

  String get preview {
    final t = english.trim();
    if (t.length <= 140) return t;
    return '${t.substring(0, 140).trimRight()}…';
  }

  String get quotePreview {
    final t = english.trim();
    final quote = RegExp(r'"([^"]{20,})"').firstMatch(t)?.group(1);
    final src = quote ?? t;
    if (src.length <= 110) return src;
    return '${src.substring(0, 110).trimRight()}…';
  }

  String? get narrator {
    final m = RegExp(
      r'^Narrated\s+([^:]+):',
      caseSensitive: false,
    ).firstMatch(english.trim());
    return m?.group(1)?.trim();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'collection': collection,
    'collection_name': collectionName,
    'hadithnumber': number,
    'arabic': arabic,
    'english': english,
    'grade': grade,
  };

  factory Hadith.fromMap(Map<String, dynamic> map) => Hadith.fromJson(map);
}

class HadithPageResult {
  const HadithPageResult({
    required this.collection,
    required this.collectionName,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hadiths,
  });

  final String collection;
  final String collectionName;
  final int page;
  final int totalPages;
  final int total;
  final List<Hadith> hadiths;

  factory HadithPageResult.fromJson(Map<String, dynamic> data) {
    final list = (data['hadiths'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Hadith.fromJson)
        .toList();
    return HadithPageResult(
      collection: data['collection'] as String? ?? '',
      collectionName: data['collection_name'] as String? ?? '',
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
      total: (data['total'] as num?)?.toInt() ?? list.length,
      hadiths: list,
    );
  }
}
