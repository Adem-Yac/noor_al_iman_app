import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/web_services/ummah_api_service.dart';
import '../features/home/data/services/location_service.dart';
import '../features/quran/data/surahs.dart';
import 'app_settings.dart';
import 'audio_cache.dart';
import 'content_cache.dart';

/// Télécharge automatiquement Coran / prières / hadiths / douas en Wi‑Fi.
abstract final class OfflinePrefetchService {
  static const _prayerCacheKey = 'home_prayer_cache_v2';
  static bool _running = false;
  static DateTime? _lastRun;

  /// Lance en arrière-plan si Wi‑Fi (ou Ethernet) et lecture hors ligne activée.
  static Future<void> prefetchIfWifi() async {
    if (_running) return;
    if (!AppSettings.offlineBrowseEnabled.value) return;

    try {
      final results = await Connectivity().checkConnectivity();
      if (!_isWifi(results)) return;
    } catch (_) {
      return;
    }

    // Évite de spammer l’API si texte + audio déjà là.
    if (_lastRun != null &&
        DateTime.now().difference(_lastRun!) < const Duration(minutes: 45)) {
      if (await _isQuranComplete() && await _isAudioSpotOk()) return;
    }

    _running = true;
    _lastRun = DateTime.now();
    try {
      await _run();
    } catch (e) {
      debugPrint('OfflinePrefetchService: $e');
    } finally {
      _running = false;
    }
  }

  static bool _isWifi(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  static Future<bool> _isQuranComplete() async {
    // Spot-check + quelques manquantes au milieu.
    for (final n in const [1, 18, 36, 55, 67, 112, 114]) {
      if (!await ContentCache.has('surah_$n')) return false;
    }
    return true;
  }

  static Future<bool> _isAudioSpotOk() async {
    // 1er ayah de quelques sourates = signal que l’audio a démarré.
    for (final n in const [1, 18, 36, 112]) {
      if (!await OfflineAudioCache.hasAyah(n, 1)) return false;
    }
    return true;
  }

  static Future<void> _run() async {
    final api = UmmahApiService();

    // 1) Douas (hub = toutes les catégories)
    try {
      final duas = await api.getDuas();
      await ContentCache.put('duas_hub', duas);
    } catch (e) {
      debugPrint('OfflinePrefetch duas: $e');
    }

    // 2) Prières du jour (si position connue)
    try {
      final loc = await LocationService().readSaved();
      if (loc != null) {
        final json = await api.getPrayerTimes(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        await prefs.setString(
          _prayerCacheKey,
          jsonEncode({
            'day': '${now.year}-${now.month}-${now.day}',
            'lat': loc.latitude,
            'lng': loc.longitude,
            'json': json,
          }),
        );
      }
    } catch (e) {
      debugPrint('OfflinePrefetch prayer: $e');
    }

    // 3) Hadiths : collections + 1re page de chaque
    try {
      final collectionsJson = await api.getHadithCollections();
      await ContentCache.put('hadith_collections', collectionsJson);
      final data = collectionsJson['data'];
      final list = data is Map ? data['collections'] as List? : null;
      if (list != null) {
        for (final raw in list.take(8)) {
          if (raw is! Map) continue;
          final key = raw['key'] as String?;
          if (key == null || key.isEmpty) continue;
          try {
            final page = await api.getHadithCollection(
              collection: key,
              page: 1,
              limit: 20,
            );
            await ContentCache.put('hadith_page_${key}_1_20', page);
            // Featured home utilise limit 3.
            if (key == 'nawawi') {
              final featured = await api.getHadithCollection(
                collection: key,
                page: 1,
                limit: 3,
              );
              await ContentCache.put('hadith_page_${key}_1_3', featured);
            }
          } catch (_) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
      }
    } catch (e) {
      debugPrint('OfflinePrefetch hadith: $e');
    }

    // 4) Coran : 114 sourates (skip déjà présentes) + audio ayahs
    for (final surah in kSurahs) {
      final key = 'surah_${surah.number}';
      final already = await ContentCache.has(key);
      if (!already) {
        try {
          final results = await Connectivity().checkConnectivity();
          if (!_isWifi(results)) break;
          final json = await api.getSurah(surah.number);
          await ContentCache.put(key, json);
        } catch (e) {
          debugPrint('OfflinePrefetch surah ${surah.number}: $e');
          break;
        }
      }

      // Audio Alafasy (EveryAyah) — même Wi‑Fi, saute les fichiers déjà là.
      try {
        await OfflineAudioCache.prefetchSurah(
          surah.number,
          surah.ayahCount,
          shouldContinue: () async {
            if (!AppSettings.offlineBrowseEnabled.value) return false;
            try {
              return _isWifi(await Connectivity().checkConnectivity());
            } catch (_) {
              return false;
            }
          },
        );
      } catch (e) {
        debugPrint('OfflinePrefetch audio ${surah.number}: $e');
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    debugPrint('OfflinePrefetchService: done');
  }
}
