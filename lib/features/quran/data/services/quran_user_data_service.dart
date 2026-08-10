import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
import '../../../../app/user_data_sync_service.dart';
import '../models/quran_models.dart';

/// Lecture / favoris :
/// - sauvegarde : local + Firestore (si connecté)
/// - chargement : Firestore en priorité → copie en local → sinon local
class QuranUserDataService {
  QuranUserDataService({this._auth, this._db});

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  static const _lastKey = 'quran_last_reading';
  static const _favKey = 'quran_favorites';

  bool get _useFirebase {
    if (!firebaseReady) return false;
    return (_auth ?? FirebaseAuth.instance).currentUser != null;
  }

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get db => _db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _quranDoc {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur Firebase non connecté');
    }
    return db.collection(FirestorePaths.quranData).doc(uid);
  }

  DocumentReference<Map<String, dynamic>> get _legacyUserDoc {
    return db.collection(FirestorePaths.users).doc(auth.currentUser!.uid);
  }

  /// Local vs cloud : garde la plus récente (évite d’écraser le progrès).
  Future<LastReading?> getLastReading() async {
    final local = await _localLastReading();
    if (!_useFirebase) return local;

    try {
      final cloud = await _readCloudLastReading();
      final best = LastReading.newer(local, cloud);
      if (best == null) return null;
      await _saveLocalLast(best);
      return best;
    } catch (_) {
      return local;
    }
  }

  /// Local + Firestore (si connecté).
  Future<void> saveLastReading(LastReading reading) async {
    final stamped = LastReading(
      surah: reading.surah,
      ayah: reading.ayah,
      surahLatin: reading.surahLatin,
      surahArabic: reading.surahArabic,
      label: reading.label,
      updatedAt: reading.updatedAt ?? DateTime.now(),
    );
    await _saveLocalLast(stamped);
    if (!_useFirebase) return;
    try {
      await _quranDoc.set({
        'lastReading': stamped.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      await _markPending();
    }
  }

  /// Firestore d’abord → copie locale. Sinon local.
  Future<List<FavoriteItem>> getFavorites() async {
    if (_useFirebase) {
      try {
        final fromCloud = await _readCloudFavorites();
        if (fromCloud != null) {
          await _saveLocalFavorites(fromCloud);
          return fromCloud;
        }
      } catch (_) {}
    }
    return _localFavorites();
  }

  /// Local + Firestore (si connecté).
  Future<void> toggleFavorite(FavoriteItem item) async {
    // Base locale (déjà hydratée depuis Firestore au chargement).
    final current = await _localFavorites();
    final exists = current.any((f) => f.id == item.id);
    final next = exists
        ? current.where((f) => f.id != item.id).toList()
        : [...current, item];

    await _saveLocalFavorites(next);
    if (!_useFirebase) return;
    try {
      await _quranDoc.set({
        'favorites': [for (final f in next) f.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      await _markPending();
    }
  }

  /// Pousse la dernière lecture + favoris locaux vers le cloud.
  Future<void> pushLocalToCloud() async {
    if (!_useFirebase) return;
    try {
      final last = await _localLastReading();
      final favs = await _localFavorites();
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (last != null) data['lastReading'] = last.toMap();
      data['favorites'] = [for (final f in favs) f.toMap()];
      await _quranDoc.set(data, SetOptions(merge: true));
    } catch (_) {
      await _markPending();
      rethrow;
    }
  }

  Future<void> _markPending() => UserDataSyncService.markPending();

  Future<LastReading?> _readCloudLastReading() async {
    try {
      final snap = await _quranDoc.get();
      final data = snap.data();
      if (data != null && data['lastReading'] != null) {
        return LastReading.fromMap(
          Map<String, dynamic>.from(data['lastReading'] as Map),
        );
      }

      final legacy = await _legacyUserDoc.get();
      final legacyReading = legacy.data()?['lastReading'];
      if (legacyReading == null) return null;

      final reading = LastReading.fromMap(
        Map<String, dynamic>.from(legacyReading as Map),
      );
      await _quranDoc.set({
        'lastReading': reading.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return reading;
    } catch (_) {
      return null;
    }
  }

  /// `null` = pas de doc cloud ; liste vide = doc sans favoris.
  Future<List<FavoriteItem>?> _readCloudFavorites() async {
    final snap = await _quranDoc.get();
    final data = snap.data();
    if (data != null && data.containsKey('favorites')) {
      final raw = data['favorites'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          FavoriteItem.fromMap(Map<String, dynamic>.from(item as Map)),
      ];
    }

    final legacy = await _legacyUserDoc.get();
    final raw = legacy.data()?['favorites'] as List<dynamic>?;
    if (raw == null) return null;

    final items = [
      for (final item in raw)
        FavoriteItem.fromMap(Map<String, dynamic>.from(item as Map)),
    ];
    await _quranDoc.set({
      'favorites': [for (final f in items) f.toMap()],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return items;
  }

  Future<LastReading?> _localLastReading() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LastReading.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalLast(LastReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, jsonEncode(reading.toMap()));
  }

  Future<List<FavoriteItem>> _localFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        FavoriteItem.fromMap(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _saveLocalFavorites(List<FavoriteItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _favKey,
      jsonEncode([for (final f in items) f.toMap()]),
    );
  }
}
