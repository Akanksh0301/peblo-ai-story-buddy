import 'package:flutter/foundation.dart';

/// Immutable representation of a single quiz question.
///
/// Built entirely from JSON so the question, the number of options, and the
/// answer can all change without touching a single line of UI code. The
/// renderer iterates [options], so 3, 4, 5 (or N) options "just work".
@immutable
class QuizModel {
  const QuizModel({
    required this.question,
    required this.options,
    required this.answer,
  });

  final String question;
  final List<String> options;
  final String answer;

  /// Parses a quiz from a decoded JSON map.
  ///
  /// Throws [FormatException] on malformed data so callers can surface a
  /// friendly error rather than crashing on a bad cast.
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final question = json['question'];
    final rawOptions = json['options'];
    final answer = json['answer'];

    if (question is! String || question.trim().isEmpty) {
      throw const FormatException('Quiz "question" missing or invalid.');
    }
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw const FormatException('Quiz "options" missing or empty.');
    }
    if (answer is! String || answer.trim().isEmpty) {
      throw const FormatException('Quiz "answer" missing or invalid.');
    }

    final options = rawOptions.map((e) => e.toString()).toList(growable: false);

    if (!options.contains(answer)) {
      throw const FormatException('Quiz "answer" is not one of the options.');
    }

    return QuizModel(
      question: question,
      options: options,
      answer: answer,
    );
  }

  /// True when [selected] matches the correct answer.
  bool isCorrect(String selected) => selected == answer;

  @override
  bool operator ==(Object other) =>
      other is QuizModel &&
      other.question == question &&
      listEquals(other.options, options) &&
      other.answer == answer;

  @override
  int get hashCode => Object.hash(question, Object.hashAll(options), answer);
}
