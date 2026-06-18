import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';
import '../constants/strings.dart';

/// Celebration shown on a correct answer: a big confetti burst, an achievement
/// badge that "earns" itself with an elastic pop, twinkling stars, and a replay
/// CTA so the loop feels rewarding rather than final.
///
/// Owns its [ConfettiController]; fires once on appear, disposed with the widget.
class SuccessCard extends StatefulWidget {
  const SuccessCard({super.key, this.onReplay});

  final VoidCallback? onReplay;

  @override
  State<SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<SuccessCard> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(seconds: 3))..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Bigger, fuller confetti burst.
        Positioned(
          top: -12,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.04,
            numberOfParticles: 30,
            maxBlastForce: 32,
            minBlastForce: 12,
            gravity: 0.28,
            shouldLoop: false,
            colors: AppColors.confettiColors,
          ),
        ),
        _card(),
      ],
    );
  }

  Widget _card() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        gradient: AppColors.successGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.liftShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _badge(),
          const SizedBox(height: 16),
          const Text(
            AppStrings.successTitle,
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.successMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (widget.onReplay != null) ...[
            const SizedBox(height: 18),
            _replayButton(),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 480.ms,
          curve: Curves.elasticOut,
        );
  }

  /// Achievement medal: a star that pops in, ringed by twinkling stars.
  Widget _badge() {
    return SizedBox(
      height: 110,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final star in _twinkles) _twinkle(star),
          // Medal
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 44)),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                delay: 150.ms,
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .rotate(begin: -0.1, end: 0, duration: 600.ms),
          // Ribbon label
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.sunnyYellow,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: const Text(
                AppStrings.successBadge,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
          ),
        ],
      ),
    );
  }

  // Positions (dx,dy) + size for the little twinkling stars around the medal.
  static const _twinkles = [
    Offset(-58, -28),
    Offset(58, -22),
    Offset(-48, 26),
    Offset(52, 30),
  ];

  Widget _twinkle(Offset pos) {
    return Positioned(
      left: 80 + pos.dx,
      top: 42 + pos.dy,
      child: const Text('✨', style: TextStyle(fontSize: 18))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 700.ms)
          .scaleXY(begin: 0.6, end: 1.1, duration: 700.ms),
    );
  }

  Widget _replayButton() {
    return GestureDetector(
      onTap: widget.onReplay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, color: AppColors.successGreen, size: 22),
            SizedBox(width: 8),
            Text(
              AppStrings.successCta,
              style: TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
