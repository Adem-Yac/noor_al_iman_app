import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// REST API UmmahAPI — même idée que `web_services` du cours (Session Cubit + RestAPI).
class UmmahApiService {
  UmmahApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://ummahapi.com/api';
  final http.Client _client;

  Future<Map<String, dynamic>> getPrayerTimes({
    required double latitude,
    required double longitude,
  }) {
    final uri = Uri.parse('$_baseUrl/prayer-times').replace(
      queryParameters: {
        'lat': '$latitude',
        'lng': '$longitude',
        'method': 'Algeria',
      },
    );
    return _get(uri);
  }

  Future<Map<String, dynamic>> getTodayHijri() {
    return _get(Uri.parse('$_baseUrl/today-hijri'));
  }

  Future<Map<String, dynamic>> getRandomVerse() {
    return _get(Uri.parse('$_baseUrl/quran/random'));
  }

  Future<Map<String, dynamic>> getAyah({
    required int surah,
    required int ayah,
  }) {
    return _get(Uri.parse('$_baseUrl/quran/surah/$surah/ayah/$ayah'));
  }

  Future<Map<String, dynamic>> getSurah(int number) {
    return _get(Uri.parse('$_baseUrl/quran/surah/$number'));
  }

  Future<Map<String, dynamic>> getHadithCollections() {
    return _get(Uri.parse('$_baseUrl/hadith/collections'));
  }

  Future<Map<String, dynamic>> getRandomHadith() {
    return _get(Uri.parse('$_baseUrl/hadith/random'));
  }

  Future<Map<String, dynamic>> getHadithCollection({
    required String collection,
    int page = 1,
    int limit = 20,
  }) {
    final uri = Uri.parse('$_baseUrl/hadith/$collection').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
      },
    );
    return _get(uri);
  }

  Future<Map<String, dynamic>> getDuas({String? category}) {
    final uri = Uri.parse('$_baseUrl/duas').replace(
      queryParameters: category == null ? null : {'category': category},
    );
    return _get(uri);
  }

  Future<Map<String, dynamic>> getTafsir({
    required String source,
    required int surah,
    required int ayah,
  }) {
    return _get(
      Uri.parse('$_baseUrl/tafsir/$source/surah/$surah/ayah/$ayah'),
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const UmmahApiException('Délai dépassé — réessaie plus tard');
    } on SocketException {
      throw const UmmahApiException('Pas de connexion Internet');
    } on http.ClientException {
      throw const UmmahApiException('Pas de connexion Internet');
    } on HandshakeException {
      throw const UmmahApiException('Connexion sécurisée impossible');
    } catch (_) {
      throw const UmmahApiException('Erreur réseau — réessaie plus tard');
    }

    if (response.statusCode != 200) {
      throw UmmahApiException('Erreur API (${response.statusCode})');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] != true) {
        throw const UmmahApiException('Réponse UmmahAPI invalide');
      }
      return json;
    } on UmmahApiException {
      rethrow;
    } catch (_) {
      throw const UmmahApiException('Réponse UmmahAPI invalide');
    }
  }
}

class UmmahApiException implements Exception {
  const UmmahApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
