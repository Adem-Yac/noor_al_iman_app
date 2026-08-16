import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/audio_cache.dart';
import '../../data/models/quran_models.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/surahs.dart';

class SurahTarget {
  const SurahTarget(this.number, {this.initialAyah = 1});
  final int number;
  final int initialAyah;
}

class QuranReaderCubit extends Cubit<QuranReaderState> {
  QuranReaderCubit(this._repo, {AudioPlayer? player})
    : _player = player ?? AudioPlayer(),
      super(const QuranReaderLoading()) {
    _player.onPlayerComplete.listen((_) => _onAudioComplete());
  }

  final QuranRepository _repo;
  final AudioPlayer _player;
  bool _autoPlayNext = false;

  /// Invalide toute lecture en cours (évite « Stream closed before it got prepared »).
  int _audioGen = 0;

  Future<void> load(SurahTarget target) async {
    emit(const QuranReaderLoading());
    try {
      final surah = await _repo.loadSurah(target.number);
      final favs = await _repo.favorites();
      final index = (target.initialAyah - 1).clamp(0, surah.ayahs.length - 1);
      emit(
        QuranReaderReady(
          title: surah.nameEnglish,
          subtitle: surah.nameArabic,
          surahNumber: surah.number,
          ayahs: surah.ayahs,
          currentIndex: index,
          favoriteIds: {for (final f in favs) f.id},
          surahAudioUrl: surah.surahAudioUrl,
        ),
      );
      await _persistProgress(surah.ayahs[index]);
      // Cache audio de la sourate ouverte (écoute hors ligne ensuite).
      unawaited(
        OfflineAudioCache.prefetchSurah(surah.number, surah.ayahs.length),
      );
      if (surah.surahAudioUrl != null) {
        unawaited(OfflineAudioCache.ensure(surah.surahAudioUrl!));
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  Future<void> selectAyah(int index) async {
    final s = state;
    if (s is! QuranReaderReady) return;
    emit(s.copyWith(currentIndex: index, clearPlaying: true));
    await _stopAudio();
    await _persistProgress(s.ayahs[index]);
  }

  Future<void> playCurrent({bool continuePlaylist = false}) async {
    final s = state;
    if (s is! QuranReaderReady) return;
    final ayah = s.ayahs[s.currentIndex];
    final url = ayah.audioUrl;
    if (url == null) return;

    _autoPlayNext = continuePlaylist;

    if (s.isPlaying && s.playingKey == ayah.key) {
      await _stopAudio();
      _autoPlayNext = false;
      emit(s.copyWith(isPlaying: false, clearPlaying: true));
      return;
    }

    emit(s.copyWith(isPlaying: true, playingKey: ayah.key, playerVisible: true));
    final ok = await _playUrl(url);
    if (!ok) {
      final latest = state;
      if (latest is QuranReaderReady) {
        emit(latest.copyWith(isPlaying: false, clearPlaying: true));
      }
      return;
    }
    await _persistProgress(ayah);
  }

  Future<void> playSurahAudio() async {
    final s = state;
    if (s is! QuranReaderReady || s.surahAudioUrl == null) return;
    _autoPlayNext = false;
    if (s.isPlaying && s.playingKey == 'surah') {
      await _stopAudio();
      emit(s.copyWith(isPlaying: false, clearPlaying: true));
      return;
    }
    emit(
      s.copyWith(isPlaying: true, playingKey: 'surah', playerVisible: true),
    );
    final ok = await _playUrl(s.surahAudioUrl!);
    if (!ok) {
      final latest = state;
      if (latest is QuranReaderReady) {
        emit(latest.copyWith(isPlaying: false, clearPlaying: true));
      }
    }
  }

  Future<void> toggleAyahFavorite() async {
    final s = state;
    if (s is! QuranReaderReady) return;
    final ayah = s.ayahs[s.currentIndex];
    final meta = kSurahs.firstWhere(
      (x) => x.number == ayah.surahNumber,
      orElse: () => Surah(
        number: ayah.surahNumber,
        latin: ayah.surahName,
        french: '',
        arabic: '',
        ayahCount: 0,
      ),
    );
    final item = FavoriteItem(
      id: FavoriteItem.ayahId(ayah.surahNumber, ayah.ayah),
      type: 'ayah',
      surah: ayah.surahNumber,
      ayah: ayah.ayah,
      surahLatin: meta.latin,
      surahArabic: meta.arabic,
      arabicPreview: ayah.arabic,
    );
    await _repo.toggleFavorite(item);
    final next = {...s.favoriteIds};
    if (next.contains(item.id)) {
      next.remove(item.id);
    } else {
      next.add(item.id);
    }
    emit(s.copyWith(favoriteIds: next));
  }

  Future<void> playPrevious() async {
    final s = state;
    if (s is! QuranReaderReady || s.currentIndex <= 0) return;
    await selectAyah(s.currentIndex - 1);
    await playCurrent(continuePlaylist: s.repeat);
  }

  Future<void> playNext() async {
    final s = state;
    if (s is! QuranReaderReady || s.currentIndex >= s.ayahs.length - 1) {
      return;
    }
    await selectAyah(s.currentIndex + 1);
    await playCurrent(continuePlaylist: s.repeat);
  }

  Future<void> togglePlayPause() async {
    final s = state;
    if (s is! QuranReaderReady) return;
    if (s.isPlaying && s.playingKey == s.current.key) {
      await playCurrent(continuePlaylist: s.repeat);
      return;
    }
    await playCurrent(continuePlaylist: true);
  }

  Future<void> _onAudioComplete() async {
    final s = state;
    if (s is! QuranReaderReady) return;
    if ((s.repeat || _autoPlayNext) && s.currentIndex < s.ayahs.length - 1) {
      final next = s.currentIndex + 1;
      emit(s.copyWith(currentIndex: next, isPlaying: false, clearPlaying: true));
      await _persistProgress(s.ayahs[next]);
      await playCurrent(continuePlaylist: true);
    } else {
      emit(s.copyWith(isPlaying: false, clearPlaying: true));
    }
  }

  Future<void> _stopAudio() async {
    _audioGen++;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Lance une URL en invalidant les lectures concurrentes / interrompues.
  Future<bool> _playUrl(String url) async {
    final gen = ++_audioGen;
    try {
      await _player.stop();
    } catch (_) {}
    if (gen != _audioGen) return false;

    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (gen != _audioGen) return false;

    try {
      await _player.play(await OfflineAudioCache.sourceFor(url));
      return gen == _audioGen;
    } catch (e) {
      if (gen != _audioGen) return false;
      if (!_isStreamClosed(e)) return false;

      // Retry une fois après fermeture du stream précédent.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (gen != _audioGen) return false;
      try {
        await _player.play(await OfflineAudioCache.sourceFor(url));
        return gen == _audioGen;
      } catch (_) {
        return false;
      }
    }
  }

  bool _isStreamClosed(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('stream closed') || msg.contains('before it got prepared');
  }

  Future<void> _persistProgress(QuranAyah ayah) async {
    final meta = kSurahs.firstWhere(
      (x) => x.number == ayah.surahNumber,
      orElse: () => Surah(
        number: ayah.surahNumber,
        latin: ayah.surahName,
        french: '',
        arabic: '',
        ayahCount: 0,
      ),
    );
    await _repo.saveProgress(
      LastReading(
        surah: ayah.surahNumber,
        ayah: ayah.ayah,
        surahLatin: meta.latin,
        surahArabic: meta.arabic,
        label: 'Verset ${ayah.ayah}',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    _audioGen++;
    try {
      await _player.stop();
    } catch (_) {}
    await _player.dispose();
    return super.close();
  }
}

sealed class QuranReaderState {
  const QuranReaderState();
}

class QuranReaderLoading extends QuranReaderState {
  const QuranReaderLoading();
}

class QuranReaderError extends QuranReaderState {
  const QuranReaderError(this.message);
  final String message;
}

class QuranReaderReady extends QuranReaderState {
  const QuranReaderReady({
    required this.title,
    required this.subtitle,
    required this.surahNumber,
    required this.ayahs,
    required this.currentIndex,
    required this.favoriteIds,
    this.surahAudioUrl,
    this.isPlaying = false,
    this.playingKey,
    this.repeat = true,
    this.playerVisible = false,
  });

  final String title;
  final String subtitle;
  final int surahNumber;
  final List<QuranAyah> ayahs;
  final int currentIndex;
  final Set<String> favoriteIds;
  final String? surahAudioUrl;
  final bool isPlaying;
  final String? playingKey;
  final bool repeat;
  /// Bande audio visible seulement après lancement de l'écoute.
  final bool playerVisible;

  QuranAyah get current => ayahs[currentIndex];

  bool get isCurrentFavorite =>
      favoriteIds.contains(FavoriteItem.ayahId(current.surahNumber, current.ayah));

  QuranReaderReady copyWith({
    String? title,
    String? subtitle,
    int? surahNumber,
    List<QuranAyah>? ayahs,
    int? currentIndex,
    Set<String>? favoriteIds,
    String? surahAudioUrl,
    bool? isPlaying,
    String? playingKey,
    bool? repeat,
    bool? playerVisible,
    bool clearPlaying = false,
  }) {
    return QuranReaderReady(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahs: ayahs ?? this.ayahs,
      currentIndex: currentIndex ?? this.currentIndex,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      surahAudioUrl: surahAudioUrl ?? this.surahAudioUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      playingKey: clearPlaying ? null : (playingKey ?? this.playingKey),
      repeat: repeat ?? this.repeat,
      playerVisible: playerVisible ?? this.playerVisible,
    );
  }
}
