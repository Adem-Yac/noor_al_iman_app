import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/web_services/ummah_api_service.dart';
import '../models/hadith_models.dart';

class HadithRepository {
  HadithRepository({UmmahApiService? api}) : _api = api ?? UmmahApiService();

  final UmmahApiService _api;
  static const _favKey = 'hadith_favorites';

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

  /// Hadiths vedette : 1 seul appel API (évite les TimeoutException en rafale).
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
    return prefs.getStringList(_favKey)?.toSet() ?? {};
  }

  Future<Set<String>> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList(_favKey)?.toSet() ?? {};
    if (!set.add(id)) set.remove(id);
    await prefs.setStringList(_favKey, set.toList());
    return set;
  }
}
