import 'dart:convert';

import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw UmmahApiException('Erreur API (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw const UmmahApiException('Réponse UmmahAPI invalide');
    }
    return json;
  }
}

class UmmahApiException implements Exception {
  const UmmahApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
