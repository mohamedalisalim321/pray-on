import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/prayer_service.dart';
import '../themes/theme_extensions.dart';
import '../utils/utils.dart';
import 'my_info_box.dart';

class NextPrayerBox extends StatelessWidget {
  final PrayerTimes prayers;
  final Duration timeLeft;

  final Animation<double> countdownAnimation;
  final AnimationController shimmerController;
  final AnimationController pulseController;

  const NextPrayerBox({
    super.key,
    required this.prayers,
    required this.timeLeft,
    required this.countdownAnimation,
    required this.shimmerController,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    // BUG FIX: context.read inside build is fine for StatelessWidget only when
    // the value never changes mid-session (PrayerService is a singleton from
    // the provider tree). Using context.read (not watch) is correct here
    // because NextPrayerBox is rebuilt by its parent whenever data changes.
    final prayerService = context.read<PrayerService>();

    final nextPrayer = prayerService.getNextPrayer(prayers);
    final nextTime = prayerService.timeForNextPrayer(prayers, nextPrayer);

    if (nextTime == null) {
      return const MyInfoBox(text: "لا يمكن تحديد وقت الصلاة القادمة");
    }

    final prayerColor = prayerService.getPrayerColor(nextPrayer);
    final prayerName = prayerService.getArabicPrayerName(nextPrayer);
    final prayerIcon = prayerService.getPrayerIcon(nextPrayer);

    // ── Time-left breakdown ───────────────────────────────────────────────
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;
    final seconds = timeLeft.inSeconds % 60;

    // Build a human-readable Arabic string: hours + minutes only (seconds
    // shown separately in a smaller badge so the main text stays readable).
    String timeLeftText = '';
    if (hours > 0) timeLeftText += '${convertToArabicNumber(hours)} ساعة ';
    if (minutes > 0 || hours > 0) {
      timeLeftText += '${convertToArabicNumber(minutes)} دقيقة';
    }
    if (timeLeftText.isEmpty) {
      timeLeftText = '${convertToArabicNumber(seconds)} ثانية';
    }

    // ── Progress fraction: elapsed / total interval to this prayer ────────
    // We approximate total interval as timeLeft at the last reset (~1 prayer
    // cycle). Since we don't have the start time here, we clamp progress to
    // a safe display-only estimate derived from the current clock position
    // relative to the prayer window. For a cleaner approach the parent could
    // pass a `totalDuration`, but this keeps the widget self-contained.
    final totalSecondsGuess =
        _estimateTotalSeconds(prayers, nextPrayer, nextTime);
    final elapsedSeconds = totalSecondsGuess - timeLeft.inSeconds;
    final progress = totalSecondsGuess > 0
        ? (elapsedSeconds / totalSecondsGuess).clamp(0.0, 1.0)
        : 0.0;

    return ScaleTransition(
      scale: countdownAnimation,
      child: AnimatedBuilder(
        animation: shimmerController,
        builder: (context, child) {
          final sv = shimmerController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  prayerColor.withOpacity(0.18),
                  prayerColor.withOpacity(0.07),
                  prayerColor.withOpacity(0.18),
                ],
                stops: [
                  (sv - 0.35).clamp(0.0, 1.0),
                  sv,
                  (sv + 0.35).clamp(0.0, 1.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: context.radiusXL,
              border: Border.all(
                color: prayerColor.withOpacity(0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: prayerColor.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: context.paddingLG,
            margin: context.paddingSM,
            child: child,
          );
        },
        // child is const-stable; rebuilt only when parent setState fires.
        child: Column(
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            _PulsingIcon(
              icon: prayerIcon,
              color: prayerColor,
              pulseController: pulseController,
            ),

            context.gapMD,

            // ── Prayer name ───────────────────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [prayerColor, prayerColor.withOpacity(0.65)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'صلاة $prayerName',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lateef',
                ),
              ),
            ),

            SizedBox(height: 6.w),

            // ── Countdown: hours + minutes ────────────────────────────────
            Text(
              timeLeftText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: prayerColor,
                fontFamily: 'Lateef',
              ),
            ),

            // ── Seconds badge ─────────────────────────────────────────────
            if (hours == 0)
              Padding(
                padding: EdgeInsets.only(top: 4.w),
                child: _SecondsBadge(seconds: seconds, color: prayerColor),
              ),

            SizedBox(height: 14.w),

            // ── Progress arc ──────────────────────────────────────────────
            _ProgressArc(
              progress: progress,
              color: prayerColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Estimates the full interval from the previous prayer to [nextPrayer].
  static int _estimateTotalSeconds(
      PrayerTimes prayers, Prayer nextPrayer, DateTime nextTime) {
    // Find the time of the prayer just before nextPrayer.
    DateTime? prevTime;
    switch (nextPrayer) {
      case Prayer.fajr:
        // Before Fajr → Isha of yesterday; approximate as 6 hours.
        prevTime = nextTime.subtract(const Duration(hours: 6));
        break;
      case Prayer.sunrise:
        prevTime = prayers.fajr;
        break;
      case Prayer.dhuhr:
        prevTime = prayers.sunrise;
        break;
      case Prayer.asr:
        prevTime = prayers.dhuhr;
        break;
      case Prayer.maghrib:
        prevTime = prayers.asr;
        break;
      case Prayer.isha:
        prevTime = prayers.maghrib;
        break;
      default:
        return 0;
    }
    return nextTime.difference(prevTime).inSeconds.clamp(1, 999999);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing icon – isolated so it's the only thing that rebuilds on pulse ticks.
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AnimationController pulseController;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final v = pulseController.value;
        return Transform.scale(
          scale: 1.0 + v * 0.08,
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3 + v * 0.25),
                  blurRadius: 20 + 12 * v,
                  spreadRadius: 2 * v,
                ),
              ],
            ),
            child: Icon(icon, size: 40.w, color: color),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seconds badge – ticking sub-display when less than an hour remains.
// ─────────────────────────────────────────────────────────────────────────────

class _SecondsBadge extends StatelessWidget {
  final int seconds;
  final Color color;

  const _SecondsBadge({required this.seconds, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        'و ${convertToArabicNumber(seconds)} ثانية',
        style: TextStyle(
          fontSize: 14.sp,
          color: color.withOpacity(0.8),
          fontFamily: 'Lateef',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress arc – thin arc at the bottom of the card showing elapsed fraction.
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressArc extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _ProgressArc({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.r),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6.w,
        ),
      ),
    );
  }
}
