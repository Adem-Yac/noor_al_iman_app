import '../../../../app/app_settings.dart';
import '../../../../app/content_cache.dart';
import '../../../../data/web_services/ummah_api_service.dart';
import '../models/quran_models.dart';
import '../services/quran_user_data_service.dart';

class QuranRepository {
  QuranRepository({UmmahApiService? api, QuranUserDataService? userData})
    : _api = api ?? UmmahApiService(),
      _userData = userData ?? QuranUserDataService();

  final UmmahApiService _api;
  final QuranUserDataService _userData;

  Future<SurahContent> loadSurah(int number) async {
    final cacheKey = 'surah_$number';
    try {
      final json = await _api.getSurah(number);
      await ContentCache.put(cacheKey, json);
      return SurahContent.fromJson(json);
    } catch (_) {
      if (!AppSettings.offlineBrowseEnabled.value) rethrow;
      final cached = await ContentCache.get(cacheKey);
      if (cached != null) return SurahContent.fromJson(cached);
      rethrow;
    }
  }

  Future<LastReading?> lastReading() => _userData.getLastReading();

  Future<void> saveProgress(LastReading reading) =>
      _userData.saveLastReading(reading);

  Future<List<FavoriteItem>> favorites() => _userData.getFavorites();

  Future<void> toggleFavorite(FavoriteItem item) =>
      _userData.toggleFavorite(item);
}
