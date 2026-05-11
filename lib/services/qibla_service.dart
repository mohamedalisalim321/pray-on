import 'dart:math';

import 'package:location/location.dart' show LocationData;

class QiblaResult {
  final double bearing;
  final double distanceKm;
  final String compassLabel;
  final double userLatitude;
  final double userLongitude;
  final DateTime timestamp;
  final bool fromCache;

  const QiblaResult({
    required this.bearing,
    required this.distanceKm,
    required this.compassLabel,
    required this.userLatitude,
    required this.userLongitude,
    required this.timestamp,
    this.fromCache = false,
  });
}

class QiblaService {
  static const double _kaabaLatitude = 21.4225241;
  static const double _kaabaLongitude = 39.8261818;
  static const double _earthRadiusKm = 6371.0;

  final Duration cacheTtl;
  QiblaResult? _cached;

  QiblaService({
    this.cacheTtl = const Duration(minutes: 5),
  });

  QiblaResult getQiblaDirection({
    required LocationData location,
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _isCacheValid()) {
      return _cached!;
    }

    final lat = location.latitude;
    final lng = location.longitude;

    if (lat == null || lng == null || !_isValid(lat, lng)) {
      throw Exception("Invalid coordinates");
    }

    final bearing = _calculateBearing(lat, lng);
    final distance = _calculateDistance(lat, lng);
    final label = _compassLabel(bearing);

    final result = QiblaResult(
      bearing: bearing,
      distanceKm: distance,
      compassLabel: label,
      userLatitude: lat,
      userLongitude: lng,
      timestamp: DateTime.now(),
    );

    _cached = result;
    return result;
  }

  void clearCache() => _cached = null;

  // ─────────────────────────────────────────────
  // CORE MATH
  // ─────────────────────────────────────────────

  double _calculateBearing(double lat, double lng) {
    final lat1 = _toRad(lat);
    final lat2 = _toRad(_kaabaLatitude);
    final dLng = _toRad(_kaabaLongitude - lng);

    final x = sin(dLng);
    final y = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLng);

    return (_toDeg(atan2(x, y)) + 360) % 360;
  }

  double _calculateDistance(double lat, double lng) {
    final lat1 = _toRad(lat);
    final lat2 = _toRad(_kaabaLatitude);
    final dLat = _toRad(_kaabaLatitude - lat);
    final dLng = _toRad(_kaabaLongitude - lng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);

    return 2 * _earthRadiusKm * atan2(sqrt(a), sqrt(1 - a));
  }

  String _compassLabel(double bearing) {
    const points = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW'
    ];

    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return points[index];
  }

  bool _isCacheValid() {
    if (_cached == null) return false;
    return DateTime.now().difference(_cached!.timestamp) < cacheTtl;
  }

  bool _isValid(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  double _toRad(double d) => d * pi / 180;
  double _toDeg(double r) => r * 180 / pi;
}
