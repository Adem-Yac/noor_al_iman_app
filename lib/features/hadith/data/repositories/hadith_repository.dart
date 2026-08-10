import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_settings.dart';
import '../../../../app/content_cache.dart';
import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
import '../../../../app/user_data_sync_service.dart';
import '../../../../data/web_services/ummah_api_service.dart';
import '../models/hadith_models.dart';

class HadithRepository {
  HadithRepository({UmmahApiService? api}) : _api = api ?? UmmahApiService();

  final UmmahApiService _api;
  static const _favIdsKey = 'hadith_favorites';
  static const _favDataKey = 'hadith_favorites_data_v1';
  static const _collectionsCache = 'hadith_collections';

  bool get _canUseCloud {
    if (!firebaseReady) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<List<HadithCollection>> getCollections() async {
    try {
      final json = await _api.getHadithCollections();
      await ContentCache.put(_collectionsCache, json);
      return _parseCollections(json);
    } catch (_) {
      if (!AppSettings.offlineBrowseEnabled.value) rethrow;
      final cached = await ContentCache.get(_collectionsCache);
      if (cached != null) return _parseCollections(cached);
      rethrow;
    }
  }

  List<HadithCollection> _parseCollections(Map<String, dynamic> json) {
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

  Future<HadithPageResult> getCollectionPage({
    required String collection,
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey = 'hadith_page_${collection}_${page}_$limit';
    try {
      final json = await _api.getHadithCollection(
        collection: collection,
        page: page,
        limit: limit,
      );
      await ContentCache.put(cacheKey, json);
      return HadithPageResult.fromJson(json['data'] as Map<String, dynamic>);
    } catch (_) {
      if (!AppSettings.offlineBrowseEnabled.value) rethrow;
      final cached = await ContentCache.get(cacheKey);
      if (cached != null) {
        return HadithPageResult.fromJson(
          cached['data'] as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  Future<List<Hadith>> getFeatured() async {
    try {
      final page = await getCollectionPage(
        collection: 'nawawi',
        page: 1,
        limit: 3,
      );
      if (page.hadiths.isNotEmpty) return page.hadiths;
    } catch (_) {}

    try {
      return [await getRandom()];
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> loadFavorites() async {
    if (_canUseCloud) {
      try {
        await _hydrateFavoritesFromCloud();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favIdsKey)?.toSet() ?? {};
  }

  Future<List<Hadith>> loadFavoriteHadiths() async {
    if (_canUseCloud) {
      try {
        await _hydrateFavoritesFromCloud();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favDataKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => Hadith.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> toggleFavorite(Hadith hadith) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favIdsKey)?.toSet() ?? {};
    final items = await loadFavoriteHadiths();

    if (ids.contains(hadith.id)) {
      ids.remove(hadith.id);
      items.removeWhere((h) => h.id == hadith.id);
    } else {
      ids.add(hadith.id);
      if (!items.any((h) => h.id == hadith.id)) {
        items.insert(0, hadith);
      }
    }

    await prefs.setStringList(_favIdsKey, ids.toList());
    await prefs.setString(
      _favDataKey,
      jsonEncode([for (final h in items) h.toMap()]),
    );
    try {
      await pushFavoritesToCloud();
    } catch (_) {}
    return ids;
  }

  Future<void> pushFavoritesToCloud() async {
    if (!_canUseCloud) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_favDataKey);
      final items = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list.whereType<Map>()) {
          items.add(Map<String, dynamic>.from(e));
        }
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection(FirestorePaths.hadithData)
          .doc(uid)
          .set({
        'favorites': items,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Règles pas encore déployées / hors ligne → retry au prochain sync.
      await UserDataSyncService.markPending();
    }
  }

  Future<void> _hydrateFavoritesFromCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLocal = (prefs.getStringList(_favIdsKey)?.isNotEmpty ?? false) ||
          (prefs.getString(_favDataKey)?.isNotEmpty ?? false);
      if (hasLocal) return;

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.hadithData)
          .doc(uid)
          .get();
      final raw = snap.data()?['favorites'] as List<dynamic>?;
      if (raw == null) return;

      final items = [
        for (final e in raw.whereType<Map>())
          Hadith.fromMap(Map<String, dynamic>.from(e)),
      ];
      await prefs.setStringList(
        _favIdsKey,
        [for (final h in items) h.id],
      );
      await prefs.setString(
        _favDataKey,
        jsonEncode([for (final h in items) h.toMap()]),
      );
    } catch (_) {
      // Permission / offline — rester sur le local.
    }
  }
}
