import 'package:flutter_test/flutter_test.dart';
import 'package:story_buddy/models/quiz_model.dart';

void main() {
  group('QuizModel.fromJson', () {
    test('parses a valid 4-option quiz', () {
      final q = QuizModel.fromJson({
        'question': 'What colour was the gear?',
        'options': ['Red', 'Green', 'Blue', 'Yellow'],
        'answer': 'Blue',
      });
      expect(q.options.length, 4);
      expect(q.isCorrect('Blue'), isTrue);
      expect(q.isCorrect('Red'), isFalse);
    });

    test('supports any option count (3 and 5)', () {
      final three = QuizModel.fromJson({
        'question': 'Pick one',
        'options': ['A', 'B', 'C'],
        'answer': 'B',
      });
      final five = QuizModel.fromJson({
        'question': 'Pick one',
        'options': ['A', 'B', 'C', 'D', 'E'],
        'answer': 'E',
      });
      expect(three.options.length, 3);
      expect(five.options.length, 5);
    });

    test('throws when answer is not among options', () {
      expect(
        () => QuizModel.fromJson({
          'question': 'Q',
          'options': ['A', 'B'],
          'answer': 'Z',
        }),
        throwsFormatException,
      );
    });

    test('throws on malformed payload', () {
      expect(
        () => QuizModel.fromJson({'question': '', 'options': [], 'answer': ''}),
        throwsFormatException,
      );
    });
  });
}
