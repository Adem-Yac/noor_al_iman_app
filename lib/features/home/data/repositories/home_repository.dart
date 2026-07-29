import '../models/home_data.dart';
import '../services/location_service.dart';
import '../../../../data/web_services/ummah_api_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../prayer/data/models/prayer_summary.dart';

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
    await _syncLocationWithCloud();
    final resolved = location ?? await _resolveUserLocation();
    return _fetch(resolved);
  }

  /// Clic localisation : GPS frais → local + sync Firestore.
  Future<HomeData> requestUserLocationAndLoad() async {
    final location = await _locationService.requestAndSave(force: true);
    await _userRepository.syncLocation(location);
    return _fetch(location);
  }

  /// Position : sauvegardée / cloud / GPS (première ouverture) / repli.
  Future<UserLocation> _resolveUserLocation() async {
    final saved = await _locationService.readSaved();
    if (saved != null) return saved;

    try {
      final gps = await _locationService.requestAndSave();
      await _userRepository.syncLocation(gps);
      return gps;
    } on LocationException {
      return UserLocation.fallback;
    } catch (_) {
      return UserLocation.fallback;
    }
  }

  Future<void> _syncLocationWithCloud() async {
    final local = await _locationService.readSaved();
    if (local != null) {
      await _userRepository.syncLocation(local);
      return;
    }

    final cloud = await _userRepository.loadCloudLocation();
    if (cloud != null) {
      await _locationService.persist(cloud);
    }
  }

  Future<HomeData> _fetch(UserLocation location) async {
    final core = await Future.wait([
      _api.getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      _api.getRandomVerse(),
      _api.getTodayHijri(),
    ]);

    return HomeData(
      location: location,
      prayer: PrayerSummary.fromJson(core[0]),
      verse: DailyVerse.fromJson(core[1]),
      calendar: IslamicCalendar.fromJson(core[2]),
    );
  }

  Future<DailyVerse> loadAyah({required int surah, required int ayah}) async {
    return DailyVerse.fromJson(await _api.getAyah(surah: surah, ayah: ayah));
  }
}
