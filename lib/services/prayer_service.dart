import 'package:flutter/material.dart';

import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;

import '../models/my_prayer.dart';

class PrayersException implements Exception {
  final String message;
  final Object? cause;

  const PrayersException(this.message, {this.cause});

  @override
  String toString() =>
      'PrayersException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class PrayerService {
  PrayerTimes? _cachedPrayerTimes;
  DateTime? _cacheDate;

  CalculationMethod defaultMethod;
  Madhab defaultMadhab;

  PrayerService({
    this.defaultMethod = CalculationMethod.egyptian,
    this.defaultMadhab = Madhab.shafi,
  });

  // ---------------------------------------------------------------------------
  // CORE
  // ---------------------------------------------------------------------------

  Future<PrayerTimes> getPrayerTimes({
    required loc.LocationData location,
    CalculationMethod? method,
    Madhab? madhab,
  }) async {
    final now = DateTime.now();
    final resolvedMethod = method ?? defaultMethod;
    final resolvedMadhab = madhab ?? defaultMadhab;

    if (_cachedPrayerTimes != null &&
        _cacheDate != null &&
        _isSameDay(now, _cacheDate!)) {
      return _cachedPrayerTimes!;
    }

    final lat = location.latitude;
    final lng = location.longitude;

    if (lat == null || lng == null || !_isValidCoordinate(lat, lng)) {
      throw const PrayersException('Location data is unavailable.');
    }

    final coordinates = Coordinates(lat, lng);
    final date = DateComponents.from(now);
    final params = resolvedMethod.getParameters()..madhab = resolvedMadhab;

    _cachedPrayerTimes = PrayerTimes(coordinates, date, params);
    _cacheDate = now;

    return _cachedPrayerTimes!;
  }

  // ---------------------------------------------------------------------------
  // REST OF YOUR LOGIC (UNCHANGED)
  // ---------------------------------------------------------------------------

  void invalidateCache() {
    _cachedPrayerTimes = null;
    _cacheDate = null;
  }

  DateTime? timeForNextPrayer(PrayerTimes prayers, Prayer next) {
    if (next != Prayer.fajr) {
      return prayers.timeForPrayer(next);
    }

    final now = DateTime.now();

    if (now.isAfter(prayers.isha)) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayers = PrayerTimes(
        prayers.coordinates,
        DateComponents.from(tomorrow),
        prayers.calculationParameters,
      );
      return tomorrowPrayers.fajr;
    }

    return prayers.fajr;
  }

  Prayer getNextPrayer(PrayerTimes prayers) {
    final next = prayers.nextPrayer();
    return next == Prayer.none ? Prayer.fajr : next;
  }

  Duration timeUntilNextPrayer(PrayerTimes prayers) {
    final next = getNextPrayer(prayers);
    final nextTime = timeForNextPrayer(prayers, next);
    if (nextTime == null) return Duration.zero;

    final diff = nextTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  List<MyPrayer> formatPrayers(PrayerTimes prayers) {
    return [
      MyPrayer(
        prayer: Prayer.fajr,
        name: getArabicPrayerName(Prayer.fajr),
        icon: getPrayerIcon(Prayer.fajr),
        time: prayers.fajr,
      ),
      MyPrayer(
        prayer: Prayer.sunrise,
        name: getArabicPrayerName(Prayer.sunrise),
        icon: getPrayerIcon(Prayer.sunrise),
        time: prayers.sunrise,
      ),
      MyPrayer(
        prayer: Prayer.dhuhr,
        name: getArabicPrayerName(Prayer.dhuhr),
        icon: getPrayerIcon(Prayer.dhuhr),
        time: prayers.dhuhr,
      ),
      MyPrayer(
        prayer: Prayer.asr,
        name: getArabicPrayerName(Prayer.asr),
        icon: getPrayerIcon(Prayer.asr),
        time: prayers.asr,
      ),
      MyPrayer(
        prayer: Prayer.maghrib,
        name: getArabicPrayerName(Prayer.maghrib),
        icon: getPrayerIcon(Prayer.maghrib),
        time: prayers.maghrib,
      ),
      MyPrayer(
        prayer: Prayer.isha,
        name: getArabicPrayerName(Prayer.isha),
        icon: getPrayerIcon(Prayer.isha),
        time: prayers.isha,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS (UNCHANGED)

  MyPrayer formatPrayer(PrayerTimes prayers, Prayer p) {
    final time = timeForNextPrayer(prayers, p);
    if (time == null) {
      throw PrayersException('Could not resolve time for prayer: $p');
    }
    return MyPrayer(
      prayer: p,
      name: getArabicPrayerName(p),
      icon: getPrayerIcon(p),
      time: time,
    );
  }

  String formatCountdown(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String formatTime(DateTime t) => DateFormat.jm("ar").format(t);

  Color getPrayerColor(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const Color(0xFF5E35B1);
      case Prayer.sunrise:
        return const Color(0xFFFF6F00);
      case Prayer.dhuhr:
        return const Color(0xFF1565C0);
      case Prayer.asr:
        return const Color(0xFFF57C00);
      case Prayer.maghrib:
        return const Color(0xFFAD1457);
      case Prayer.isha:
        return const Color(0xFF283593);
      default:
        return const Color(0xFF424242);
    }
  }

  IconData getPrayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.brightness_2;
      case Prayer.sunrise:
        return Icons.wb_sunny_outlined;
      case Prayer.dhuhr:
        return Icons.wb_sunny;
      case Prayer.asr:
        return Icons.sunny;
      case Prayer.maghrib:
        return Icons.nightlight_round;
      case Prayer.isha:
        return Icons.brightness_3;
      default:
        return Icons.access_time;
    }
  }

  String getArabicPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isValidCoordinate(double lat, double lng) =>
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      !(lat == 0.0 && lng == 0.0);
}
