import '../../../../app/app_settings.dart';
import '../../../../app/content_cache.dart';
import '../../../../data/web_services/ummah_api_service.dart';
import '../models/dua_main_categories.dart';
import '../models/dua_models.dart';

class DuasRepository {
  DuasRepository({UmmahApiService? api}) : _api = api ?? UmmahApiService();

  final UmmahApiService _api;
  static const _hubKey = 'duas_hub';

  Future<DuasHub> getHub() async {
    try {
      final json = await _api.getDuas();
      await ContentCache.put(_hubKey, json);
      return DuasHub.fromJson(json);
    } catch (_) {
      if (!AppSettings.offlineBrowseEnabled.value) rethrow;
      final cached = await ContentCache.get(_hubKey);
      if (cached != null) return DuasHub.fromJson(cached);
      rethrow;
    }
  }

  Future<List<Dua>> getByCategory(String category) async {
    // Réveil / sommeil : même API `sleep`, filtrée localement.
    if (DuaMainCategories.isWake(category)) {
      final sleep = await _fetchApiCategory('sleep');
      return sleep.where(DuaMainCategories.isWakeDua).toList();
    }
    if (category == 'sleep') {
      final sleep = await _fetchApiCategory('sleep');
      return sleep.where(DuaMainCategories.isSleepBedtime).toList();
    }
    return _fetchApiCategory(category);
  }

  Future<List<Dua>> _fetchApiCategory(String category) async {
    final cacheKey = 'duas_cat_$category';
    try {
      final json = await _api.getDuas(category: category);
      await ContentCache.put(cacheKey, json);
      return _parseCategory(json);
    } catch (_) {
      if (!AppSettings.offlineBrowseEnabled.value) rethrow;
      final cached = await ContentCache.get(cacheKey);
      if (cached != null) return _parseCategory(cached);
      try {
        final hub = await getHub();
        return hub.duas.where((d) => d.category == category).toList();
      } catch (_) {
        rethrow;
      }
    }
  }

  List<Dua> _parseCategory(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return (data['duas'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Dua.fromJson)
        .toList();
  }
}
