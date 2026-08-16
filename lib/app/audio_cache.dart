import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../features/quran/data/models/quran_models.dart';

/// Cache MP3 local (EveryAyah / URLs API) pour écoute hors ligne.
abstract final class OfflineAudioCache {
  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/audio_cache_v1');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _fileName(String url) {
    final last = url.split('/').last.split('?').first;
    if (last.toLowerCase().endsWith('.mp3') && last.length < 80) {
      return last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    }
    return '${url.hashCode.toUnsigned(32).toRadixString(16)}.mp3';
  }

  static Future<File> _file(String url) async =>
      File('${(await _dir()).path}/${_fileName(url)}');

  static Future<bool> has(String url) async {
    try {
      final f = await _file(url);
      return await f.exists() && await f.length() > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasAyah(int surah, int ayah) =>
      has(everyAyahAudioUrl(surah, ayah));

  /// Chemin local si déjà téléchargé.
  static Future<String?> pathIfCached(String url) async {
    try {
      final f = await _file(url);
      if (await f.exists() && await f.length() > 0) return f.path;
    } catch (_) {}
    return null;
  }

  /// Télécharge si besoin. Retourne le chemin local ou null.
  static Future<String?> ensure(String url) async {
    final existing = await pathIfCached(url);
    if (existing != null) return existing;
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      final f = await _file(url);
      await f.writeAsBytes(res.bodyBytes, flush: true);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> ensureAyah(int surah, int ayah) =>
      ensure(everyAyahAudioUrl(surah, ayah));

  /// Source lecture : fichier local si dispo, sinon URL (+ cache en fond).
  static Future<Source> sourceFor(String url) async {
    final local = await pathIfCached(url);
    if (local != null) return DeviceFileSource(local);
    unawaited(ensure(url));
    return UrlSource(url);
  }

  /// Prefetch tous les ayahs d’une sourate (EveryAyah).
  static Future<void> prefetchSurah(
    int surah,
    int ayahCount, {
    FutureOr<bool> Function()? shouldContinue,
  }) async {
    for (var a = 1; a <= ayahCount; a++) {
      if (shouldContinue != null && !await shouldContinue()) return;
      if (await hasAyah(surah, a)) continue;
      await ensureAyah(surah, a);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }
}
