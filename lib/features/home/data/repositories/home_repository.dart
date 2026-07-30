import 'dart:async';

import '../models/home_data.dart';
import '../services/location_service.dart';
import '../../../../data/web_services/ummah_api_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../duas/data/models/dua_models.dart';
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
    // Sync cloud en arrière-plan — ne bloque pas le premier rendu.
    unawaited(_syncLocationWithCloud());
    final resolved = location ?? await _resolveUserLocation();
    return _fetch(resolved);
  }

  /// Clic localisation : GPS frais → local + sync Firestore.
  Future<HomeData> requestUserLocationAndLoad() async {
    final location = await _locationService.requestAndSave(force: true);
    try {
      await _userRepository.syncLocation(location);
    } catch (_) {}
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
    try {
      final local = await _locationService.readSaved();
      if (local != null) {
        await _userRepository.syncLocation(local);
        return;
      }

      final cloud = await _userRepository.loadCloudLocation();
      if (cloud != null) {
        await _locationService.persist(cloud);
      }
    } catch (_) {}
  }

  Future<HomeData> _fetch(UserLocation location) async {
    final prayerFuture = _api.getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    final verseFuture = _api.getRandomVerse();
    final hijriFuture = _api.getTodayHijri();
    final duasFuture = _safeGetDuas();

    final prayer = await prayerFuture;
    final verse = await verseFuture;
    final hijri = await hijriFuture;
    final duasJson = await duasFuture;

    return HomeData(
      location: location,
      prayer: PrayerSummary.fromJson(prayer),
      verse: DailyVerse.fromJson(verse),
      calendar: IslamicCalendar.fromJson(hijri),
      dailyDua: duasJson == null ? null : _pickDailyDuaSafe(duasJson),
    );
  }

  Future<Map<String, dynamic>?> _safeGetDuas() async {
    try {
      return await _api.getDuas();
    } catch (_) {
      return null;
    }
  }

  Dua? _pickDailyDuaSafe(Map<String, dynamic> json) {
    try {
      return _pickDailyDua(json);
    } catch (_) {
      return null;
    }
  }

  Dua? _pickDailyDua(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final list = (data['duas'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Dua.fromJson)
        .toList();
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return list[dayOfYear % list.length];
  }

  Future<DailyVerse> loadAyah({required int surah, required int ayah}) async {
    return DailyVerse.fromJson(await _api.getAyah(surah: surah, ayah: ayah));
  }
}
