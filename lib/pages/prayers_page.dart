import 'dart:async';

import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/my_info_box.dart';
import '../components/next_prayer_box.dart';
import '../components/prayer_tile.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../themes/theme_extensions.dart';
import '../services/noti_service.dart';import '../services/adhan_service.dart';

class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage>
    with TickerProviderStateMixin {
  final String _hijriDate = HijriCalendar.now().toFormat("dd MMMM yyyy هـ");
  final String _gregorianDate =
      DateFormat.yMMMMEEEEd('ar').format(DateTime.now());

  PrayerTimes? _prayerTimes;
  bool _loading = true;
  bool _error = false;

  // Guards against concurrent _load() calls (e.g. countdown expiry firing
  // while a pull-to-refresh is already in flight).
  bool _loadInProgress = false;

  // Tracks the last location used to schedule notifications so we only
  // reschedule when the location meaningfully changes, not on every rebuild.
  String? _lastNotificationLocationKey;

  // ── Countdown ─────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _countdownCtrl;
  late final AnimationController _listCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _staggerCtrl;

  late final Animation<double> _headerAnim;
  late final Animation<double> _countdownAnim;
  late final Animation<Offset> _slideAnim;

  static const int _tileCount = 6;
  late final List<Animation<double>> _tileAnimations;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _headerCtrl.dispose();
    _countdownCtrl.dispose();
    _listCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final location = context.watch<LocationService>().currentLocation;

    // Only trigger a reload when:
    //   1. We're not already loading, AND
    //   2. The location has actually changed since the last load.
    // This prevents a cascade of _load() calls during normal rebuilds and
    // avoids redundant notification rescheduling.
    if (location != null && !_loading && !_loadInProgress) {
      final key = '${location.latitude},${location.longitude}';
      if (key != _lastNotificationLocationKey) {
        _load();
      }
    }
  }

  // ── Animation setup ───────────────────────────────────────────────────────
  void _initAnimations() {
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnim = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutBack,
    );

    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _countdownAnim = CurvedAnimation(
      parent: _countdownCtrl,
      curve: Curves.elasticOut,
    );

    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _listCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _tileAnimations = List.generate(_tileCount, (i) {
      final start = i / _tileCount;
      final end = (i + 1) / _tileCount;
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
  }

  void _resetAnimations() {
    _headerCtrl.reset();
    _countdownCtrl.reset();
    _listCtrl.reset();
    _staggerCtrl.reset();
  }

  Future<void> _runAnimationSequence() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _headerCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _countdownCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _listCtrl.forward();
    _staggerCtrl.forward();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    // Prevent overlapping loads.
    if (_loadInProgress) return;
    if (!mounted) return;

    _loadInProgress = true;

    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final location = context.read<LocationService>().currentLocation;

      if (location == null) {
        throw Exception("Location not available yet");
      }

      final prayerService = context.read<PrayerService>();
      await NotiService.instance.initialize();

      // Build a stable key from the location so we know whether notifications
      // need to be rescheduled. We truncate to 4 decimal places (~11 m) to
      // avoid rescheduling on sub-meter GPS jitter.
      final locationKey =
          '${location.latitude?.toStringAsFixed(4)},${location.longitude?.toStringAsFixed(4)}';

      final bool shouldScheduleNotifications =
          locationKey != _lastNotificationLocationKey;

      final times = await prayerService.getPrayerTimes(location: location);

      if (shouldScheduleNotifications) {
        final prayersList = prayerService.formatPrayers(times);

        await NotiService.instance.schedulePrayerNotifications(prayersList);
        await AdhanService.instance.playPrayerAdhan();
        _lastNotificationLocationKey = locationKey; 

        if (mounted) {
          // Show a brief confirmation so the user knows notifications were set.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '🔔 تم جدولة إشعارات الصلاة',
                style: TextStyle(fontFamily: 'Lateef', fontSize: 16),
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _prayerTimes = times;
        _loading = false;
      });

      _startCountdown(times);
      _resetAnimations();
      _runAnimationSequence();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = true;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      // Always release the guard, even if an exception was thrown.
      _loadInProgress = false;
    }
  }

  // ── Countdown timer ───────────────────────────────────────────────────────
  void _startCountdown(PrayerTimes prayers) {
    _countdownTimer?.cancel();
    final prayerService = context.read<PrayerService>();
    final nextPrayer = prayerService.getNextPrayer(prayers);
    final nextTime = prayerService.timeForNextPrayer(prayers, nextPrayer);
    if (nextTime == null) return;

    setState(() {
      _timeLeft = nextTime.difference(DateTime.now());
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final diff = nextTime.difference(DateTime.now());
      if (diff.isNegative) {
        // Cancel before reload to prevent the timer from firing again while
        // _load() is awaiting getPrayerTimes().
        _countdownTimer?.cancel();
        _load();
      } else {
        setState(() => _timeLeft = diff);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Pull-to-refresh: invalidate cache so fresh prayer times are fetched,
        // then reset the location key so notifications are rescheduled too.
        context.read<PrayerService>().invalidateCache();
        _lastNotificationLocationKey = null;
        await _load();
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error || _prayerTimes == null) return _buildError();
    return _buildContent(_prayerTimes!);
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تحميل المواقيت...',
                style: TextStyle(
                  fontFamily: 'Lateef',
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(child: MyInfoBox(text: 'تعذر تحميل المواقيت')),
      ),
    );
  }

  Widget _buildContent(PrayerTimes prayers) {
    final prayerService = context.read<PrayerService>();

    final currentPrayer = prayers.currentPrayer();
    final nextPrayer = prayerService.getNextPrayer(prayers);
    final prayersList = prayerService.formatPrayers(prayers);

    return ListView(
      padding: context.paddingMD,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        NextPrayerBox(
          prayers: prayers,
          timeLeft: _timeLeft,
          countdownAnimation: _countdownAnim,
          shimmerController: _shimmerCtrl,
          pulseController: _pulseCtrl,
        ),
        context.gapMD,
        FadeTransition(
          opacity: _headerAnim,
          child: Row(
            children: [
              Expanded(child: MyInfoBox(text: _hijriDate)),
              context.gapSM,
              Expanded(child: MyInfoBox(text: _gregorianDate)),
            ],
          ),
        ),
        context.gapLG,
        SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              for (int i = 0; i < prayersList.length; i++)
                PrayerTile(
                  prayer: prayersList[i],
                  index: i,
                  tileAnimations: _tileAnimations,
                  isCurrent: currentPrayer == prayersList[i].prayer,
                  isNext: nextPrayer == prayersList[i].prayer,
                  pulseController: _pulseCtrl,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
