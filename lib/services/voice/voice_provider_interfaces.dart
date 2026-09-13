// KisanSetu (SIH26032) - Voice Assistant Provider Abstractions
// Defines vendor-agnostic contracts for ASR, TTS, and Intent Extraction.

import 'package:flutter/foundation.dart';
import '../../models/voice/voice_intent.dart';

/// Supported voice assistant provider modes.
enum VoiceProviderMode {
  /// Local high-fidelity mock voice provider (Default during approval pending phase).
  mock('DEMO/MOCK'),

  /// Real Bhashini National Language Translation Mission pipeline (activated upon approval).
  realBhashini('REAL_BHASHINI');

  const VoiceProviderMode(this.identifier);
  final String identifier;

  static VoiceProviderMode fromString(String val) {
    if (val.toUpperCase().contains('BHASHINI') || val.toUpperCase() == 'REAL_BHASHINI') {
      return VoiceProviderMode.realBhashini;
    }
    return VoiceProviderMode.mock;
  }
}

/// Provider contract for Automatic Speech Recognition (ASR / Voice Input).
abstract class VoiceInputProvider {
  /// Starts listening for microphone speech input in [language] (e.g. 'en-IN', 'hi-IN', 'te-IN').
  Future<bool> startListening({
    required String language,
    required ValueChanged<String> onResult,
    required ValueChanged<String> onError,
  });

  /// Stops the current listening session.
  Future<void> stopListening();

  /// Whether the input provider is currently recording/listening.
  bool get isListening;
}

/// Provider contract for Text-to-Speech (TTS / Voice Output).
abstract class VoiceOutputProvider {
  /// Speaks the provided [text] in [language].
  Future<void> speak(String text, {required String language});

  /// Immediately cancels any ongoing speech synthesis.
  Future<void> stop();

  /// Whether speech output is currently active.
  bool get isSpeaking;
}

/// Provider contract for NLU / Intent & Entity Extraction.
abstract class IntentProvider {
  /// Extracts a structured [VoiceIntent] from transcribed [text] in [language],
  /// taking into account [previousIntent] for progressive slot filling.
  Future<VoiceIntent> extractIntent({
    required String text,
    required String language,
    VoiceIntent? previousIntent,
  });
}
