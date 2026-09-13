// KisanSetu (SIH26032) - Bhashini Service Facade
// Architectural boundary adapter for National Language Translation Mission (NLTM) Bhashini APIs.
//
// NOTICE: Real Bhashini integration is pending API approval.
// DO NOT hardcode API credentials or private keys in this client application.
// In production, Bhashini ULCA pipeline endpoints are invoked via secure Supabase Edge Functions.

import 'bhashini_ald_service.dart';
import 'bhashini_asr_service.dart';
import 'bhashini_config.dart';
import 'bhashini_translation_service.dart';
import 'bhashini_tts_service.dart';

/// Central facade orchestrating Bhashini voice, translation, and language identification adapters.
class BhashiniService {
  BhashiniService._({
    BhashiniConfig? config,
    BhashiniAldService? ald,
    BhashiniAsrService? asr,
    BhashiniTranslationService? nmt,
    BhashiniTtsService? tts,
  })  : _config = config ?? const BhashiniConfig(),
        _ald = ald ?? BhashiniAldService(config: config),
        _asr = asr ?? BhashiniAsrService(config: config),
        _nmt = nmt ?? BhashiniTranslationService(config: config),
        _tts = tts ?? BhashiniTtsService(config: config);

  static final BhashiniService instance = BhashiniService._();

  BhashiniConfig _config;
  final BhashiniAldService _ald;
  final BhashiniAsrService _asr;
  final BhashiniTranslationService _nmt;
  final BhashiniTtsService _tts;

  /// Current Bhashini configuration.
  BhashiniConfig get config => _config;

  /// Audio Language Identification service adapter.
  BhashiniAldService get ald => _ald;

  /// Speech Recognition service adapter.
  BhashiniAsrService get asr => _asr;

  /// Neural Machine Translation service adapter.
  BhashiniTranslationService get nmt => _nmt;

  /// Text to Speech service adapter.
  BhashiniTtsService get tts => _tts;

  /// Whether live Bhashini API access is configured and active.
  /// Remains false during approval pending phase.
  bool get isConfigured => _config.isConfigured;

  /// Status description of the Bhashini service.
  String get statusMessage => isConfigured
      ? 'Bhashini AI pipeline configured.'
      : 'Bhashini AI pipeline approval pending. Running on high-fidelity Mock Voice Provider.';

  /// Updates pipeline configuration and propagates to all sub-services.
  void updateConfig(BhashiniConfig newConfig) {
    _config = newConfig;
    _ald.updateConfig(newConfig);
    _asr.updateConfig(newConfig);
    _nmt.updateConfig(newConfig);
    _tts.updateConfig(newConfig);
  }
}
