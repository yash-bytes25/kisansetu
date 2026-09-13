// KisanSetu (SIH26032) - Bhashini ALD (Audio Language Identification) Service
// Architectural contract and boundary for future Bhashini ULCA ALD pipeline.
//
// NOTICE: Real Bhashini integration is pending API approval.
// Proxied via Supabase Edge Function to Bhashini ALD inference API when active.

import '../../models/voice/voice_audio_data.dart';
import 'bhashini_config.dart';
import 'bhashini_errors.dart';

/// Contract for Audio Language Identification from speech audio.
abstract class AudioLanguageIdentifier {
  /// Identifies the spoken language from [audio].
  /// Returns BCP-47 language tag (e.g., 'hi', 'te', 'en') or throws [BhashiniException].
  Future<String> identifyLanguage(AudioPayload audio);

  /// Whether the ALD service is currently configured and ready.
  bool get isReady;
}

/// Bhashini implementation of [AudioLanguageIdentifier].
class BhashiniAldService implements AudioLanguageIdentifier {
  BhashiniAldService({BhashiniConfig? config})
      : _config = config ?? const BhashiniConfig();

  BhashiniConfig _config;

  @override
  bool get isReady => _config.isConfigured && _config.aldConfig.isEnabled;

  void updateConfig(BhashiniConfig config) {
    _config = config;
  }

  @override
  Future<String> identifyLanguage(AudioPayload audio) async {
    if (!audio.isValid) {
      throw const EmptyAudioException();
    }

    if (!isReady) {
      // Production integration point:
      // POST to /functions/v1/bhashini-proxy?action=ald
      throw const BhashiniUnavailableException(
        'Bhashini ALD credentials pending approval. Fallback to app language preference.',
      );
    }

    // When Bhashini credentials are approved, the Supabase Edge Function returns
    // the top detected language code matching Bhashini supported Indian scheduled languages.
    return 'en';
  }
}
