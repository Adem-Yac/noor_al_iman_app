import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
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

  Future<void> _onAuthChanged(User? user) async {
    if (state is AuthLoading) return;

    if (user == null) {
      if (state is! AuthUnauthenticated) {
        emit(const AuthUnauthenticated());
      }
      return;
    }

    try {
      await user.reload();
    } catch (_) {}

    final refreshed = _repository.currentUser;
    if (refreshed == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    emit(AuthAuthenticated(refreshed));
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
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(AuthErrorMapper.message(e)));
    } catch (_) {
      emit(const AuthFailure('Connexion impossible. Réessaie.'));
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
        const AuthUnauthenticated(
          message: 'Compte créé. Tu peux te connecter.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(AuthErrorMapper.message(e)));
    } catch (_) {
      emit(const AuthFailure('Inscription impossible. Réessaie.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') {
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthFailure(AuthErrorMapper.message(e)));
    } catch (_) {
      emit(const AuthFailure('Connexion Google impossible.'));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final previous = state;
    emit(const AuthLoading());
    try {
      await _repository.sendPasswordResetEmail(email);
      if (previous is AuthAuthenticated) {
        emit(previous);
      } else {
        emit(
          const AuthUnauthenticated(
            message: 'E-mail de réinitialisation envoyé.',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(AuthErrorMapper.message(e)));
    } catch (_) {
      emit(const AuthFailure('Impossible d’envoyer l’e-mail.'));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
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
