import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_data.dart';

/// Position utilisateur persistée (SharedPreferences).
class LocationService {
  static const _kLat = 'user_lat';
  static const _kLng = 'user_lng';
  static const _kLabel = 'user_location_label';
  static const _kSaved = 'user_location_saved';

  Future<UserLocation> loadSavedOrFallback() async {
    final saved = await readSaved();
    return saved ?? UserLocation.fallback;
  }

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

  /// Demande la permission GPS (une fois) et enregistre la position.
  /// Si déjà sauvegardée, renvoie directement sans re-demander.
  Future<UserLocation> requestAndSave({bool force = false}) async {
    if (!force) {
      final existing = await readSaved();
      if (existing != null) return existing;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw const LocationException(
        'Active la localisation dans les paramètres du téléphone.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Autorisation refusée. Autorise la localisation pour Noor Al Iman.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw const LocationException(
        'Localisation bloquée. Active-la dans les paramètres de l’app.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    final label = await _labelFor(position.latitude, position.longitude);
    final location = UserLocation(
      label: label,
      latitude: position.latitude,
      longitude: position.longitude,
      fromGps: true,
    );

    await _save(location);
    return location;
  }

  Future<void> _save(UserLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSaved, true);
    await prefs.setDouble(_kLat, location.latitude);
    await prefs.setDouble(_kLng, location.longitude);
    await prefs.setString(_kLabel, location.label);
  }

  /// Restaure une position depuis Firestore (nouveau téléphone).
  Future<void> persist(UserLocation location) async {
    await _save(location);
  }

  Future<String> _labelFor(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return 'Ma position';
      final place = places.first;
      final city = place.locality ?? place.subAdministrativeArea ?? place.name;
      final country = place.isoCountryCode ?? place.country;
      if (city == null || city.isEmpty) return 'Ma position';
      if (country == null || country.isEmpty) return city;
      return '$city, $country';
    } catch (_) {
      return 'Ma position';
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
