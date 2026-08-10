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

    final gps = await _tryGps();
    if (gps != null) {
      await _save(gps);
      return gps;
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

  Future<UserLocation?> _tryGps() async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final label = await _labelFor(position.latitude, position.longitude);
      return UserLocation(
        label: label,
        latitude: position.latitude,
        longitude: position.longitude,
        fromGps: true,
      );
    } catch (_) {
      return null;
    }
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
      final places = await placemarkFromCoordinates(lat, lng);
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
