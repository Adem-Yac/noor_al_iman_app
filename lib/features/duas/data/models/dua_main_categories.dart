import 'package:flutter/material.dart';

import 'dua_models.dart';

/// Catégories principales affichées sur la page Douas.
abstract final class DuaMainCategories {
  static const otherId = 'other';
  static const wakeId = 'wake';

  /// Douas « au réveil » (API catégorie `sleep`).
  static const wakeDuaIds = {15, 63};

  static const ids = [
    'morning',
    'evening',
    'sleep',
    wakeId,
    'travel',
    otherId,
  ];

  /// Nombre de douas affichées (null = toutes).
  static const Map<String, int?> displayLimits = {
    'morning': 7,
    'evening': 5,
    'sleep': 6,
    wakeId: null,
    'travel': 6,
    otherId: null,
  };

  static int? displayLimit(String id) => displayLimits[id];

  static bool isOther(String id) => id == otherId;

  static bool isWake(String id) => id == wakeId;

  static bool isSleepBedtime(Dua dua) =>
      dua.category == 'sleep' && !wakeDuaIds.contains(dua.id);

  static bool isWakeDua(Dua dua) => wakeDuaIds.contains(dua.id);

  static const _meta = {
    'morning': (
      fr: 'Matin',
      en: 'Morning',
      ar: 'الصباح',
      icon: Icons.wb_sunny_outlined,
    ),
    'evening': (
      fr: 'Soir',
      en: 'Evening',
      ar: 'المساء',
      icon: Icons.nightlight_round,
    ),
    'sleep': (
      fr: 'Sommeil',
      en: 'Sleep',
      ar: 'النوم',
      icon: Icons.bedtime_outlined,
    ),
    wakeId: (
      fr: 'Réveil',
      en: 'Wake',
      ar: 'الاستيقاظ',
      icon: Icons.wb_twilight_outlined,
    ),
    'travel': (
      fr: 'Voyage',
      en: 'Travel',
      ar: 'السفر',
      icon: Icons.flight_outlined,
    ),
    otherId: (
      fr: 'Autre',
      en: 'Other',
      ar: 'أخرى',
      icon: Icons.apps_outlined,
    ),
  };

  static List<DuaCategory> resolve(
    List<DuaCategory> fromApi, {
    int totalDuas = 0,
    List<Dua> duas = const [],
  }) {
    return [
      for (final id in ids)
        _resolveOne(id, fromApi, totalDuas: totalDuas, duas: duas),
    ];
  }

  static DuaCategory _resolveOne(
    String id,
    List<DuaCategory> fromApi, {
    required int totalDuas,
    List<Dua> duas = const [],
  }) {
    if (isOther(id)) {
      final meta = _meta[id]!;
      return DuaCategory(
        id: id,
        name: meta.fr,
        description: '',
        count: totalDuas,
      );
    }

    if (isWake(id)) {
      final meta = _meta[id]!;
      final count = duas.isEmpty
          ? wakeDuaIds.length
          : duas.where(isWakeDua).length;
      return DuaCategory(
        id: id,
        name: meta.fr,
        description: '',
        count: count == 0 ? wakeDuaIds.length : count,
      );
    }

    final limit = displayLimit(id);
    final match = fromApi.where((c) => c.id == id);
    if (match.isNotEmpty) {
      final c = match.first;
      var count = c.count;
      if (id == 'sleep' && duas.isNotEmpty) {
        count = duas.where(isSleepBedtime).length;
      }
      if (limit != null) {
        count = count > 0 && count < limit ? count : limit;
      }
      final meta = _meta[id];
      return DuaCategory(
        id: c.id,
        name: meta?.fr ?? c.name,
        description: c.description,
        count: count,
      );
    }

    final meta = _meta[id]!;
    return DuaCategory(
      id: id,
      name: meta.fr,
      description: '',
      count: limit ?? 0,
    );
  }

  static String frenchLabel(String id) => _meta[id]?.fr ?? id;

  static String englishLabel(String id) => _meta[id]?.en ?? id;

  static String arabicLabel(String id) => _meta[id]?.ar ?? id;

  static IconData icon(String id) {
    if (_meta.containsKey(id)) return _meta[id]!.icon;
    return switch (id) {
      'protection' => Icons.shield_outlined,
      'food' => Icons.restaurant_outlined,
      'prayer' || 'after_prayer' => Icons.mosque_outlined,
      'wudu' => Icons.water_drop_outlined,
      'home' => Icons.home_outlined,
      'masjid' => Icons.account_balance_outlined,
      'forgiveness' => Icons.favorite_outline,
      'gratitude' => Icons.volunteer_activism_outlined,
      'distress' => Icons.spa_outlined,
      _ => Icons.menu_book_outlined,
    };
  }

  static bool isMain(String id) => ids.contains(id);
}
