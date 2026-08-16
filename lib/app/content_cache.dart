import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Cache JSON local (fichiers) pour lecture hors ligne.
abstract final class ContentCache {
  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/content_cache_v2');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _fileName(String key) =>
      '${key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.json';

  static Future<File> _file(String key) async =>
      File('${(await _dir()).path}/${_fileName(key)}');

  static Future<void> put(String key, Map<String, dynamic> json) async {
    try {
      await (await _file(key)).writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> has(String key) async {
    try {
      return await (await _file(key)).exists();
    } catch (_) {
      return false;
    }
  }
}
