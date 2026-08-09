import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Messages d’erreur Firebase Auth en français.
abstract final class AuthErrorMapper {
  static String message(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Adresse e-mail invalide.',
      'user-disabled' => 'Ce compte a été désactivé.',
      'user-not-found' => 'Aucun compte avec cet e-mail.',
      'wrong-password' => 'Mot de passe incorrect.',
      'email-already-in-use' => 'Cet e-mail est déjà utilisé.',
      'weak-password' => 'Mot de passe trop faible (min. 6 caractères).',
      'invalid-credential' => 'Identifiants incorrects.',
      'too-many-requests' => 'Trop de tentatives. Réessaie plus tard.',
      'network-request-failed' => 'Connexion impossible. Vérifie le réseau.',
      'operation-not-allowed' => 'Méthode de connexion non activée dans Firebase.',
      'account-exists-with-different-credential' =>
        'Un compte existe déjà avec une autre méthode de connexion.',
      'requires-recent-login' => 'Reconnecte-toi pour continuer.',
      'email-not-verified' =>
          'Vérifie ton e-mail avant de te connecter. Un nouveau lien a été envoyé.',
      'google-sign-in-cancelled' => 'Connexion Google annulée.',
      'invalid-display-name' => 'Nom invalide (1 à 40 caractères).',
      'password-not-available' =>
          'Ce compte utilise Google. Change le mot de passe dans ton compte Google.',
      _ => 'Erreur d’authentification (${e.code}).',
    };
  }

  static String fromAny(Object error) {
    if (error is FirebaseAuthException) return message(error);
    if (error is PlatformException) {
      if (error.code == 'network-request-failed' ||
          error.message?.contains('network') == true ||
          error.message?.contains('timeout') == true) {
        return 'Connexion impossible. Vérifie le réseau.';
      }
      return error.message ?? 'Erreur réseau. Réessaie.';
    }
    return 'Connexion impossible. Réessaie.';
  }
}
