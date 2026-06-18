import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/quiz_provider.dart';
import '../providers/tts_provider.dart';
import '../utils/audio_state.dart';
import '../utils/buddy_state.dart';
import '../widgets/animated_button.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/quiz_card.dart';
import '../widgets/story_card.dart';
import '../widgets/success_card.dart';

/// The single screen. A [ConsumerWidget] (no local mutable state) that composes
/// small widgets and *derives* what to show from providers. Mobile-first: the
/// content column is capped at 460px and centred, so it stays a tight, phone-
/// shaped experience even if opened on a wide screen — no dead empty space.
class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  BuddyState _buddyState(AudioState audio, bool correct) {
    if (correct) return BuddyState.success;
    if (audio.isSpeaking) return BuddyState.narrating;
    if (audio.isLoading) return BuddyState.listening;
    return BuddyState.idle;
  }

  String _hint(BuddyState s) => switch (s) {
        BuddyState.idle => AppStrings.buddyIdle,
        BuddyState.listening => AppStrings.buddyListening,
        BuddyState.narrating => AppStrings.buddyNarrating,
        BuddyState.success => AppStrings.buddySuccess,
      };

  void _readStory(WidgetRef ref) {
    ref.read(quizAnswerProvider.notifier).reset();
    ref.read(ttsControllerProvider.notifier).narrate(AppStrings.storyText);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(ttsControllerProvider);
    final quizAsync = ref.watch(quizProvider);
    // .select keeps this widget from rebuilding on every answer-state change —
    // it only cares whether the answer is now correct.
    final correct = ref.watch(quizAnswerProvider.select((s) => s.isCorrect));
    final buddy = _buddyState(audio, correct);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Header(),
                    const SizedBox(height: 2),
                    Center(child: BuddyWidget(state: buddy, size: 210)),
                    _SpeechBubble(text: _hint(buddy)),
                    const SizedBox(height: 16),
                    StoryCard(
                      title: AppStrings.storyTitle,
                      body: AppStrings.storyText,
                      highlight: audio.isSpeaking,
                    ),
                    const SizedBox(height: 16),
                    _ControlArea(audio: audio, onRead: () => _readStory(ref)),
                    if (audio.isCompleted) ...[
                      const SizedBox(height: 16),
                      quizAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const _QuizLoadError(),
                        data: (quiz) => Column(
                          children: [
                            QuizCard(quiz: quiz)
                                .animate()
                                .fadeIn(duration: 420.ms)
                                .slideY(
                                  begin: 0.22,
                                  end: 0,
                                  duration: 480.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                            if (correct) ...[
                              const SizedBox(height: 16),
                              SuccessCard(onReplay: () => _readStory(ref)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('✨', style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Text(
          AppStrings.appTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlArea extends StatelessWidget {
  const _ControlArea({required this.audio, required this.onRead});
  final AudioState audio;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    if (audio.isError) return _ErrorCard(onRetry: onRead);

    return Column(
      children: [
        AnimatedButton(
          label: audio.isSpeaking ? AppStrings.reading : AppStrings.readStory,
          icon: Icons.volume_up_rounded,
          isLoading: audio.isLoading,
          pulse: audio.isIdle, // gently invites the first tap
          onPressed: audio.canStart ? onRead : null,
        ),
        if (audio.isLoading) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.loadingMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 700.ms),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.wrongCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.wrongCoral, width: 2),
      ),
      child: Column(
        children: [
          const Text('😅', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          const Text(
            AppStrings.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedButton(
            label: AppStrings.retry,
            icon: Icons.refresh_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.wrongCoral, Color(0xFFFF6B6B)],
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _QuizLoadError extends StatelessWidget {
  const _QuizLoadError();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wrongCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        AppStrings.quizLoadError,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
