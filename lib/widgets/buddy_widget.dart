import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/buddy_state.dart';

/// "Pip" — the AI Buddy and emotional centre of the experience.
///
/// Drawn entirely with [CustomPaint] (no image assets) so it is tiny in memory
/// and reacts instantly to mood. It feels *alive* through four layered motions,
/// each cheap:
///   * breathing  — slow scale pulse (always)
///   * floating   — gentle vertical drift (always)
///   * blinking   — quick eye close on a randomised timer
///   * celebrating— one-shot elastic bounce when entering [BuddyState.success]
///
/// Performance: one `RepaintBoundary` (added here) isolates all of this motion
/// from the rest of the tree, and a single merged [Listenable] drives one
/// `AnimatedBuilder` rather than nesting several.
class BuddyWidget extends StatefulWidget {
  const BuddyWidget({
    super.key,
    required this.state,
    this.size = 200,
  });

  final BuddyState state;
  final double size;

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget>
    with TickerProviderStateMixin {
  late final AnimationController _idle; // breathing + floating (loops)
  late final AnimationController _blink; // quick eye blink
  late final AnimationController _celebrate; // success bounce (one-shot)
  late final Animation<double> _bounce;
  final _rng = math.Random();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bounce = CurvedAnimation(parent: _celebrate, curve: Curves.elasticOut);

    _scheduleBlink();
    if (widget.state == BuddyState.success) _celebrate.forward(from: 0);
  }

  /// Self-scheduling blink loop with human-feeling random gaps.
  Future<void> _scheduleBlink() async {
    while (!_disposed) {
      await Future<void>.delayed(
        Duration(milliseconds: 1800 + _rng.nextInt(2600)),
      );
      if (_disposed) return;
      await _blink.forward();
      if (_disposed) return;
      await _blink.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant BuddyWidget old) {
    super.didUpdateWidget(old);
    // Fire the celebration bounce only on the transition INTO success.
    if (widget.state == BuddyState.success &&
        old.state != BuddyState.success) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _idle.dispose();
    _blink.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size + 24,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _blink, _celebrate]),
          builder: (context, _) {
            final t = _idle.value * 2 * math.pi;
            final floatY = math.sin(t) * 7; // drift up/down
            final breathe = 1 + math.sin(t) * 0.018; // subtle scale
            final pop = 1 + _bounce.value * 0.16; // success bounce
            final eyeOpen = 1 - _blink.value; // 1 open, 0 closed

            return Transform.translate(
              offset: Offset(0, floatY),
              child: Transform.scale(
                scale: breathe * pop,
                child: CustomPaint(
                  painter: _BuddyPainter(
                    state: widget.state,
                    pulse: (math.sin(t) + 1) / 2,
                    eyeOpen: eyeOpen,
                    bounce: _bounce.value,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({
    required this.state,
    required this.pulse,
    required this.eyeOpen,
    required this.bounce,
  });

  final BuddyState state;
  final double pulse;
  final double eyeOpen; // 1 open .. 0 closed
  final double bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.width; // keep face square; extra height is breathing room
    final cx = w / 2;

    // --- Soft glowing halo behind Pip (depth) --------------------------
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.skyBlue.withValues(alpha: 0.22),
          AppColors.skyBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, h * 0.5), radius: w * 0.55));
    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.55, haloPaint);

    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.60, h * 0.54),
      Radius.circular(w * 0.24),
    );

    // --- Antenna -------------------------------------------------------
    final antennaPaint = Paint()
      ..color = AppColors.primaryPurple
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, h * 0.22), Offset(cx, h * 0.11), antennaPaint);
    final glow = Color.lerp(AppColors.sunnyYellow, AppColors.skyBlue, pulse)!;
    // glow ring
    canvas.drawCircle(Offset(cx, h * 0.095), w * 0.075,
        Paint()..color = glow.withValues(alpha: 0.30));
    canvas.drawCircle(Offset(cx, h * 0.095), w * 0.048 + pulse * w * 0.012,
        Paint()..color = glow);

    // --- Head with shadow + gradient ----------------------------------
    canvas.drawRRect(
      headRect.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x336C63FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.skyBlue, AppColors.primaryPurple],
        ).createShader(headRect.outerRect),
    );
    // glossy highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.27, w * 0.34, h * 0.10),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // ears / bolts
    final boltPaint = Paint()..color = AppColors.primaryPurple;
    canvas.drawCircle(Offset(w * 0.18, h * 0.49), w * 0.045, boltPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.49), w * 0.045, boltPaint);

    // --- Face screen ---------------------------------------------------
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.29, h * 0.32, w * 0.42, h * 0.32),
      Radius.circular(w * 0.13),
    );
    canvas.drawRRect(faceRect, Paint()..color = AppColors.textDark);

    _drawEyes(canvas, w, h);
    _drawMouth(canvas, w, h);

    if (state == BuddyState.success) {
      final cheek = Paint()..color = AppColors.wrongCoral.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(w * 0.34, h * 0.55), w * 0.032, cheek);
      canvas.drawCircle(Offset(w * 0.66, h * 0.55), w * 0.032, cheek);
    }

    // --- Body hint -----------------------------------------------------
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.74, w * 0.36, h * 0.12),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = AppColors.primaryPurple,
    );
  }

  void _drawEyes(Canvas canvas, double w, double h) {
    final left = Offset(w * 0.41, h * 0.44);
    final right = Offset(w * 0.59, h * 0.44);
    final r = w * 0.052;
    final eye = Paint()..color = AppColors.sunnyYellow;

    // Closed-eye line (used for blink, listening, success arcs handled below).
    void closedLine(Offset c) {
      final p = Paint()
        ..color = AppColors.sunnyYellow
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), p);
    }

    // Happy upward arc ^ (success).
    void happyArc(Offset c) {
      final p = Paint()
        ..color = AppColors.sunnyYellow
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final rect = Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.8);
      canvas.drawArc(rect, 0.12 * math.pi, 0.76 * math.pi, false, p);
    }

    if (state == BuddyState.success) {
      happyArc(left);
      happyArc(right);
      return;
    }
    if (state == BuddyState.listening) {
      closedLine(left);
      closedLine(right);
      return;
    }

    // idle / narrating: round eyes that blink (squash vertically as eyeOpen→0).
    if (eyeOpen < 0.18) {
      closedLine(left);
      closedLine(right);
      return;
    }
    final ry = r * eyeOpen;
    canvas.drawOval(Rect.fromCenter(center: left, width: r * 2, height: ry * 2), eye);
    canvas.drawOval(Rect.fromCenter(center: right, width: r * 2, height: ry * 2), eye);
    final spark = Paint()..color = Colors.white;
    canvas.drawCircle(left.translate(-r * 0.3, -ry * 0.3), r * 0.28, spark);
    canvas.drawCircle(right.translate(-r * 0.3, -ry * 0.3), r * 0.28, spark);
  }

  void _drawMouth(Canvas canvas, double w, double h) {
    final center = Offset(w * 0.50, h * 0.56);
    final p = Paint()
      ..color = AppColors.sunnyYellow
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (state) {
      case BuddyState.idle:
        _smile(canvas, center, w * 0.10, p, depth: 0.35);
      case BuddyState.listening:
        canvas.drawCircle(center, w * 0.028, Paint()..color = AppColors.sunnyYellow);
      case BuddyState.narrating:
        // mouth "talks": opening size oscillates with the breathing phase.
        final open = 0.06 + pulse * 0.06;
        canvas.drawOval(
          Rect.fromCenter(center: center, width: w * 0.12, height: w * open),
          Paint()..color = AppColors.sunnyYellow,
        );
      case BuddyState.success:
        _smile(canvas, center, w * 0.15, p, depth: 0.7);
    }
  }

  void _smile(Canvas canvas, Offset c, double radius, Paint p,
      {required double depth}) {
    final rect = Rect.fromCenter(
      center: c,
      width: radius * 2,
      height: radius * 2 * depth + radius,
    );
    canvas.drawArc(rect, 0.15 * math.pi, 0.7 * math.pi, false, p);
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter old) =>
      old.state != state ||
      old.pulse != pulse ||
      old.eyeOpen != eyeOpen ||
      old.bounce != bounce;
}
