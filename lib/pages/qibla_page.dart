import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../components/qibla_compass.dart';
import '../services/location_service.dart';
import '../services/qibla_service.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with WidgetsBindingObserver {
  // ── State ─────────────────────────────────────────────────────────────────
  double? _qiblaDirection;
  double? _heading;
  double? _headingAngle;
  bool _loading = true;
  bool _error = false;
  bool _aligned = false;

  // ── Compass stream ────────────────────────────────────────────────────────
  StreamSubscription<CompassEvent>? _compassSubscription;

  // ── Throttle: only push a setState at most every 16 ms (~60 fps) ─────────
  static const _kFrameDuration = Duration(milliseconds: 16);
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Alignment hysteresis ──────────────────────────────────────────────────
  // Align ON  at < 5°, align OFF at > 8° – prevents rapid toggling at boundary.
  static const double _kAlignOnThreshold = 5.0;
  static const double _kAlignOffThreshold = 8.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationService = context.read<LocationService>();

      // 🔥 CRITICAL FIX: ensure location exists
      await locationService.getCurrentLocation();

      if (!mounted) return;
      _initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // BUG Q4 FIX: only restart the compass when a valid Qibla direction is
        // already available; otherwise the app was backgrounded mid-load and
        // _initialize will call _startCompass itself once it completes.
        if (_qiblaDirection != null && !_error) {
          _startCompass();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // BUG Q2 FIX: cancel instead of pause. pause() buffers every compass
        // event that arrives while suspended and replays them in a burst on
        // resume, flooding the UI with stale readings and defeating the throttle.
        _cancelCompass();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // BUG Q3 FIX: forceRefresh was always true, bypassing both the
      // QiblaService TTL cache and the LocationService coordinate cache on every
      // retry. Let the service's own TTL decide freshness instead.
      final locationService = context.read<LocationService>();
      final location = locationService.currentLocation;

      if (location == null) {
        throw Exception("Location still not ready");
      }

      final qiblaService = context.read<QiblaService>();

      final result = qiblaService.getQiblaDirection(location: location);
      if (!mounted) return;
      setState(() {
        _qiblaDirection = result.bearing;
        _loading = false;
      });
      _startCompass();
    } catch (e) {
      _handleError(null);
    }
  }

  void _handleError(String? e) {
    if (!mounted) return;
    debugPrint('[QiblaPage] error: $e');
    _cancelCompass();
    setState(() {
      _error = true;
      _loading = false;
    });
  }

  // ── Compass management ────────────────────────────────────────────────────

  void _startCompass() {
    _compassSubscription?.cancel();

    final stream = FlutterCompass.events;
    if (stream == null) {
      // Device has no compass sensor.
      if (mounted) setState(() => _error = true);
      return;
    }

    _compassSubscription = stream.listen(
      _onCompassEvent,
      onError: (_) {
        if (mounted) setState(() => _error = true);
      },
      cancelOnError: true,
    );
  }

  // BUG Q2 FIX: replaced _pauseCompass (which called .pause() and buffered
  // events) with _cancelCompass (which tears down the subscription cleanly).
  // _startCompass on resume creates a fresh subscription with no backlog.
  void _cancelCompass() => _compassSubscription?.cancel();

  void _onCompassEvent(CompassEvent event) {
    final heading = event.heading;
    if (heading == null || !mounted) return;

    // ── Throttle to ~60 fps ───────────────────────────────────────────────
    final now = DateTime.now();
    if (now.difference(_lastUpdate) < _kFrameDuration) return;
    _lastUpdate = now;

    // ── Compute derived values outside setState ───────────────────────────
    double? newAngle;
    bool newAligned = _aligned;

    if (_qiblaDirection != null) {
      // Shortest angular difference, normalised to [-180, 180].
      final diff = _shortestAngleDiff(_qiblaDirection!, heading);
      final absDiff = diff.abs();

      newAngle = diff * (3.1415926535897932 / 180);

      // Hysteresis: latch ON below 5°, latch OFF above 8°.
      if (absDiff < _kAlignOnThreshold && !_aligned) {
        newAligned = true;
        HapticFeedback.mediumImpact(); // single pulse when locked on
      } else if (absDiff > _kAlignOffThreshold && _aligned) {
        newAligned = false;
      }
    }

    setState(() {
      _heading = heading;
      _headingAngle = newAngle;
      _aligned = newAligned;
    });
  }

  /// Returns the signed shortest path from [from] to [to] on a circle (°).
  static double _shortestAngleDiff(double to, double from) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return QiblaCompass(
      init: _initialize,
      heading: _heading,
      headingAngle: _headingAngle,
      qiblaDirection: _qiblaDirection,
      aligned: _aligned,
      loading: _loading,
      error: _error,
    );
  }
}
