import '../models/home_data.dart';
import '../services/location_service.dart';
import '../services/ummah_api_service.dart';
import '../../../auth/data/repositories/user_repository.dart';

class HomeRepository {
  HomeRepository({
    UmmahApiService? api,
    LocationService? locationService,
    UserRepository? userRepository,
  }) : _api = api ?? UmmahApiService(),
       _locationService = locationService ?? LocationService(),
       _userRepository = userRepository ?? UserRepository();

  final UmmahApiService _api;
  final LocationService _locationService;
  final UserRepository _userRepository;

  Future<HomeData> loadHome({UserLocation? location}) async {
    await _restoreCloudLocationIfNeeded();
    final resolved = location ?? await _locationService.loadSavedOrFallback();
    return _fetch(resolved);
  }

  /// Clic localisation : GPS une fois, puis sauvegarde locale + cloud.
  Future<HomeData> requestUserLocationAndLoad() async {
    final location = await _locationService.requestAndSave();
    await _userRepository.syncLocation(location);
    return _fetch(location);
  }

  Future<void> _restoreCloudLocationIfNeeded() async {
    final local = await _locationService.readSaved();
    if (local != null) return;

    final cloud = await _userRepository.loadCloudLocation();
    if (cloud != null) {
      await _locationService.persist(cloud);
    }
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
