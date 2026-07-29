import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../data/web_services/ummah_api_service.dart';
import '../models/quran_models.dart';

enum TafsirLanguage { french, english }

class TafsirEntry {
  const TafsirEntry({
    required this.text,
    required this.sourceName,
  });

  final String text;
  final String sourceName;
}

class TafsirRepository {
  TafsirRepository({UmmahApiService? api, http.Client? client})
    : _api = api ?? UmmahApiService(),
      _client = client ?? http.Client();

  final UmmahApiService _api;
  final http.Client _client;

  static const _frenchTafsirBase =
      'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/french-mokhtasar';

  Future<SurahContent> loadSurah(int number) async {
    return SurahContent.fromJson(await _api.getSurah(number));
  }

  Future<TafsirEntry> loadTafsir({
    required int surah,
    required int ayah,
    required TafsirLanguage language,
  }) async {
    if (language == TafsirLanguage.english) {
      final json = await _api.getTafsir(
        source: 'ibn_kathir',
        surah: surah,
        ayah: ayah,
      );
      final data = json['data'] as Map<String, dynamic>;
      final tafsir = data['tafsir'] as Map<String, dynamic>? ?? {};
      return TafsirEntry(
        text: tafsir['text'] as String? ?? '',
        sourceName: tafsir['name'] as String? ?? 'Ibn Kathir',
      );
    }

    final uri = Uri.parse('$_frenchTafsirBase/$surah/$ayah.json');
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw UmmahApiException('Tafsir FR indisponible (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return TafsirEntry(
      text: json['text'] as String? ?? '',
      sourceName: 'Mokhtasar (FR)',
    );
  }

  String verseTranslation(QuranAyah ayah, TafsirLanguage language) {
    if (language == TafsirLanguage.french) {
      return ayah.french;
    }
    return ayah.english ?? ayah.french;
  }
}
