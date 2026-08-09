import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'user_repository.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']),
       _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) return;

    await user.updateDisplayName(displayName.trim());
    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('sendEmailVerification: $e');
    }
    await _userRepository.createOrUpdateProfile(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      providers: ['password'],
      emailVerified: false,
    );
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    try {
      await user.reload();
    } catch (_) {}
    final refreshed = _auth.currentUser ?? user;
    if (!refreshed.emailVerified) {
      try {
        await refreshed.sendEmailVerification();
      } catch (_) {}
      await _auth.signOut();
      throw FirebaseAuthException(code: 'email-not-verified');
    }

    await _userRepository.syncFromAuthUser(refreshed);
    return refreshed;
  }

  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'google-sign-in-cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    await _userRepository.syncFromAuthUser(user);
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<User> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final name = displayName.trim();
    if (name.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-display-name');
    }
    if (name.length > 40) {
      throw FirebaseAuthException(code: 'invalid-display-name');
    }
    await user.updateDisplayName(name);
    try {
      await user.reload();
    } catch (_) {}
    final refreshed = _auth.currentUser ?? user;
    await _userRepository.createOrUpdateProfile(
      uid: refreshed.uid,
      email: refreshed.email ?? '',
      displayName: name,
      photoUrl: refreshed.photoURL,
      providers: refreshed.providerData.map((p) => p.providerId).toList(),
      emailVerified: refreshed.emailVerified,
    );
    return refreshed;
  }

  /// Change le mot de passe (compte e-mail uniquement).
  /// Nécessite le mot de passe actuel (ré-auth Firebase).
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(code: 'operation-not-allowed');
    }
    final hasPassword = user.providerData.any((p) => p.providerId == 'password');
    if (!hasPassword) {
      throw FirebaseAuthException(code: 'password-not-available');
    }
    if (newPassword.length < 6) {
      throw FirebaseAuthException(code: 'weak-password');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  bool hasPasswordProvider(User user) =>
      user.providerData.any((p) => p.providerId == 'password');

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
