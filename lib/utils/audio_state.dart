/// Lifecycle of the Text-To-Speech narration.
///
/// The quiz is gated on [completed], so this enum is the single source of
/// truth that drives both the button and the quiz reveal.
enum AudioState {
  idle,
  loading,
  speaking,
  completed,
  error;

  bool get isIdle => this == AudioState.idle;
  bool get isLoading => this == AudioState.loading;
  bool get isSpeaking => this == AudioState.speaking;
  bool get isCompleted => this == AudioState.completed;
  bool get isError => this == AudioState.error;

  /// Button is tappable only when we are not mid-flight.
  bool get canStart =>
      this == AudioState.idle ||
      this == AudioState.completed ||
      this == AudioState.error;
}
