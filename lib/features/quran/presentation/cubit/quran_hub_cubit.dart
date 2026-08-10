import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/quran_models.dart';
import '../../data/repositories/quran_repository.dart';

class QuranHubCubit extends Cubit<QuranHubState> {
  QuranHubCubit(this._repo) : super(const QuranHubState()) {
    load();
  }

  final QuranRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final last = await _repo.lastReading();
      final favs = await _repo.favorites();
      emit(
        state.copyWith(
          loading: false,
          lastReading: last,
          favorites: favs,
          clearLastIfNull: last == null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> toggleSurahFavorite({
    required int surah,
    required String latin,
    required String arabic,
  }) async {
    final item = FavoriteItem(
      id: FavoriteItem.surahId(surah),
      type: 'surah',
      surah: surah,
      surahLatin: latin,
      surahArabic: arabic,
    );
    await _repo.toggleFavorite(item);
    await load();
  }
}

class QuranHubState {
  const QuranHubState({
    this.loading = false,
    this.lastReading,
    this.favorites = const [],
    this.error,
  });

  final bool loading;
  final LastReading? lastReading;
  final List<FavoriteItem> favorites;
  final String? error;

  QuranHubState copyWith({
    bool? loading,
    LastReading? lastReading,
    List<FavoriteItem>? favorites,
    String? error,
    bool clearError = false,
    bool clearLastIfNull = false,
  }) {
    return QuranHubState(
      loading: loading ?? this.loading,
      lastReading: clearLastIfNull
          ? lastReading
          : (lastReading ?? this.lastReading),
      favorites: favorites ?? this.favorites,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
