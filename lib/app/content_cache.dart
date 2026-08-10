import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache JSON local pour lecture hors ligne (Coran / Douas / Hadiths).
abstract final class ContentCache {
  static const _indexKey = 'content_cache_index_v1';
  static const _maxEntries = 40;

  static Future<void> put(String key, Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(key), jsonEncode(json));
      await _touchIndex(prefs, key);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(key));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static String _prefKey(String key) => 'content_cache_v1_$key';

  static Future<void> _touchIndex(SharedPreferences prefs, String key) async {
    final index = prefs.getStringList(_indexKey) ?? <String>[];
    index.remove(key);
    index.add(key);
    while (index.length > _maxEntries) {
      final oldest = index.removeAt(0);
      await prefs.remove(_prefKey(oldest));
    }
    await prefs.setStringList(_indexKey, index);
  }
}
