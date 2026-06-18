import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts].
///
/// Responsibilities:
///  * own the plugin instance and its configuration,
///  * expose a small, intention-revealing API (`init` / `speak` / `stop`),
///  * translate plugin callbacks into simple Dart callbacks the provider wires.
///
/// No Flutter widgets, no Riverpod — this class is pure Dart and unit-testable
/// (you can mock [FlutterTts] in a test). This is the "no business logic in the
/// UI" boundary in action.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialised = false;

  /// Configure voice + wire native completion/error handlers.
  ///
  /// Throws if the engine cannot be configured so the caller can show the
  /// friendly retry UI instead of silently failing.
  Future<void> init({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String message) onError,
  }) async {
    try {
      // Critical for the gating flow: makes `speak` resolve only AFTER the
      // utterance finishes on iOS/Web, keeping behaviour consistent with
      // Android. We still rely on the completion handler as the source of
      // truth for revealing the quiz.
      await _tts.awaitSpeakCompletion(true);

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // gentle pace for young listeners
      await _tts.setPitch(1.15); // slightly higher = friendlier
      await _tts.setVolume(1.0);

      _tts.setStartHandler(onStart);
      _tts.setCompletionHandler(onComplete);
      _tts.setCancelHandler(onComplete);
      _tts.setErrorHandler((msg) => onError(msg.toString()));

      _initialised = true;
    } catch (e) {
      _initialised = false;
      throw TtsException('Failed to initialise narration engine: $e');
    }
  }

  /// Speak [text]. Assumes [init] has run; throws otherwise.
  Future<void> speak(String text) async {
    if (!_initialised) {
      throw const TtsException('TTS used before initialisation.');
    }
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop(); // guard against overlapping utterances
      await _tts.speak(text);
    } catch (e) {
      throw TtsException('Speech failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Stopping should never throw upward — best-effort only.
    }
  }

  Future<void> dispose() => stop();
}

/// Domain-specific exception so callers can distinguish TTS failures from
/// generic errors and react with the right copy.
class TtsException implements Exception {
  const TtsException(this.message);
  final String message;

  @override
  String toString() => 'TtsException: $message';
}
