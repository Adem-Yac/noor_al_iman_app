import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/web_services/ummah_api_service.dart';
import '../models/hadith_models.dart';

class HadithRepository {
  HadithRepository({UmmahApiService? api}) : _api = api ?? UmmahApiService();

  final UmmahApiService _api;
  static const _favIdsKey = 'hadith_favorites';
  static const _favDataKey = 'hadith_favorites_data_v1';

  Future<List<HadithCollection>> getCollections() async {
    final json = await _api.getHadithCollections();
    final data = json['data'] as Map<String, dynamic>;
    return (data['collections'] as List)
        .whereType<Map<String, dynamic>>()
        .map(HadithCollection.fromJson)
        .toList();
  }

  Future<Hadith> getRandom() async {
    final json = await _api.getRandomHadith();
    return Hadith.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<HadithPageResult> getCollectionPage({
    required String collection,
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _api.getHadithCollection(
      collection: collection,
      page: page,
      limit: limit,
    );
    return HadithPageResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<Hadith>> getFeatured() async {
    try {
      final page = await getCollectionPage(
        collection: 'nawawi',
        page: 1,
        limit: 3,
      );
      if (page.hadiths.isNotEmpty) return page.hadiths;
    } catch (_) {}

    try {
      return [await getRandom()];
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favIdsKey)?.toSet() ?? {};
  }

  Future<List<Hadith>> loadFavoriteHadiths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favDataKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => Hadith.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> toggleFavorite(Hadith hadith) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favIdsKey)?.toSet() ?? {};
    final items = await loadFavoriteHadiths();

    if (ids.contains(hadith.id)) {
      ids.remove(hadith.id);
      items.removeWhere((h) => h.id == hadith.id);
    } else {
      ids.add(hadith.id);
      if (!items.any((h) => h.id == hadith.id)) {
        items.insert(0, hadith);
      }
    }

    await prefs.setStringList(_favIdsKey, ids.toList());
    await prefs.setString(
      _favDataKey,
      jsonEncode([for (final h in items) h.toMap()]),
    );
    return ids;
  }
}
