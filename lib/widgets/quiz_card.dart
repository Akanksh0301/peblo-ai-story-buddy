import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';

/// Renders a [QuizModel] like a little game.
///
/// Still fully dynamic: it iterates [QuizModel.options], so 3/4/5/N options and
/// any question text render with zero code changes. Correctness is decided by
/// the model, never by index — reordering options stays safe.
class QuizCard extends ConsumerWidget {
  const QuizCard({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answer = ref.watch(quizAnswerProvider);
    final controller = ref.read(quizAnswerProvider.notifier);

    // Side-effect: haptics fire exactly when a NEW wrong attempt is recorded —
    // a pure reaction to state, kept out of the tap handler.
    ref.listen<QuizAnswerState>(quizAnswerProvider, (prev, next) {
      if (next.wrongAttempts > (prev?.wrongAttempts ?? 0)) {
        HapticFeedback.mediumImpact();
      }
    });

    final encouragement = AppStrings.encouragements[
        (answer.wrongAttempts - 1).clamp(0, AppStrings.encouragements.length - 1)];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sunnyYellow.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🎯  Quiz Time!',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB8860B))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quiz.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic options. Shake replays whenever wrongAttempts changes,
          // because the ValueKey changes and flutter_animate re-runs the effect.
          Animate(
            key: ValueKey(answer.wrongAttempts),
            effects: answer.isWrong
                ? const [ShakeEffect(duration: Duration(milliseconds: 450), hz: 6)]
                : const [],
            child: Column(
              children: [
                for (var i = 0; i < quiz.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      index: i,
                      label: quiz.options[i],
                      state: answer,
                      isAnswer: quiz.answer == quiz.options[i],
                      onTap: answer.isCorrect
                          ? null
                          : () => controller.submit(quiz, quiz.options[i]),
                    ),
                  ),
              ],
            ),
          ),

          if (answer.isWrong)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.wrongCoral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🤗', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      encouragement,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD9663A),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

/// One tappable answer with its own press feedback (scale) and a letter chip.
class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.index,
    required this.label,
    required this.state,
    required this.isAnswer,
    required this.onTap,
  });

  final int index;
  final String label;
  final QuizAnswerState state;
  final bool isAnswer;
  final VoidCallback? onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _pressed = false;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isSelected = state.selected == widget.label;
    final isCorrectPick = state.isCorrect && widget.isAnswer;
    final isWrongPick = state.isWrong && isSelected;

    Color border = const Color(0xFFE6E9F5);
    Color bg = const Color(0xFFFBFBFF);
    Color fg = AppColors.textDark;
    Color chipBg = AppColors.primaryPurple.withValues(alpha: 0.12);
    Color chipFg = AppColors.primaryPurple;
    IconData? trailing;

    if (isCorrectPick) {
      border = AppColors.successGreen;
      bg = AppColors.successGreen.withValues(alpha: 0.12);
      fg = const Color(0xFF2E7D32);
      chipBg = AppColors.successGreen;
      chipFg = Colors.white;
      trailing = Icons.check_circle_rounded;
    } else if (isWrongPick) {
      border = AppColors.wrongCoral;
      bg = AppColors.wrongCoral.withValues(alpha: 0.10);
      fg = const Color(0xFFD9663A);
      chipBg = AppColors.wrongCoral;
      chipFg = Colors.white;
      trailing = Icons.replay_rounded;
    }

    Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 66, // big, game-like tap target
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 2.5),
      ),
      child: Row(
        children: [
          // Letter chip
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _letters[widget.index % _letters.length],
              style: TextStyle(
                  color: chipFg, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
          if (trailing != null) Icon(trailing, color: chipBg, size: 26),
        ],
      ),
    );

    // Quick celebratory pop on the correct tile.
    if (isCorrectPick) {
      tile = tile
          .animate()
          .scaleXY(begin: 1.0, end: 1.04, duration: 180.ms, curve: Curves.easeOut)
          .then()
          .scaleXY(begin: 1.04, end: 1.0, duration: 180.ms);
    }

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown:
            widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
        onTapCancel:
            widget.onTap != null ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: tile,
        ),
      ),
    );
  }
}
