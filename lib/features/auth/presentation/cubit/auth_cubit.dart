import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/user_data_sync_service.dart';
import '../../../home/data/services/location_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_error_mapper.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _subscription;

  void _onAuthChanged(User? user) {
    // Pendant un login/signup, le cubit gère l’état lui-même.
    if (state is AuthLoading) return;

    if (user == null) {
      // Ne pas effacer un message d’erreur / succès affiché.
      if (state is AuthUnauthenticated &&
          (state as AuthUnauthenticated).message != null) {
        return;
      }
      emit(const AuthUnauthenticated());
      return;
    }

    // Pas de user.reload() ici : plante souvent hors-ligne / Play Services.
    emit(AuthAuthenticated(user));
    unawaited(UserDataSyncService.syncAll());
    unawaited(_ensureUserLocation());
  }

  /// Après inscription / connexion : demande la localisation automatiquement.
  Future<void> _ensureUserLocation() async {
    try {
      final location = await LocationService().requestAndSave();
      await UserRepository().syncLocation(location);
    } catch (_) {
      // L’accueil redemandera via HomeCubit / bouton refresh.
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      unawaited(UserDataSyncService.syncAll());
      unawaited(_ensureUserLocation());
    } catch (e) {
      // AuthUnauthenticated + message : le formulaire reste utilisable.
      emit(AuthUnauthenticated(message: AuthErrorMapper.fromAny(e)));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      emit(
        AuthUnauthenticated(message: S.get('auth_signup_verify')),
      );
    } catch (e) {
      emit(AuthUnauthenticated(message: AuthErrorMapper.fromAny(e)));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
      unawaited(UserDataSyncService.syncAll());
      unawaited(_ensureUserLocation());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') {
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthUnauthenticated(message: AuthErrorMapper.message(e)));
    } catch (e) {
      emit(AuthUnauthenticated(message: AuthErrorMapper.fromAny(e)));
    }
  }

  /// Reset MDP : hors session → change l’état auth ; en session → bool seulement.
  Future<bool> sendPasswordReset(String email) async {
    final inSession = state is AuthAuthenticated;
    if (!inSession) emit(const AuthLoading());
    try {
      await _repository.sendPasswordResetEmail(email);
      if (!inSession) {
        emit(AuthUnauthenticated(message: S.get('auth_reset_sent')));
      }
      return true;
    } catch (e) {
      if (!inSession) {
        emit(AuthUnauthenticated(message: AuthErrorMapper.fromAny(e)));
      }
      return false;
    }
  }

  /// Retourne `null` si OK, sinon le message d’erreur.
  Future<String?> updateDisplayName(String displayName) async {
    final previous = state;
    try {
      final user = await _repository.updateDisplayName(displayName);
      if (!isClosed) emit(AuthAuthenticated(user));
      return null;
    } catch (e) {
      if (!isClosed && previous is AuthAuthenticated) emit(previous);
      if (e is FirebaseAuthException) return AuthErrorMapper.message(e);
      return S.nameUpdateFailed;
    }
  }

  /// Retourne `null` si OK, sinon le message d’erreur.
  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) return AuthErrorMapper.message(e);
      return S.passwordUpdateFailed;
    }
  }

  bool hasPasswordProvider(User user) =>
      _repository.hasPasswordProvider(user);

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  void clearTransientMessage() {
    if (state is AuthUnauthenticated) {
      emit(const AuthUnauthenticated());
    }
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
