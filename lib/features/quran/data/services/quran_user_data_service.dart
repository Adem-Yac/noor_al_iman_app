import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../models/quran_models.dart';

class QuranUserDataService {
  QuranUserDataService({this._auth, this._db});

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  static const _lastKey = 'quran_last_reading';
  static const _favKey = 'quran_favorites';

  bool get _useFirebase =>
      firebaseReady && (_auth ?? FirebaseAuth.instance).currentUser != null;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get db => _db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur Firebase non connecté');
    }
    return db.collection('users').doc(uid);
  }

  Future<void> ensureSignedIn() async {
    if (!firebaseReady) return;
    try {
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (_) {
      // keep local fallback
    }
  }

  Future<LastReading?> getLastReading() async {
    await ensureSignedIn();
    if (_useFirebase) {
      try {
        final snap = await _userDoc.get();
        final data = snap.data();
        if (data != null && data['lastReading'] != null) {
          return LastReading.fromMap(
            Map<String, dynamic>.from(data['lastReading'] as Map),
          );
        }
      } catch (_) {}
    }
    return _localLastReading();
  }

  Future<void> saveLastReading(LastReading reading) async {
    await _saveLocalLast(reading);
    await ensureSignedIn();
    if (!_useFirebase) return;
    try {
      await _userDoc.set({
        'lastReading': reading.toMap(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<FavoriteItem>> getFavorites() async {
    await ensureSignedIn();
    if (_useFirebase) {
      try {
        final snap = await _userDoc.get();
        final data = snap.data();
        final raw = data?['favorites'] as List<dynamic>? ?? const [];
        return [
          for (final item in raw)
            FavoriteItem.fromMap(Map<String, dynamic>.from(item as Map)),
        ];
      } catch (_) {}
    }
    return _localFavorites();
  }

  Future<void> toggleFavorite(FavoriteItem item) async {
    final current = await getFavorites();
    final exists = current.any((f) => f.id == item.id);
    final next = exists
        ? current.where((f) => f.id != item.id).toList()
        : [...current, item];
    await _saveLocalFavorites(next);
    await ensureSignedIn();
    if (!_useFirebase) return;
    try {
      await _userDoc.set({
        'favorites': [for (final f in next) f.toMap()],
      }, SetOptions(merge: true));
    } catch (_) {}
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
