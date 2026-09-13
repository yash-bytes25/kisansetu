// KisanSetu (SIH26032) - Bhashini Machine Translation (NMT) Service
// Architectural boundary for future Bhashini Neural Machine Translation pipeline.
//
// NOTICE: Real Bhashini integration is pending API approval.
// DO NOT hardcode API credentials or private keys in this client application.

import 'bhashini_config.dart';
import 'bhashini_errors.dart';

/// Contract for Neural Machine Translation across Indian scheduled languages.
abstract class MachineTranslationProvider {
  /// Translates [sourceText] from [sourceLang] to [targetLang].
  Future<String> translate({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
  });

  /// Updates configuration when Bhashini access details change.
  void updateConfig(BhashiniConfig config);

  /// Whether the translation service is ready for live inference.
  bool get isReady;
}

/// Interface and adapter for Bhashini machine translation.
class BhashiniTranslationService implements MachineTranslationProvider {
  BhashiniTranslationService({BhashiniConfig? config})
      : _config = config ?? const BhashiniConfig();

  static final BhashiniTranslationService instance =
      BhashiniTranslationService();

  BhashiniConfig _config;

  @override
  bool get isReady => _config.isConfigured && _config.nmtConfig.isEnabled;

  @override
  void updateConfig(BhashiniConfig config) {
    _config = config;
  }

  @override
  Future<String> translate({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (sourceText.trim().isEmpty) return sourceText;
    if (sourceLang.toLowerCase() == targetLang.toLowerCase()) return sourceText;

    if (_config.isConfigured) {
      if (!_config.isLanguageSupported(BhashiniServiceType.nmt, sourceLang)) {
        throw UnsupportedLanguageException(sourceLang);
      }
      if (!_config.isLanguageSupported(BhashiniServiceType.nmt, targetLang)) {
        throw UnsupportedLanguageException(targetLang);
      }
    }

    if (!isReady) {
      // Production integration point:
      // Proxied via Supabase Edge Function to Bhashini NMT inference API.
      return sourceText;
    }

    // When approved, sends text to Supabase Edge Function proxy
    return sourceText;
  }
}
