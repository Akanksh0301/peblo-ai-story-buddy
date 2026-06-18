import 'package:flutter/material.dart';

/// Brand palette + design tokens for the Peblo "AI Story Buddy & Quiz".
///
/// One source of truth: a designer can re-skin the whole feature here. Tokens
/// (gradients, shadows, radii) live alongside colours so widgets stay free of
/// magic values.
abstract final class AppColors {
  // --- Brand ---------------------------------------------------------
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color skyBlue = Color(0xFF00C2FF);
  static const Color sunnyYellow = Color(0xFFFFD93D);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAFF);

  // --- Supporting ----------------------------------------------------
  static const Color textDark = Color(0xFF2D2A55);
  static const Color textSoft = Color(0xFF7B789E);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color wrongCoral = Color(0xFFFF8A5C); // softer than red = kinder
  static const Color storyPeach = Color(0xFFFFF3E9);
  static const Color storyInk = Color(0xFF5B4B8A);

  // --- Shadows (two tiers for layered depth) -------------------------
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x146C63FF), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> liftShadow = [
    BoxShadow(color: Color(0x1F6C63FF), blurRadius: 30, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // --- Gradients -----------------------------------------------------
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFF1FF), Color(0xFFF8FAFF), Color(0xFFFDF6FF)],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, primaryPurple],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5BD16A), successGreen, Color(0xFF2E9E55)],
  );

  static const List<Color> confettiColors = [
    primaryPurple,
    skyBlue,
    sunnyYellow,
    successGreen,
    wrongCoral,
  ];
}
