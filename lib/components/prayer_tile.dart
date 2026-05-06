import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/my_prayer.dart';
import '../services/prayer_service.dart';
import '../themes/app_constants.dart';
import '../themes/theme_extensions.dart';

class PrayerTile extends StatelessWidget {
  final MyPrayer prayer;
  final int index;
  final bool isCurrent;
  final bool isNext;
  final List<Animation<double>> tileAnimations;
  final AnimationController pulseController;

  const PrayerTile({
    super.key,
    required this.prayer,
    required this.index,
    required this.tileAnimations,
    required this.isCurrent,
    required this.isNext,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<PrayerService>();
    final color = service.getPrayerColor(prayer.prayer);
    final formattedTime = service.formatTime(prayer.time);

    // Reveal animation wraps only the card; AnimatedBuilder child optimisation
    // ensures the card subtree is built once and reused across animation frames.
    return AnimatedBuilder(
      animation: tileAnimations[index],
      builder: (_, child) {
        final t = tileAnimations[index].value;
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: _TileCard(
        prayer: prayer,
        color: color,
        formattedTime: formattedTime,
        isCurrent: isCurrent,
        isNext: isNext,
        pulseController: pulseController,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card body – separated so AnimatedBuilder child optimisation applies.
// ─────────────────────────────────────────────────────────────────────────────

class _TileCard extends StatelessWidget {
  final MyPrayer prayer;
  final Color color;
  final String formattedTime;
  final bool isCurrent;
  final bool isNext;
  final AnimationController pulseController;

  const _TileCard({
    required this.prayer,
    required this.color,
    required this.formattedTime,
    required this.isCurrent,
    required this.isNext,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isCurrent || isNext;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: context.radiusMD,
        child: InkWell(
          // Subtle press feedback – no navigation needed; purely tactile.
          onTap: isCurrent ? () => HapticFeedback.lightImpact() : null,
          borderRadius: context.radiusMD,
          splashColor: color.withOpacity(0.12),
          highlightColor: color.withOpacity(0.06),
          child: AnimatedContainer(
            duration: AppConstants.durationNormal,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlighted
                    ? [
                        color.withOpacity(isCurrent ? 0.20 : 0.09),
                        color.withOpacity(isCurrent ? 0.10 : 0.04),
                      ]
                    : [
                        Colors.grey.withOpacity(0.06),
                        Colors.grey.withOpacity(0.02),
                      ],
              ),
              borderRadius: context.radiusMD,
              border: Border.all(
                color: highlighted
                    ? color.withOpacity(isCurrent ? 0.50 : 0.22)
                    : Colors.grey.withOpacity(0.12),
                width: highlighted ? 2 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.w),
              child: Row(
                children: [
                  // ── Icon ─────────────────────────────────────────────────
                  _PrayerIcon(
                    icon: prayer.icon,
                    color: color,
                    highlighted: highlighted,
                    isCurrent: isCurrent,
                    pulseController: isCurrent ? pulseController : null,
                  ),

                  SizedBox(width: 14.w),

                  // ── Name + next label ─────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prayer.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: highlighted ? color : null,
                            fontFamily: 'Lateef',
                          ),
                        ),
                        if (isNext && !isCurrent)
                          Padding(
                            padding: EdgeInsets.only(top: 2.w),
                            child: Text(
                              'التالية',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: color.withOpacity(0.65),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Time badge ────────────────────────────────────────────
                  _TimeBadge(
                    time: formattedTime,
                    color: color,
                    highlighted: highlighted,
                    isCurrent: isCurrent,
                  ),

                  // ── Pulse dot (current only) ──────────────────────────────
                  if (isCurrent) ...[
                    SizedBox(width: 10.w),
                    _PulseDot(color: color, controller: pulseController),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon – glows when current; static when next/inactive.
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool highlighted;
  final bool isCurrent;
  // Null when not current (avoids attaching an AnimatedBuilder unnecessarily).
  final AnimationController? pulseController;

  const _PrayerIcon({
    required this.icon,
    required this.color,
    required this.highlighted,
    required this.isCurrent,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = BoxDecoration(
      color: highlighted
          ? color.withOpacity(isCurrent ? 0.22 : 0.10)
          : Colors.grey.withOpacity(0.10),
      shape: BoxShape.circle,
    );

    final iconWidget = AnimatedContainer(
      duration: AppConstants.durationNormal,
      padding: EdgeInsets.all(10.w),
      decoration: baseDecoration,
      child: Icon(
        icon,
        size: 22.w,
        color: highlighted ? color : Colors.grey[600],
      ),
    );

    if (!isCurrent || pulseController == null) return iconWidget;

    // Glow ring animates only for the current prayer.
    return AnimatedBuilder(
      animation: pulseController!,
      builder: (_, child) {
        final v = pulseController!.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15 + v * 0.25),
                blurRadius: 10 + 8 * v,
                spreadRadius: v * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: iconWidget,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time badge – shows "الآن" chip next to the time when current.
// ─────────────────────────────────────────────────────────────────────────────

class _TimeBadge extends StatelessWidget {
  final String time;
  final Color color;
  final bool highlighted;
  final bool isCurrent;

  const _TimeBadge({
    required this.time,
    required this.color,
    required this.highlighted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppConstants.durationNormal,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.w),
          decoration: BoxDecoration(
            color: highlighted
                ? color.withOpacity(isCurrent ? 0.16 : 0.07)
                : Colors.grey.withOpacity(0.08),
            borderRadius: context.radiusMD,
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: highlighted ? color : Colors.grey[700],
            ),
          ),
        ),
        // "Now" chip beneath the time, visible only for current prayer.
        // AnimatedSize(
        //   duration: AppConstants.durationFast,
        //   child: isCurrent
        //       ? Padding(
        //           padding: EdgeInsets.only(top: 4.w),
        //           child: Container(
        //             padding: EdgeInsets.symmetric(
        //                 horizontal: 8.w, vertical: 2.w),
        //             decoration: BoxDecoration(
        //               color: color,
        //               borderRadius: BorderRadius.circular(10.r),
        //             ),
        //             child: Text(
        //               'الآن',
        //               style: TextStyle(
        //                 fontSize: 10.sp,
        //                 color: Colors.white,
        //                 fontWeight: FontWeight.bold,
        //               ),
        //             ),
        //           ),
        //         )
        //       : const SizedBox.shrink(),
        // ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulse dot – only this widget rebuilds on every controller tick.
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _PulseDot({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final v = controller.value;
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.55),
                blurRadius: 6 + 8 * v,
                spreadRadius: 1.5 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}
