/// All user-facing copy. Centralised for consistent tone, easy proofing, and
/// future localisation. Tone rule for ages 5–12: warm, never punishing.
abstract final class AppStrings {
  static const String appTitle = 'AI Story Buddy';

  // Story
  static const String storyTitle = 'Pip and the Whispering Woods';
  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny "
      "blue gear in the Whispering Woods...";

  // Buttons
  static const String readStory = 'Read Me A Story';
  static const String reading = 'Pip is reading…';
  static const String retry = 'Try Again';

  // Loading
  static const String loadingMessage = 'Getting Pip ready to tell the story…';

  // Error
  static const String errorMessage =
      "Oops! I couldn't read the story. Let's try again!";
  static const String quizLoadError =
      "Oops! I couldn't load the quiz. Try reading the story again!";

  // Quiz feedback — rotated so it never feels repetitive or scolding.
  static const List<String> encouragements = [
    'So close! Give it another go!',
    'Good try! Think about the story 💭',
    'Almost there! You can do it!',
    'Nice guess! Try one more!',
  ];

  // Success
  static const String successTitle = 'Great Job!';
  static const String successMessage = 'Pip found his blue gear!';
  static const String successBadge = 'STORY STAR';
  static const String successCta = 'Read It Again';

  // Buddy speech hints
  static const String buddyIdle = "Tap below and I'll tell you a story!";
  static const String buddyListening = 'Hmm, let me get ready…';
  static const String buddyNarrating = 'Listen closely! 📖';
  static const String buddySuccess = 'Hooray! You found my gear! 🎉';
}
