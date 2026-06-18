import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../models/quiz_model.dart';

/// Loads and parses the quiz from the bundled JSON asset.
///
/// Returns a [Future] so the UI can show loading / error states declaratively
/// via `AsyncValue`. In a real product this provider would point at an API or
/// the Peblo content service — the widgets would not change at all.
final quizProvider = FutureProvider<QuizModel>((ref) async {
  final raw = await rootBundle.loadString('assets/quiz.json');
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return QuizModel.fromJson(decoded); // throws FormatException on bad data
});

/// Result of the current attempt.
enum AnswerStatus { unanswered, wrong, correct }

@immutable
class QuizAnswerState {
  const QuizAnswerState({
    this.status = AnswerStatus.unanswered,
    this.selected,
    this.wrongAttempts = 0,
  });

  final AnswerStatus status;
  final String? selected;

  /// Incremented on every wrong answer. The quiz card watches this value and
  /// re-runs the shake animation each time it changes — a clean way to retrigger
  /// an animation without imperative animation controllers in the UI.
  final int wrongAttempts;

  bool get isCorrect => status == AnswerStatus.correct;
  bool get isWrong => status == AnswerStatus.wrong;

  QuizAnswerState copyWith({
    AnswerStatus? status,
    String? selected,
    int? wrongAttempts,
  }) {
    return QuizAnswerState(
      status: status ?? this.status,
      selected: selected ?? this.selected,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

final quizAnswerProvider =
    NotifierProvider<QuizAnswerController, QuizAnswerState>(
  QuizAnswerController.new,
);

class QuizAnswerController extends Notifier<QuizAnswerState> {
  @override
  QuizAnswerState build() => const QuizAnswerState();

  /// Evaluate [option] against [quiz] and update state.
  void submit(QuizModel quiz, String option) {
    // Ignore taps once the child has already won.
    if (state.isCorrect) return;

    if (quiz.isCorrect(option)) {
      state = state.copyWith(status: AnswerStatus.correct, selected: option);
    } else {
      state = state.copyWith(
        status: AnswerStatus.wrong,
        selected: option,
        wrongAttempts: state.wrongAttempts + 1,
      );
    }
  }

  void reset() => state = const QuizAnswerState();
}
