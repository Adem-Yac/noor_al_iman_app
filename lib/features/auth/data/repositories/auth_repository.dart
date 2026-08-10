import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../app/google_auth_config.dart';
import '../../../home/data/services/location_service.dart';
import 'user_repository.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ??
           GoogleSignIn(
             scopes: const ['email', 'profile'],
             serverClientId: GoogleAuthConfig.serverClientId,
           ),
       _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: _normalizeAuthCode(e.code, e.message),
        message: e.message,
      );
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
        code: _normalizeAuthCode(e.code, e.message),
        message: e.message,
      );
    }
  }

  static String _normalizeAuthCode(String code, [String? message]) {
    final c = code.trim();
    final msg = (message ?? '').toLowerCase();

    if (msg.contains('unable to resolve') ||
        msg.contains('network') ||
        msg.contains('hostname') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        c == 'network_error') {
      return 'network-request-failed';
    }

    return switch (c) {
      'ERROR_INVALID_CREDENTIAL' || 'invalid-credential' =>
        'invalid-credential',
      'ERROR_WRONG_PASSWORD' || 'wrong-password' => 'wrong-password',
      'ERROR_USER_NOT_FOUND' || 'user-not-found' => 'user-not-found',
      'ERROR_INVALID_EMAIL' || 'invalid-email' => 'invalid-email',
      'ERROR_USER_DISABLED' || 'user-disabled' => 'user-disabled',
      'ERROR_TOO_MANY_REQUESTS' || 'too-many-requests' => 'too-many-requests',
      'ERROR_NETWORK_REQUEST_FAILED' || 'network-request-failed' =>
        'network-request-failed',
      'ERROR_EMAIL_ALREADY_IN_USE' || 'email-already-in-use' =>
        'email-already-in-use',
      'ERROR_WEAK_PASSWORD' || 'weak-password' => 'weak-password',
      'ERROR_OPERATION_NOT_ALLOWED' || 'operation-not-allowed' =>
        'operation-not-allowed',
      'ERROR_REQUIRES_RECENT_LOGIN' || 'requires-recent-login' =>
        'requires-recent-login',
      'ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL' ||
      'account-exists-with-different-credential' =>
        'account-exists-with-different-credential',
      'google-config-missing' || 'ERROR_GOOGLE_CONFIG_MISSING' =>
        'google-config-missing',
      'google-signin-failed' || 'ERROR_GOOGLE_SIGNIN_FAILED' =>
        'google-signin-failed',
      'UNKNOWN' || 'unknown' =>
        msg.contains('internal error')
            ? 'network-request-failed'
            : 'google-signin-failed',
      _ => c.startsWith('ERROR_')
          ? c.substring(6).replaceAll('_', '-').toLowerCase()
          : c.replaceAll('_', '-').toLowerCase(),
    };
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _guard(() async {
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

      // Demande la localisation dès l’inscription (avant signOut vérification e-mail).
      try {
        final location = await LocationService().requestAndSave();
        await _userRepository.syncLocation(location);
      } catch (e) {
        debugPrint('signUp location: $e');
      }

      await signOut();
    });
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
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
    });
  }

  /// Google → Firebase (google_sign_in 6.x + signInWithCredential).
  Future<User> signInWithGoogle() async {
    return _guard(() async {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        final code = e.code.toLowerCase();
        final msg = (e.message ?? '').toLowerCase();
        if (code == 'sign_in_canceled' || code.contains('cancel')) {
          throw FirebaseAuthException(code: 'google-sign-in-cancelled');
        }
        if (code.contains('sign_in_failed') ||
            msg.contains('10:') ||
            msg.contains('developer_error') ||
            msg.contains('12500') ||
            msg.contains('reauth failed') ||
            msg.contains('[16]')) {
          throw FirebaseAuthException(code: 'google-config-missing');
        }
        rethrow;
      }

      if (googleUser == null) {
        throw FirebaseAuthException(code: 'google-sign-in-cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'google-config-missing');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'google-signin-failed');
      }

      await _userRepository.createOrUpdateProfile(
        uid: user.uid,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        providers: user.providerData.map((p) => p.providerId).toList(),
        emailVerified: true,
      );
      return user;
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _guard(
      () => _auth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  Future<User> updateDisplayName(String displayName) async {
    return _guard(() async {
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
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _guard(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }
      final email = user.email?.trim();
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(code: 'operation-not-allowed');
      }
      final hasPassword =
          user.providerData.any((p) => p.providerId == 'password');
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
    });
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
