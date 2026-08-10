import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../../../app/l10n/app_strings.dart';

/// Messages d’erreur Firebase Auth selon la langue de l’app.
abstract final class AuthErrorMapper {
  static String message(FirebaseAuthException e) {
    final key = 'auth_${e.code.replaceAll('-', '_')}';
    final mapped = S.get(key);
    if (mapped != key) return mapped;
    return S.get('auth_unknown').replaceAll('{code}', e.code);
  }

  static String fromAny(Object error) {
    if (error is FirebaseAuthException) return message(error);
    if (error is PlatformException) {
      final msg = (error.message ?? '').toLowerCase();
      if (msg.contains('unable to resolve') ||
          msg.contains('network') ||
          msg.contains('hostname') ||
          msg.contains('socket') ||
          msg.contains('reauth failed') ||
          msg.contains('[16]') ||
          (error.code.toUpperCase() == 'UNKNOWN' &&
              msg.contains('internal error'))) {
        if (msg.contains('reauth') || msg.contains('[16]')) {
          return S.get('auth_google_config_missing');
        }
        return S.get('auth_network_request_failed');
      }
      final code = _normalizePlatformCode(error.code);
      final asFirebase = FirebaseAuthException(
        code: code,
        message: error.message,
      );
      final mapped = message(asFirebase);
      if (mapped.contains(code) && error.message != null) {
        final lower = error.message!.toLowerCase();
        if (lower.contains('credential') ||
            lower.contains('password') ||
            lower.contains('malformed') ||
            lower.contains('expired')) {
          return S.get('auth_invalid_credential');
        }
      }
      return mapped;
    }
    return S.get('auth_generic');
  }

  static String _normalizePlatformCode(String code) {
    final c = code.trim();
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
      _ => c.startsWith('ERROR_')
          ? c.substring(6).replaceAll('_', '-').toLowerCase()
          : c.replaceAll('_', '-').toLowerCase(),
    };
  }
}
