// KisanSetu (SIH26032) - Bhashini TTS (Speech Synthesis) Service
// Architectural boundary for future Bhashini ULCA Text-to-Speech synthesis.
//
// NOTICE: Real Bhashini integration is pending API approval.
// DO NOT hardcode API credentials or endpoints in this client application.

import 'dart:typed_data';
import '../voice/voice_provider_interfaces.dart';
import 'bhashini_config.dart';
import 'bhashini_errors.dart';

/// Contract for speech synthesis using Bhashini TTS.
abstract class BhashiniTtsProvider implements VoiceOutputProvider {
  /// Synthesizes [text] in [language] and returns raw audio bytes without saving to disk.
  Future<Uint8List?> synthesizeAudio(String text, {required String language});

  /// Updates configuration when Bhashini access details change.
  void updateConfig(BhashiniConfig config);

  /// Whether the TTS service is ready for live synthesis.
  bool get isReady;
}

/// Implements VoiceOutputProvider and BhashiniTtsProvider for future live Bhashini TTS pipeline.
class BhashiniTtsService implements BhashiniTtsProvider {
  BhashiniTtsService({BhashiniConfig? config})
      : _config = config ?? const BhashiniConfig();

  BhashiniConfig _config;
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isReady => _config.isConfigured && _config.ttsConfig.isEnabled;

  @override
  void updateConfig(BhashiniConfig config) {
    _config = config;
  }

  @override
  Future<void> speak(String text, {required String language}) async {
    if (text.trim().isEmpty) return;

    if (!isReady) {
      // Production integration point:
      // Sends text to Supabase Edge Function -> Bhashini TTS -> audio buffer -> player.
      return;
    }

    _isSpeaking = true;
    try {
      final audioBytes = await synthesizeAudio(text, language: language);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        // Stream audio buffer to in-memory audio player
      }
    } finally {
      _isSpeaking = false;
    }
  }

  @override
  Future<Uint8List?> synthesizeAudio(String text, {required String language}) async {
    if (text.trim().isEmpty) {
      throw const EmptyTranscriptException('Text for speech synthesis cannot be empty.');
    }

    if (_config.isConfigured && !_config.isLanguageSupported(BhashiniServiceType.tts, language)) {
      throw UnsupportedLanguageException(language);
    }

    if (!isReady) {
      throw const BhashiniUnavailableException(
        'Bhashini TTS credentials pending approval. Fallback to local audio synthesis.',
      );
    }

    // Production integration point:
    // POST /functions/v1/bhashini-proxy?action=tts
    return Uint8List(0);
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
  }
}
