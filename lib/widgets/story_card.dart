import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';

/// Storybook-styled card. Pure UI: takes a title + body, knows nothing about
/// TTS or quiz state. The peach paper, decorative corner, and ribbon header
/// make it read like a page from a children's book rather than a form.
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.title,
    required this.body,
    this.highlight = false,
  });

  final String title;
  final String body;

  /// While narrating, a soft glowing border shows the page is "active".
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.storyPeach,
        borderRadius: BorderRadius.circular(26),
        boxShadow: highlight ? AppColors.liftShadow : AppColors.softShadow,
        border: Border.all(
          color: highlight ? AppColors.sunnyYellow : const Color(0xFFFFE6D2),
          width: highlight ? 3 : 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative corner illustration (sun peeking in).
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sunnyYellow.withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ribbon header
                  Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.storyInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: Color(0xFF6B5E45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 550.ms, curve: Curves.easeOut)
        .slideY(begin: 0.10, end: 0, duration: 550.ms, curve: Curves.easeOutCubic);
  }
}
