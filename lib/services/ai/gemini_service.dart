// KisanSetu (SIH26032) - Gemini AI Intent Adapter
// Architectural boundary for Gemini multimodal conversational refinement.
//
// ZERO-CREDENTIAL & RESTRICTED ACCESS DIRECTIVE:
// DO NOT store Gemini API keys in client-side Dart code.
// Gemini interactions are routed strictly via secure Supabase Edge Functions.
//
// SAFETY CONTRACT:
// Gemini receives structured text and conversational context only.
// Gemini returns structured VoiceIntent data ONLY.
// It has NO direct database access and MUST NEVER directly:
// - create or cancel bookings
// - modify payments or accounts
// - alter procurement queues or center statuses
// - update farmer profiles or grievance disputes
// All actions require explicit farmer confirmation via VoiceActionRouter.

import '../../models/voice/voice_intent.dart';
import '../voice/voice_provider_interfaces.dart';

/// Gemini AI intent extraction adapter implementing IntentProvider.
class GeminiService implements IntentProvider {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Whether the Gemini edge proxy is active and configured.
  /// Remains false until server-side Edge Function and keys are configured.
  bool get isConfigured => false;

  @override
  Future<VoiceIntent> extractIntent({
    required String text,
    required String language,
    VoiceIntent? previousIntent,
  }) async {
    final sanitizedText = text.trim();
    if (sanitizedText.isEmpty) {
      return VoiceIntent.unknown(message: text);
    }

    if (!isConfigured) {
      // Production integration point:
      // POST /functions/v1/gemini-intent-parser
      // Body: { "text": sanitizedText, "language": language, "context": previousIntent?.toJson() }
      // The edge function enforces a strict JSON Schema returning VoiceIntent properties.
      return VoiceIntent.unknown(message: text);
    }

    return VoiceIntent.unknown(message: text);
  }
}
