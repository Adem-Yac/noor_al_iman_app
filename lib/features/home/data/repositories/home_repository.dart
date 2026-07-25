import '../models/home_data.dart';
import '../services/location_service.dart';
import '../services/ummah_api_service.dart';

class HomeRepository {
  HomeRepository({UmmahApiService? api, LocationService? locationService})
    : _api = api ?? UmmahApiService(),
      _locationService = locationService ?? LocationService();

  final UmmahApiService _api;
  final LocationService _locationService;

  Future<HomeData> loadHome({UserLocation? location}) async {
    final resolved = location ?? await _locationService.loadSavedOrFallback();
    return _fetch(resolved);
  }

  /// Clic localisation : GPS une fois, puis sauvegarde locale.
  Future<HomeData> requestUserLocationAndLoad() async {
    final location = await _locationService.requestAndSave();
    return _fetch(location);
  }

  Future<HomeData> _fetch(UserLocation location) async {
    final results = await Future.wait([
      _api.getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      _api.getRandomVerse(),
      _api.getTodayHijri(),
    ]);

    return HomeData(
      location: location,
      prayer: PrayerSummary.fromJson(results[0]),
      verse: DailyVerse.fromJson(results[1]),
      calendar: IslamicCalendar.fromJson(results[2]),
    );
  }

  Future<DailyVerse> loadAyah({required int surah, required int ayah}) async {
    return DailyVerse.fromJson(await _api.getAyah(surah: surah, ayah: ayah));
  }
}
