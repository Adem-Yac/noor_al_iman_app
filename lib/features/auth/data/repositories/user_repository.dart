import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../../app/firestore_paths.dart';
import '../../../home/data/models/home_data.dart';

/// Profil + localisation Firestore (échecs réseau ignorés).
class UserRepository {
  UserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  DocumentReference<Map<String, dynamic>> _locationDoc(String uid) =>
      _firestore.collection(FirestorePaths.userLocations).doc(uid);

  bool get _canUseCloud => firebaseReady && _auth.currentUser != null;

  Future<void> createOrUpdateProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    List<String>? providers,
    bool? emailVerified,
  }) async {
    if (!firebaseReady) return;

    try {
      final data = <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (providers != null) {
        data['providers'] = providers;
      }
      if (emailVerified != null) {
        data['emailVerified'] = emailVerified;
      }

      final ref = _userDoc(uid);
      final exists = (await ref.get()).exists;
      if (!exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await ref.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserRepository.createOrUpdateProfile: $e');
    }
  }

  Future<void> syncFromAuthUser(User user) async {
    await createOrUpdateProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providers: user.providerData.map((p) => p.providerId).toList(),
      emailVerified: user.emailVerified,
    );
  }

  Future<void> syncLocation(UserLocation location) async {
    if (!_canUseCloud) return;
    try {
      final uid = _auth.currentUser!.uid;
      await _locationDoc(uid).set({
        'label': location.label,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'fromGps': location.fromGps,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserRepository.syncLocation: $e');
    }
  }

  Future<UserLocation?> loadCloudLocation() async {
    if (!_canUseCloud) return null;
    try {
      final uid = _auth.currentUser!.uid;

      final snap = await _locationDoc(uid).get();
      if (snap.exists) {
        return _parseLocation(snap.data());
      }

      // Migration depuis l’ancien schéma users/{uid}.location
      final legacy = await _userDoc(uid).get();
      final loc = legacy.data()?['location'] as Map<String, dynamic>?;
      final parsed = _parseLocation(loc);
      if (parsed != null) {
        await syncLocation(parsed);
      }
      return parsed;
    } catch (e) {
      debugPrint('UserRepository.loadCloudLocation: $e');
      return null;
    }
  }

  UserLocation? _parseLocation(Map<String, dynamic>? loc) {
    if (loc == null) return null;
    final lat = loc['latitude'] as num?;
    final lng = loc['longitude'] as num?;
    final label = loc['label'] as String?;
    if (lat == null || lng == null || label == null) return null;
    return UserLocation(
      label: label,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      fromGps: loc['fromGps'] as bool? ?? true,
    );
  }
}
