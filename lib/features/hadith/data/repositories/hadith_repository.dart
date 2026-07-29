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

  Future<Hadith> getHadith({
    required String collection,
    required int number,
  }) async {
    final json = await _api.getHadith(collection: collection, number: number);
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

  Future<List<Hadith>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final json = await _api.searchHadith(query: q, limit: limit);
    final data = json['data'] as Map<String, dynamic>;
    return (data['hadiths'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Hadith.fromJson)
        .toList();
  }

  /// Quelques hadiths « vedette » pour le hub (IDs stables).
  Future<List<Hadith>> getFeatured() async {
    const refs = [
      ('bukhari', 1),
      ('muslim', 1),
      ('nawawi', 1),
      ('bukhari', 8),
      ('tirmidhi', 1),
    ];
    final out = <Hadith>[];
    for (final r in refs) {
      try {
        out.add(await getHadith(collection: r.$1, number: r.$2));
      } catch (_) {}
    }
    return out;
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
