import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class LocationException implements Exception {
  final String message;
  final Object? cause;

  const LocationException(this.message, {this.cause});

  @override
  String toString() =>
      'LocationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class _CityNameCache {
  final String name;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const _CityNameCache({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });
}

/// ✅ NOW A PROVIDER
class LocationService extends ChangeNotifier {
  final loc.Location _location = loc.Location();

  Future<loc.LocationData>? _activeRequest;

  loc.LocationData? _cachedLocation;
  DateTime? _locationFetchedAt;

  final Duration locationCacheDuration;

  _CityNameCache? _cityNameCache;

  static const double _cityNameCacheRadiusKm = 2.0;

  LocationService({
    this.locationCacheDuration = const Duration(seconds: 15),
  });

  // ─────────────────────────────────────────────
  // PUBLIC STATE ACCESS
  // ─────────────────────────────────────────────

  loc.LocationData? get currentLocation => _cachedLocation;

  bool get hasLocation => _cachedLocation != null;

  // ─────────────────────────────────────────────
  // MAIN LOCATION FETCH
  // ─────────────────────────────────────────────

  Future<loc.LocationData> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedLocation != null &&
        _locationFetchedAt != null &&
        now.difference(_locationFetchedAt!) < locationCacheDuration) {
      return _cachedLocation!;
    }

    if (_activeRequest != null) {
      return await _activeRequest!;
    }

    await _ensureServiceEnabled();
    await _ensurePermissionGranted();

    try {
      _activeRequest = _location.getLocation();

      final data = await _activeRequest!;

      if (data.latitude == null || data.longitude == null) {
        throw const LocationException('Invalid coordinates received.');
      }

      _cachedLocation = data;
      _locationFetchedAt = now;

      notifyListeners(); // 🔥 UI updates here

      return data;
    } catch (e) {
      throw LocationException('Failed to fetch location.', cause: e);
    } finally {
      _activeRequest = null;
    }
  }

  // ─────────────────────────────────────────────
  // CITY NAME
  // ─────────────────────────────────────────────

  Future<String> getCityName({bool forceRefresh = false}) async {
    final data = await getCurrentLocation(forceRefresh: forceRefresh);

    final lat = data.latitude!;
    final lng = data.longitude!;

    if (!forceRefresh && _cityNameCache != null) {
      final distKm = _haversineKm(
        lat,
        lng,
        _cityNameCache!.latitude,
        _cityNameCache!.longitude,
      );

      if (distKm < _cityNameCacheRadiusKm) {
        return _cityNameCache!.name;
      }
    }

    final placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) {
      throw const LocationException('No address found.');
    }

    final place = placemarks.first;

    final city = place.locality?.trim();
    final admin = place.subAdministrativeArea?.trim();

    final name =
        [city, admin].where((e) => e != null && e.isNotEmpty).join(' - ');

    _cityNameCache = _CityNameCache(
      name: name,
      latitude: lat,
      longitude: lng,
      fetchedAt: DateTime.now(),
    );

    return name;
  }

  // ─────────────────────────────────────────────
  // STATUS CHECK
  // ─────────────────────────────────────────────

  Future<bool> isLocationAvailable() async {
    try {
      await _ensureServiceEnabled();
      await _ensurePermissionGranted();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // CACHE CONTROL
  // ─────────────────────────────────────────────

  void invalidateCache() {
    _cachedLocation = null;
    _locationFetchedAt = null;
    _cityNameCache = null;

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────

  Future<void> _ensureServiceEnabled() async {
    bool enabled = await _location.serviceEnabled();

    if (!enabled) {
      enabled = await _location.requestService();
      if (!enabled) {
        throw const LocationException('Location service disabled.');
      }
    }
  }

  Future<void> _ensurePermissionGranted() async {
    var permission = await _location.hasPermission();

    if (permission == loc.PermissionStatus.deniedForever) {
      throw const LocationException('Permission permanently denied.');
    }

    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != loc.PermissionStatus.granted) {
        throw const LocationException('Permission denied.');
      }
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.pow(math.sin(dLon / 2), 2) *
            math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2));

    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
