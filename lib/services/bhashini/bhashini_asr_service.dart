// KisanSetu (SIH26032) - Bhashini ASR (Speech Recognition) Service
// Architectural boundary for future Bhashini ULCA ASR pipeline.
//
// NOTICE: Real Bhashini integration is pending API approval.
// DO NOT hardcode API credentials or private keys in this client application.
// In production, audio streams to Supabase Edge Function -> Bhashini WebSocket / REST ASR.

import 'package:flutter/foundation.dart';
import '../../models/voice/voice_audio_data.dart';
import '../voice/voice_provider_interfaces.dart';
import 'bhashini_config.dart';
import 'bhashini_errors.dart';

/// Contract for speech-to-text recognition using Bhashini ASR.
abstract class BhashiniAsrProvider implements VoiceInputProvider {
  /// Directly transcribes pre-recorded or buffered [audio] payload.
  Future<String> transcribeAudio(AudioPayload audio);

  /// Updates configuration when Bhashini access details change.
  void updateConfig(BhashiniConfig config);

  /// Whether the ASR service is ready for live inference.
  bool get isReady;
}

/// Implements VoiceInputProvider and BhashiniAsrProvider for future live Bhashini ASR pipeline.
class BhashiniAsrService implements BhashiniAsrProvider {
  BhashiniAsrService({BhashiniConfig? config})
      : _config = config ?? const BhashiniConfig();

  BhashiniConfig _config;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  bool get isReady => _config.isConfigured && _config.asrConfig.isEnabled;

  @override
  void updateConfig(BhashiniConfig config) {
    _config = config;
  }

  @override
  Future<bool> startListening({
    required String language,
    required ValueChanged<String> onResult,
    required ValueChanged<String> onError,
  }) async {
    // 1. Language support validation
    if (_config.isConfigured && !_config.isLanguageSupported(BhashiniServiceType.asr, language)) {
      onError(
        const UnsupportedLanguageException('asr')
            .getUserFriendlyMessage(),
      );
      return false;
    }

    // 2. Production readiness check
    if (!isReady) {
      // Production integration point:
      // Streams audio packets to Supabase Edge Function -> Bhashini WebSocket / REST ASR.
      onError(
        const BhashiniUnavailableException(
          'Bhashini ASR credentials pending approval. Fallback to MockVoiceInputProvider.',
        ).getUserFriendlyMessage(),
      );
      return false;
    }

    _isListening = true;
    return true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<String> transcribeAudio(AudioPayload audio) async {
    if (!audio.isValid) {
      throw const EmptyAudioException();
    }

    if (!isReady) {
      throw const BhashiniUnavailableException(
        'Bhashini ASR is pending approval. Server proxy not configured.',
      );
    }

    // When active, sends audio payload to Supabase Edge Function proxy
    return audio.transcript ?? '';
  }
}
