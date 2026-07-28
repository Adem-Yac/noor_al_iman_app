import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/firebase_bootstrap.dart';
import '../../../home/data/models/home_data.dart';

/// Données utilisateur persistées dans Firestore (`users/{uid}`).
class UserRepository {
  UserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

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

    final ref = _doc(uid);
    final exists = (await ref.get()).exists;
    if (!exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
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
    final uid = _auth.currentUser!.uid;
    await _doc(uid).set({
      'location': {
        'label': location.label,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'fromGps': location.fromGps,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserLocation?> loadCloudLocation() async {
    if (!_canUseCloud) return null;
    final uid = _auth.currentUser!.uid;
    final snap = await _doc(uid).get();
    final loc = snap.data()?['location'] as Map<String, dynamic>?;
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
