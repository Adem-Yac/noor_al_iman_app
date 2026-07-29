import 'package:firebase_auth/firebase_auth.dart';
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
    await user.sendEmailVerification();
    await _userRepository.createOrUpdateProfile(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      providers: ['password'],
      emailVerified: false,
    );
    await _auth.signOut();
    await _googleSignIn.signOut();
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

    await user.reload();
    final refreshed = _auth.currentUser!;
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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
