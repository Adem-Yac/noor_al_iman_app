import 'package:flutter/material.dart';

import 'dua_models.dart';

/// Les 4 catégories principales affichées sur la page Douas.
abstract final class DuaMainCategories {
  static const otherId = 'other';
  static const ids = ['morning', 'evening', 'travel', otherId];

  /// Nombre de douas affichées (null = toutes).
  static const Map<String, int?> displayLimits = {
    'morning': 7,
    'evening': 5,
    'travel': 6,
    otherId: null,
  };

  static int? displayLimit(String id) => displayLimits[id];

  static bool isOther(String id) => id == otherId;

  static const _meta = {
    'morning': (
      fr: 'Matin',
      ar: 'الصباح',
      icon: Icons.wb_sunny_outlined,
    ),
    'evening': (
      fr: 'Soir',
      ar: 'المساء',
      icon: Icons.nightlight_round,
    ),
    'travel': (
      fr: 'Voyage',
      ar: 'السفر',
      icon: Icons.flight_outlined,
    ),
    otherId: (
      fr: 'Autre',
      ar: 'أخرى',
      icon: Icons.apps_outlined,
    ),
  };

  static List<DuaCategory> resolve(
    List<DuaCategory> fromApi, {
    int totalDuas = 0,
  }) {
    return [
      for (final id in ids) _resolveOne(id, fromApi, totalDuas: totalDuas),
    ];
  }

  static DuaCategory _resolveOne(
    String id,
    List<DuaCategory> fromApi, {
    required int totalDuas,
  }) {
    if (isOther(id)) {
      final meta = _meta[id]!;
      return DuaCategory(
        id: id,
        name: meta.fr,
        description: 'Toutes les invocations',
        count: totalDuas,
      );
    }

    final limit = displayLimit(id);
    final match = fromApi.where((c) => c.id == id);
    if (match.isNotEmpty) {
      final c = match.first;
      final count = limit == null
          ? c.count
          : (c.count > 0 && c.count < limit ? c.count : limit);
      return DuaCategory(
        id: c.id,
        name: c.name,
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

  static String arabicLabel(String id) => _meta[id]?.ar ?? id;

  static IconData icon(String id) {
    if (_meta.containsKey(id)) return _meta[id]!.icon;
    return switch (id) {
      'protection' => Icons.shield_outlined,
      'sleep' => Icons.bedtime_outlined,
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
