import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_constants.dart';
import '../themes/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class QiblaCompass extends StatefulWidget {
  final VoidCallback? init;
  final double? heading;

  /// Pre-computed rotation angle in radians: `(qiblaDirection - heading) * π/180`
  final double? headingAngle;
  final double? qiblaDirection;

  /// Distance to the Kaaba in kilometres (optional, shown when provided).
  final double? distanceKm;

  final bool aligned;
  final bool loading;
  final bool error;

  const QiblaCompass({
    super.key,
    required this.init,
    required this.heading,
    required this.headingAngle,
    required this.qiblaDirection,
    this.distanceKm,
    required this.aligned,
    required this.loading,
    required this.error,
  });

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _QiblaCompassState extends State<QiblaCompass>
    with TickerProviderStateMixin {
  // ── Needle animation ──────────────────────────────────────────────────────
  late final AnimationController _needleController;
  late Animation<double> _needleAnimation;
  double _previousAngle = 0;

  // ── Alignment glow / pulse animation ─────────────────────────────────────
  late final AnimationController _glowController;

  // ── Direction cache ───────────────────────────────────────────────────────
  late String _headingLabel;
  late String _headingDirection;
  late String _qiblaLabel;
  late String _qiblaDirectionLabel;

  @override
  void initState() {
    super.initState();

    _previousAngle = widget.headingAngle ?? 0;

    _needleController = AnimationController(
      vsync: this,
      duration: AppConstants.durationNormal,
    );
    _needleAnimation = AlwaysStoppedAnimation(_previousAngle);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _updateCachedLabels();
  }

  @override
  void didUpdateWidget(QiblaCompass old) {
    super.didUpdateWidget(old);

    if (widget.headingAngle != null && widget.headingAngle != _previousAngle) {
      final newAngle = widget.headingAngle!;
      _needleAnimation = Tween<double>(begin: _previousAngle, end: newAngle)
          .animate(CurvedAnimation(
        parent: _needleController,
        curve: Curves.easeOutCubic,
      ));
      _needleController
        ..reset()
        ..forward();
      _previousAngle = newAngle;
    }

    if (widget.heading != old.heading ||
        widget.qiblaDirection != old.qiblaDirection) {
      _updateCachedLabels();
    }
  }

  @override
  void dispose() {
    _needleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _updateCachedLabels() {
    if (widget.heading != null) {
      _headingLabel = _formatAngle(widget.heading!);
      _headingDirection = _getDirection(widget.heading!);
    }
    if (widget.qiblaDirection != null) {
      _qiblaLabel = _formatAngle(widget.qiblaDirection!);
      _qiblaDirectionLabel = _getDirection(widget.qiblaDirection!);
    }
  }

  static String _formatAngle(double angle) {
    final n = ((angle % 360) + 360) % 360;
    return '${n.toStringAsFixed(1)}°';
  }

  static String _getDirection(double angle) {
    final n = ((angle % 360) + 360) % 360;
    if (n < 45 || n >= 315) return 'شمال';
    if (n < 135) return 'شرق';
    if (n < 225) return 'جنوب';
    return 'غرب';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const _LoadingState();
    if (widget.error) return _ErrorState(onRetry: widget.init);

    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            context.gapLG,

            // ── Compass ─────────────────────────────────────────────────────
            RepaintBoundary(
              child: _AnimatedCompassNeedle(
                animation: _needleAnimation,
                glowAnimation: _glowController,
                scheme: scheme,
                aligned: widget.aligned,
              ),
            ),

            context.gapXL,

            // ── Status indicator ────────────────────────────────────────────
            _StatusIndicator(
              aligned: widget.aligned,
              glowController: _glowController,
            ),

            context.gapLG,

            // ── Info cards (only when data is available) ─────────────────────
            if (widget.heading != null && widget.qiblaDirection != null) ...[
              _AngleInfoSection(
                scheme: scheme,
                headingLabel: _headingLabel,
                headingDirection: _headingDirection,
                qiblaLabel: _qiblaLabel,
                qiblaDirectionLabel: _qiblaDirectionLabel,
                distanceKm: widget.distanceKm,
              ),
            ],

            context.gapLG,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56.w,
            height: 56.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: scheme.secondary,
            ),
          ),
          SizedBox(height: 20.w),
          Text(
            'جاري تحديد الاتجاه...',
            style: TextStyle(
              fontSize: 16.sp,
              color: scheme.secondary,
              fontFamily: 'Lateef',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated needle wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCompassNeedle extends StatelessWidget {
  final Animation<double> animation;
  final AnimationController glowAnimation;
  final ColorScheme scheme;
  final bool aligned;

  const _AnimatedCompassNeedle({
    required this.animation,
    required this.glowAnimation,
    required this.scheme,
    required this.aligned,
  });

  @override
  Widget build(BuildContext context) {
    // Outer glow ring pulses only when aligned.
    return AnimatedBuilder(
      animation: Listenable.merge([animation, glowAnimation]),
      builder: (_, __) {
        final glowOpacity = aligned ? (0.25 + glowAnimation.value * 0.35) : 0.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow backdrop (aligned only)
            if (aligned)
              Container(
                width: 296.w,
                height: 296.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(glowOpacity),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            CustomPaint(
              size: Size(280.w, 280.w),
              painter: _CompassPainter(
                angle: animation.value,
                scheme: scheme,
                aligned: aligned,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter – single-pass canvas draw
// ─────────────────────────────────────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  final double angle;
  final ColorScheme scheme;
  final bool aligned;

  const _CompassPainter({
    required this.angle,
    required this.scheme,
    required this.aligned,
  });

  static const _cardinals = ['ش', 'ق', 'ج', 'غ'];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 6;

    // ── Outer gradient ring ────────────────────────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          scheme.secondary,
          scheme.secondary.withOpacity(0.3),
          scheme.secondary,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // ── Inner decorative ring ──────────────────────────────────────────────
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = scheme.secondary.withOpacity(0.15);
    canvas.drawCircle(Offset(cx, cy), r - 20, innerRingPaint);

    // ── Tick marks ─────────────────────────────────────────────────────────
    final tickPaint = Paint()..strokeWidth = 1;
    for (int i = 0; i < 72; i++) {
      final theta = i * math.pi / 36;
      final isCardinal = i % 18 == 0; // every 90°
      final isMajor = i % 9 == 0; // every 45°

      tickPaint.color = isCardinal
          ? scheme.secondary.withOpacity(0.9)
          : scheme.secondary.withOpacity(isMajor ? 0.5 : 0.25);
      tickPaint.strokeWidth = isCardinal ? 2 : 1;

      final inner = r -
          (isCardinal
              ? 18
              : isMajor
                  ? 12
                  : 7);
      canvas.drawLine(
        Offset(cx + r * math.cos(theta), cy + r * math.sin(theta)),
        Offset(cx + inner * math.cos(theta), cy + inner * math.sin(theta)),
        tickPaint,
      );
    }

    // ── Cardinal labels ────────────────────────────────────────────────────
    final labelStyle = TextStyle(
      // wordSpacing: 10,
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: scheme.secondary,
    );
    // Positions tuned so each glyph is centred on its axis.
    final offsets = [
      Offset(cx - 24.w, 12),
      Offset(size.width - 22.w, cy - 36.w),
      Offset(cx - 24.w, size.height - 28.w),
      Offset(12, cy + 36.w),
    ];
    for (int i = 0; i < 4; i++) {
      _drawText(canvas, _cardinals[i], offsets[i], labelStyle);
    }

    // ── Needle shadow ──────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(cx + 2, cy + 3);
    canvas.rotate(angle);
    _drawNeedle(canvas, r * 0.65, Colors.black26, r * 0.18);
    canvas.restore();

    // ── Needle ────────────────────────────────────────────────────────────
    final needleColor = aligned ? scheme.primary : scheme.secondary;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    _drawNeedle(canvas, r * 0.65, needleColor, r * 0.18);

    canvas.restore();

    // ── Centre hub ────────────────────────────────────────────────────────
    final hubPaint = Paint()..style = PaintingStyle.fill;

    // Outer hub ring
    hubPaint.color = needleColor;
    canvas.drawCircle(Offset(cx, cy), 9, hubPaint);

    // Inner white dot
    hubPaint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 4.5, hubPaint);
  }

  void _drawNeedle(Canvas canvas, double length, Color color, double tailLen) {
    final path = Path()
      ..moveTo(0, -length) // tip
      ..lineTo(-7, 0)
      ..lineTo(0, tailLen) // tail
      ..lineTo(7, 0)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.angle != angle ||
      old.scheme.secondary != scheme.secondary ||
      old.aligned != aligned;
}

// ─────────────────────────────────────────────────────────────────────────────
// Status indicator with pulsing glow ring when aligned
// ─────────────────────────────────────────────────────────────────────────────

class _StatusIndicator extends StatelessWidget {
  final bool aligned;
  final AnimationController glowController;

  const _StatusIndicator({
    required this.aligned,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = aligned ? scheme.primary : scheme.error;

    return AnimatedBuilder(
      animation: glowController,
      builder: (_, child) {
        final glowRadius = aligned ? (8.0 + glowController.value * 12.0) : 0.0;
        final glowOpacity = aligned ? (0.2 + glowController.value * 0.25) : 0.0;
        return AnimatedContainer(
          duration: AppConstants.durationNormal,
          padding: context.paddingLG,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
            borderRadius: context.radiusLG,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(glowOpacity),
                blurRadius: glowRadius,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppConstants.durationFast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              aligned ? Icons.mosque_rounded : Icons.rotate_right_rounded,
              key: ValueKey(aligned),
              color: aligned
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              size: 24.w,
            ),
          ),
          context.gapSM,
          AnimatedSwitcher(
            duration: AppConstants.durationFast,
            child: Text(
              aligned ? 'محاذي مع القبلة ✓' : 'قم بتدوير الهاتف',
              key: ValueKey(aligned),
              style: TextStyle(
                fontSize: 16.sp,
                color: aligned
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
                fontFamily: 'Lateef',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Angle + distance info section – two cards side by side, distance below
// ─────────────────────────────────────────────────────────────────────────────

class _AngleInfoSection extends StatelessWidget {
  final ColorScheme scheme;
  final String headingLabel;
  final String headingDirection;
  final String qiblaLabel;
  final String qiblaDirectionLabel;
  final double? distanceKm;

  const _AngleInfoSection({
    required this.scheme,
    required this.headingLabel,
    required this.headingDirection,
    required this.qiblaLabel,
    required this.qiblaDirectionLabel,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.paddingLG,
      child: Column(
        children: [
          // Heading + Qibla side by side
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  scheme: scheme,
                  label: 'البوصلة',
                  value: headingLabel,
                  subValue: headingDirection,
                  icon: Icons.explore_rounded,
                  isQibla: false,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _InfoCard(
                  scheme: scheme,
                  label: 'القبلة',
                  value: qiblaLabel,
                  subValue: qiblaDirectionLabel,
                  icon: Icons.location_on_rounded,
                  isQibla: true,
                ),
              ),
            ],
          ),

          // Distance card (full width, shown only when available)
          if (distanceKm != null) ...[
            SizedBox(height: 12.w),
            _DistanceCard(scheme: scheme, distanceKm: distanceKm!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual info card – compact vertical layout
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final bool isQibla;

  const _InfoCard({
    required this.scheme,
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    this.isQibla = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isQibla ? scheme.secondary : scheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        borderRadius: context.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.w),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 13.sp,
              color: color.withOpacity(0.65),
              fontFamily: 'Lateef',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Distance card – full-width strip below the two info cards
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceCard extends StatelessWidget {
  final ColorScheme scheme;
  final double distanceKm;

  const _DistanceCard({required this.scheme, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final color = scheme.tertiary;
    final distStr = distanceKm >= 1000
        ? '${(distanceKm / 1000).toStringAsFixed(2)} ألف كم'
        : '${distanceKm.toStringAsFixed(1)} كم';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: context.radiusMD,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.social_distance_rounded, color: color, size: 20.w),
          SizedBox(width: 10.w),
          Text(
            'المسافة إلى الكعبة:  ',
            style: TextStyle(
              fontSize: 14.sp,
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            distStr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Lateef',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: context.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  color: errorColor, size: 48.sp),
            ),
            SizedBox(height: 20.w),
            Text(
              'تعذر تحديد اتجاه القبلة',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: errorColor,
                fontFamily: 'Lateef',
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              'تحقق من صلاحيات الموقع والبوصلة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                fontFamily: 'Lateef',
              ),
            ),
            SizedBox(height: 28.w),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
