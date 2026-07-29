import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/home_data.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/services/location_service.dart';
import '../../../prayer/data/services/prayer_notification_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository, {AudioPlayer? player})
    : _player = player ?? AudioPlayer(),
      super(const HomeInitial());

  final HomeRepository _repository;
  final AudioPlayer _player;
  bool _notificationsEnabled = true;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final data = await _repository.loadHome();
      emit(HomeLoaded(data: data, notificationsEnabled: _notificationsEnabled));
      await PrayerNotificationService.instance.rescheduleFromApi(data.prayer);
    } catch (_) {
      emit(
        const HomeError(
          'Impossible de charger les données. Vérifiez votre connexion.',
        ),
      );
    }
  }

  /// Clic localisation → GPS + sauvegarde locale.
  Future<void> requestUserLocation() async {
    emit(const HomeLoading());
    try {
      final data = await _repository.requestUserLocationAndLoad();
      emit(HomeLoaded(data: data, notificationsEnabled: _notificationsEnabled));
      await PrayerNotificationService.instance.rescheduleFromApi(data.prayer);
    } on LocationException catch (e) {
      emit(HomeError(e.message));
    } catch (_) {
      emit(
        const HomeError(
          'Impossible d’obtenir ta position. Réessaie plus tard.',
        ),
      );
    }
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(notificationsEnabled: _notificationsEnabled));
      if (_notificationsEnabled) {
        PrayerNotificationService.instance.rescheduleFromApi(current.data.prayer);
      } else {
        PrayerNotificationService.instance.cancelAll();
      }
    }
  }

  Future<void> playVerse(String? url) async {
    if (url == null) return;
    final current = state;
    if (current is! HomeLoaded) return;

    if (current.isPlaying && current.playingUrl == url) {
      await _player.stop();
      emit(current.copyWith(isPlaying: false, clearPlayingUrl: true));
      return;
    }

    await _player.stop();
    emit(current.copyWith(isPlaying: true, playingUrl: url));
    try {
      await _player.play(UrlSource(url));
      _player.onPlayerComplete.first.then((_) {
        final latest = state;
        if (latest is HomeLoaded) {
          emit(latest.copyWith(isPlaying: false, clearPlayingUrl: true));
        }
      });
    } catch (_) {
      emit(current.copyWith(isPlaying: false, clearPlayingUrl: true));
    }
  }

  Future<DailyVerse> loadNextAyah(DailyVerse verse) {
    return _repository.loadAyah(surah: verse.surahNumber, ayah: verse.ayah + 1);
  }

  @override
  Future<void> close() async {
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
    this.notificationsEnabled = true,
    this.isPlaying = false,
    this.playingUrl,
  });

  final HomeData data;
  final bool notificationsEnabled;
  final bool isPlaying;
  final String? playingUrl;

  HomeLoaded copyWith({
    HomeData? data,
    bool? notificationsEnabled,
    bool? isPlaying,
    String? playingUrl,
    bool clearPlayingUrl = false,
  }) {
    return HomeLoaded(
      data: data ?? this.data,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      playingUrl: clearPlayingUrl ? null : (playingUrl ?? this.playingUrl),
    );
  }
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;
}
