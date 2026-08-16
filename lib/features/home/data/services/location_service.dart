import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/l10n/app_strings.dart';
import '../models/home_data.dart';

/// Position utilisateur (GPS → SharedPreferences ; sync Firestore via repository).
class LocationService {
  static const _kLat = 'user_lat';
  static const _kLng = 'user_lng';
  static const _kLabel = 'user_location_label';
  static const _kSaved = 'user_location_saved';

  Future<UserLocation?> readSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSaved) != true) return null;

    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    final label = prefs.getString(_kLabel);
    if (lat == null || lng == null || label == null) return null;

    return UserLocation(
      label: label,
      latitude: lat,
      longitude: lng,
      fromGps: true,
    );
  }

  /// Demande la permission GPS et enregistre la position.
  ///
  /// Si le GPS échoue → [LocationException].
  /// - [force] true : ouvre les réglages si GPS off / permission refusée.
  Future<UserLocation> requestAndSave({bool force = false}) async {
    if (!force) {
      final existing = await readSaved();
      if (existing != null) return existing;
    }

    final gps = await _tryGps(forceFresh: force);
    if (gps != null) {
      await _save(gps);
      return gps;
    }

    // Dernière chance : position déjà connue du système.
    final last = await _fromLastKnown();
    if (last != null) {
      await _save(last);
      return last;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (force) await Geolocator.openLocationSettings();
      throw LocationException(S.locationGpsOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (force) await Geolocator.openAppSettings();
      throw LocationException(S.locationPermissionDenied);
    }

    throw LocationException(S.locationUnavailable);
  }

  /// Comme [requestAndSave] mais ne lance jamais : utile après login.
  Future<UserLocation?> tryRequestAndSave({bool force = false}) async {
    try {
      return await requestAndSave(force: force);
    } catch (_) {
      return readSaved();
    }
  }

  Future<UserLocation?> _tryGps({required bool forceFresh}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Rapide : dernière position connue (évite TimeoutException au login).
      if (!forceFresh) {
        final cached = await _fromLastKnown();
        if (cached != null) return cached;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } on TimeoutException {
        // GPS lent / intérieur : fallback sans faire planter le debugger.
        return _fromLastKnown();
      }

      return _fromPosition(position);
    } on TimeoutException {
      return _fromLastKnown();
    } catch (_) {
      return _fromLastKnown();
    }
  }

  Future<UserLocation?> _fromLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      return _fromPosition(last);
    } catch (_) {
      return null;
    }
  }

  Future<UserLocation> _fromPosition(Position position) async {
    final label = await _labelFor(position.latitude, position.longitude);
    return UserLocation(
      label: label,
      latitude: position.latitude,
      longitude: position.longitude,
      fromGps: true,
    );
  }

  Future<void> _save(UserLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSaved, true);
    await prefs.setDouble(_kLat, location.latitude);
    await prefs.setDouble(_kLng, location.longitude);
    await prefs.setString(_kLabel, location.label);
  }

  Future<void> persist(UserLocation location) async {
    await _save(location);
  }

  Future<String> _labelFor(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 4));
      if (places.isEmpty) {
        return _coordsLabel(lat, lng);
      }
      final place = places.first;
      final city = place.locality ?? place.subAdministrativeArea ?? place.name;
      final country = place.isoCountryCode ?? place.country;
      if (city == null || city.isEmpty) return _coordsLabel(lat, lng);
      if (country == null || country.isEmpty) return city;
      return '$city, $country';
    } catch (_) {
      return _coordsLabel(lat, lng);
    }
  }

  String _coordsLabel(double lat, double lng) =>
      S.myPosition('${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}');
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
