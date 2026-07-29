import '../../../../data/web_services/ummah_api_service.dart';
import '../models/quran_models.dart';
import '../services/quran_user_data_service.dart';

class QuranRepository {
  QuranRepository({UmmahApiService? api, QuranUserDataService? userData})
    : _api = api ?? UmmahApiService(),
      _userData = userData ?? QuranUserDataService();

  final UmmahApiService _api;
  final QuranUserDataService _userData;

  QuranUserDataService get userData => _userData;

  Future<SurahContent> loadSurah(int number) async {
    return SurahContent.fromJson(await _api.getSurah(number));
  }

  Future<LastReading?> lastReading() => _userData.getLastReading();

  Future<void> saveProgress(LastReading reading) =>
      _userData.saveLastReading(reading);

  Future<List<FavoriteItem>> favorites() => _userData.getFavorites();

  Future<void> toggleFavorite(FavoriteItem item) =>
      _userData.toggleFavorite(item);
}
