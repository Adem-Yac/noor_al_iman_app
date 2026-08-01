import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  static const _kPrayerCache = 'home_prayer_cache_v2';

  final UmmahApiService _api;
  final LocationService _locationService;
  final UserRepository _userRepository;

  Future<HomeData> loadHome({UserLocation? location}) async {
    unawaited(_syncLocationWithCloud());
    final resolved = location ?? await _resolveUserLocation();
    return _fetch(resolved);
  }

  Future<HomeData> requestUserLocationAndLoad() async {
    final location = await _locationService.requestAndSave(force: true);
    try {
      await _userRepository.syncLocation(location);
    } catch (_) {}
    return _fetch(location);
  }

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
    final results = await Future.wait([
      _safePrayer(location),
      _safeVerse(),
      _safeHijri(),
      _safeGetDuas(),
    ]);

    final prayer = results[0] as PrayerSummary;
    final verse = results[1] as DailyVerse;
    final hijri = results[2] as IslamicCalendar;
    final duasJson = results[3] as Map<String, dynamic>?;

    if (!prayer.hasTimes) {
      throw const UmmahApiException(
        'Impossible de charger les horaires de prière.',
      );
    }

    final duas = duasJson == null ? null : _parseDuas(duasJson);
    final daily = duas == null ? null : _pickDaily(duas);
    final morning = duas == null
        ? null
        : (_pickFromCategory(duas, 'morning') ?? daily);
    final evening = duas == null ? null : _pickFromCategory(duas, 'evening');

    return HomeData(
      location: location,
      prayer: prayer,
      verse: verse,
      calendar: hijri,
      dailyDua: daily,
      morningDua: morning,
      eveningDua: evening,
    );
  }

  Future<PrayerSummary> _safePrayer(UserLocation location) async {
    try {
      final json = await _api.getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      final summary = PrayerSummary.fromJson(json);
      if (summary.hasTimes) {
        unawaited(_cachePrayer(location, json));
        return summary;
      }
    } catch (_) {}

    return await _readCachedPrayer(location) ?? PrayerSummary.empty;
  }

  Future<DailyVerse> _safeVerse() async {
    try {
      return DailyVerse.fromJson(await _api.getRandomVerse());
    } catch (_) {
      return DailyVerse.placeholder;
    }
  }

  Future<IslamicCalendar> _safeHijri() async {
    try {
      return IslamicCalendar.fromJson(await _api.getTodayHijri());
    } catch (_) {
      return IslamicCalendar.localToday();
    }
  }

  Future<void> _cachePrayer(
    UserLocation location,
    Map<String, dynamic> json,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final payload = {
        'day': '${now.year}-${now.month}-${now.day}',
        'lat': location.latitude,
        'lng': location.longitude,
        'json': json,
      };
      await prefs.setString(_kPrayerCache, jsonEncode(payload));
    } catch (_) {}
  }

  Future<PrayerSummary?> _readCachedPrayer(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrayerCache);
      if (raw == null || raw.isEmpty) return null;
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) return null;

      final now = DateTime.now();
      final day = '${now.year}-${now.month}-${now.day}';
      if (payload['day'] != day) return null;

      final lat = (payload['lat'] as num?)?.toDouble();
      final lng = (payload['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      if ((lat - location.latitude).abs() > 0.05 ||
          (lng - location.longitude).abs() > 0.05) {
        return null;
      }

      final json = payload['json'];
      if (json is! Map<String, dynamic>) return null;
      final summary = PrayerSummary.fromJson(json);
      return summary.hasTimes ? summary : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetDuas() async {
    try {
      return await _api.getDuas();
    } catch (_) {
      return null;
    }
  }

  List<Dua>? _parseDuas(Map<String, dynamic> json) {
    try {
      return DuasHub.fromJson(json).duas;
    } catch (_) {
      return null;
    }
  }

  Dua? _pickDaily(List<Dua> list) {
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return list[dayOfYear % list.length];
  }

  Dua? _pickFromCategory(List<Dua> list, String category) {
    final filtered = list.where((d) => d.category == category).toList();
    if (filtered.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return filtered[dayOfYear % filtered.length];
  }

  Future<DailyVerse> loadAyah({required int surah, required int ayah}) async {
    return DailyVerse.fromJson(await _api.getAyah(surah: surah, ayah: ayah));
  }
}
