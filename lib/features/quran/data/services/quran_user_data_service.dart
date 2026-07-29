import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
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

  /// Firestore d’abord → copie locale. Sinon local.
  Future<LastReading?> getLastReading() async {
    if (_useFirebase) {
      try {
        final fromCloud = await _readCloudLastReading();
        if (fromCloud != null) {
          await _saveLocalLast(fromCloud);
          return fromCloud;
        }
      } catch (_) {}
    }
    return _localLastReading();
  }

  /// Local + Firestore (si connecté).
  Future<void> saveLastReading(LastReading reading) async {
    await _saveLocalLast(reading);
    if (!_useFirebase) return;
    try {
      await _quranDoc.set({
        'lastReading': reading.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<LastReading?> _readCloudLastReading() async {
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
    // Migre vers la nouvelle collection.
    await _quranDoc.set({
      'lastReading': reading.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return reading;
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null) return null;
    return LastReading.fromMap(jsonDecode(raw) as Map<String, dynamic>);
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
