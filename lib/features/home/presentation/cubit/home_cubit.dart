import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../duas/data/models/dua_models.dart';
import '../../../prayer/data/services/prayer_notification_service.dart';
import '../../../../app/app_settings.dart';
import '../../../../app/l10n/content_lang.dart';
import '../../data/models/home_data.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/services/location_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository, {AudioPlayer? player})
    : _player = player ?? AudioPlayer(),
      super(const HomeInitial());

  final HomeRepository _repository;
  final AudioPlayer _player;
  StreamSubscription<void>? _completeSub;
  Future<void>? _notifSync;
  String? _lastNotifFingerprint;
  int _audioGen = 0;

  Future<void> load({bool silent = false}) async {
    final keepUi = silent || state is HomeLoaded;
    if (!keepUi) emit(const HomeLoading());
    try {
      final data = await _repository.loadHome();
      final playing = state is HomeLoaded ? (state as HomeLoaded).isPlaying : false;
      final url = state is HomeLoaded ? (state as HomeLoaded).playingUrl : null;
      emit(HomeLoaded(data: data, isPlaying: playing, playingUrl: url));
      unawaited(_syncNotifications(data));
    } catch (_) {
      if (keepUi && state is HomeLoaded) return;
      emit(
        const HomeError(
          'Impossible de charger les données. Vérifiez votre connexion.',
        ),
      );
    }
  }

  /// Met à jour la position GPS. Renvoie `true` si OK.
  Future<bool> requestUserLocation() async {
    final previous = state is HomeLoaded ? (state as HomeLoaded) : null;
    if (previous == null) emit(const HomeLoading());
    try {
      final data = await _repository.requestUserLocationAndLoad();
      emit(
        HomeLoaded(
          data: data,
          isPlaying: previous?.isPlaying ?? false,
          playingUrl: previous?.playingUrl,
        ),
      );
      unawaited(_syncNotifications(data));
      return true;
    } catch (e) {
      if (previous != null) {
        emit(previous);
      } else if (e is LocationException) {
        emit(HomeError(e.message));
      } else {
        emit(
          const HomeError(
            'Impossible d’obtenir ta position. Réessaie plus tard.',
          ),
        );
      }
      return false;
    }
  }

  void invalidateNotifSync() {
    _lastNotifFingerprint = null;
  }

  Future<void> _syncNotifications(HomeData data) async {
    if (!data.prayer.hasTimes) return;
    if (!AppSettings.notificationsEnabled.value) return;

    final times = data.prayer.prayerTimes.entries
        .map((e) => '${e.key}:${e.value}')
        .toList()
      ..sort();
    final fingerprint =
        '${times.join(',')}|${data.morningDua?.id}|${data.eveningDua?.id}|${data.dailyDua?.id}';
    if (fingerprint == _lastNotifFingerprint) return;

    _notifSync = (_notifSync ?? Future.value()).then((_) async {
      try {
        final notif = PrayerNotificationService.instance;
        await notif.rescheduleFromApi(data.prayer);

        String preview(String arabic) {
          final t = arabic.trim();
          if (t.length <= 80) return t;
          return '${t.substring(0, 80).trimRight()}…';
        }

        String? bodyFor(Dua? dua) {
          if (dua == null) return null;
          return '${ContentLang.duaTitle(dua)}\n${preview(dua.arabic)}';
        }

        final wakeDua = data.dailyDua ?? data.morningDua;
        await notif.scheduleDailyDuas(
          prayer: data.prayer,
          morningTitle: 'Réveil · Doua du jour',
          morningBody: bodyFor(wakeDua),
          morningHeadline: 'Doua du matin',
          eveningTitle: 'Doua du soir · Noor Al-Iman',
          eveningBody: bodyFor(data.eveningDua ?? data.dailyDua),
          eveningHeadline: 'Doua du soir',
        );
        _lastNotifFingerprint = fingerprint;
      } catch (_) {
        // Réessayer au prochain load.
      }
    });
    await _notifSync;
  }

  Future<void> playVerse(String? url) async {
    if (url == null) return;
    final current = state;
    if (current is! HomeLoaded) return;

    if (current.isPlaying && current.playingUrl == url) {
      await _completeSub?.cancel();
      _audioGen++;
      try {
        await _player.stop();
      } catch (_) {}
      emit(current.copyWith(isPlaying: false, clearPlayingUrl: true));
      return;
    }

    await _completeSub?.cancel();
    final gen = ++_audioGen;
    try {
      await _player.stop();
    } catch (_) {}
    if (gen != _audioGen) return;

    emit(current.copyWith(isPlaying: true, playingUrl: url));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (gen != _audioGen) return;

    try {
      await _player.play(UrlSource(url));
      if (gen != _audioGen) return;
      _completeSub = _player.onPlayerComplete.listen((_) {
        final latest = state;
        if (latest is HomeLoaded) {
          emit(latest.copyWith(isPlaying: false, clearPlayingUrl: true));
        }
      });
    } catch (e) {
      if (gen != _audioGen) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('stream closed') ||
          msg.contains('before it got prepared')) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (gen != _audioGen) return;
        try {
          await _player.play(UrlSource(url));
          _completeSub = _player.onPlayerComplete.listen((_) {
            final latest = state;
            if (latest is HomeLoaded) {
              emit(latest.copyWith(isPlaying: false, clearPlayingUrl: true));
            }
          });
          return;
        } catch (_) {}
      }
      emit(current.copyWith(isPlaying: false, clearPlayingUrl: true));
    }
  }

  Future<DailyVerse> loadNextAyah(DailyVerse verse) {
    return _repository.loadAyah(surah: verse.surahNumber, ayah: verse.ayah + 1);
  }

  @override
  Future<void> close() async {
    await _completeSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}

sealed class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.data,
    this.isPlaying = false,
    this.playingUrl,
  });

  final HomeData data;
  final bool isPlaying;
  final String? playingUrl;

  HomeLoaded copyWith({
    HomeData? data,
    bool? isPlaying,
    String? playingUrl,
    bool clearPlayingUrl = false,
  }) {
    return HomeLoaded(
      data: data ?? this.data,
      isPlaying: isPlaying ?? this.isPlaying,
      playingUrl: clearPlayingUrl ? null : (playingUrl ?? this.playingUrl),
    );
  }
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;
}
