import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tts_service.dart';
import '../utils/audio_state.dart';

/// Owns the single [TtsService] instance and disposes it with the provider.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

/// Drives the narration lifecycle as an [AudioState] state machine.
///
/// The whole UI (button, loading message, quiz gate) reads from this single
/// notifier, so there is exactly one source of truth for "what is the audio
/// doing right now".
final ttsControllerProvider =
    NotifierProvider<TtsController, AudioState>(TtsController.new);

class TtsController extends Notifier<AudioState> {
  bool _initialised = false;

  @override
  AudioState build() => AudioState.idle;

  TtsService get _service => ref.read(ttsServiceProvider);

  /// Initialise the engine exactly once and wire its callbacks to state.
  Future<void> _ensureInit() async {
    if (_initialised) return;
    await _service.init(
      // Native handlers push the state machine forward. Because the quiz is
      // gated on AudioState.completed, the quiz can ONLY appear after the
      // completion callback fires — exactly as required.
      onStart: () => state = AudioState.speaking,
      onComplete: () => state = AudioState.completed,
      onError: (_) => state = AudioState.error,
    );
    _initialised = true;
  }

  /// Full narration flow: loading -> speaking -> completed (or error).
  Future<void> narrate(String text) async {
    state = AudioState.loading;
    try {
      await _ensureInit();
      // `speak` returns; final state is set by the completion handler. We do
      // not optimistically set `completed` here — we trust the callback so the
      // gate is genuinely tied to playback finishing.
      await _service.speak(text);
    } on TtsException {
      state = AudioState.error;
    } catch (_) {
      state = AudioState.error;
    }
  }

  /// Reset to idle so the user can re-trigger after success or error.
  void reset() => state = AudioState.idle;
}
