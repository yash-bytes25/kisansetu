// KisanSetu (SIH26032) - Voice Assistant Service
// Central coordinator managing speech input, NLU intent extraction, confirmation flow, and action dispatch.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/voice/voice_message.dart';
import '../ai/gemini_service.dart';
import '../app_preferences_service.dart';
import '../bhashini/bhashini_service.dart';
import '../connectivity_service.dart';
import 'mock_voice_providers.dart';
import 'voice_action_router.dart';
import 'voice_provider_interfaces.dart';
import 'voice_response_service.dart';
import 'voice_session_service.dart';

/// Central facade coordinating farmer voice interactions.
class VoiceAssistantService extends ChangeNotifier {
  static final VoiceAssistantService instance = VoiceAssistantService._();

  VoiceAssistantService._({
    VoiceInputProvider? inputProvider,
    VoiceOutputProvider? outputProvider,
    IntentProvider? intentProvider,
    VoiceSessionService? sessionService,
    VoiceActionRouter? actionRouter,
    VoiceResponseService? responseService,
  })  : _inputProvider = inputProvider ?? MockVoiceInputProvider(),
        _outputProvider = outputProvider ?? MockVoiceOutputProvider(),
        _intentProvider = intentProvider ?? MockIntentProvider(),
        _session = sessionService ?? VoiceSessionService(),
        _actionRouter = actionRouter ?? VoiceActionRouter(),
        _responseService = responseService ?? VoiceResponseService.instance {
    _session.addListener(notifyListeners);
  }

  VoiceProviderMode _providerMode = VoiceProviderMode.mock;
  VoiceInputProvider _inputProvider;
  VoiceOutputProvider _outputProvider;
  IntentProvider _intentProvider;
  final VoiceSessionService _session;
  final VoiceActionRouter _actionRouter;
  final VoiceResponseService _responseService;

  VoiceProviderMode get providerMode => _providerMode;
  VoiceSessionService get session => _session;
  VoiceInputProvider get inputProvider => _inputProvider;
  VoiceOutputProvider get outputProvider => _outputProvider;
  IntentProvider get intentProvider => _intentProvider;
  bool get isListening => _inputProvider.isListening;
  bool get isSpeaking => _outputProvider.isSpeaking;

  /// Switches active voice provider between DEMO/MOCK and REAL_BHASHINI.
  /// Defaults to DEMO/MOCK while Bhashini approval is pending.
  void setProviderMode(VoiceProviderMode mode) {
    _providerMode = mode;
    switch (mode) {
      case VoiceProviderMode.mock:
        _inputProvider = MockVoiceInputProvider();
        _outputProvider = MockVoiceOutputProvider();
        _intentProvider = MockIntentProvider();
        break;
      case VoiceProviderMode.realBhashini:
        _inputProvider = BhashiniService.instance.asr;
        _outputProvider = BhashiniService.instance.tts;
        _intentProvider = GeminiService.instance;
        break;
    }
    notifyListeners();
  }

  /// Allows replacing providers (e.g. for testing or future Bhashini/Gemini plugin).
  void configureProviders({
    VoiceInputProvider? input,
    VoiceOutputProvider? output,
    IntentProvider? intent,
  }) {
    if (input != null) _inputProvider = input;
    if (output != null) _outputProvider = output;
    if (intent != null) _intentProvider = intent;
    notifyListeners();
  }

  /// Starts listening for speech input.
  Future<bool> startListening() async {
    final voiceLang = AppPreferencesService.instance.voiceLocale;
    _session.setVoiceLanguage(voiceLang);

    // If in Real Bhashini mode but Bhashini is not configured or network is offline
    if (_providerMode == VoiceProviderMode.realBhashini &&
        (!BhashiniService.instance.isConfigured || !AppConnectivityService.instance.isOnline)) {
      _session.addMessage(
        VoiceMessage(
          sender: VoiceSender.assistant,
          text: 'Voice service is temporarily unavailable. You can type your request instead.',
          mode: _session.mode,
        ),
      );
      notifyListeners();
      return false;
    }

    final success = await _inputProvider.startListening(
      language: voiceLang,
      onResult: (transcript) {
        processUserInput(transcript);
      },
      onError: (err) {
        final displayErr = _providerMode == VoiceProviderMode.realBhashini
            ? 'Voice service is temporarily unavailable. You can type your request instead.'
            : err;
        _session.addMessage(
          VoiceMessage(
            sender: VoiceSender.assistant,
            text: displayErr,
            mode: _session.mode,
          ),
        );
      },
    );
    notifyListeners();
    return success;
  }

  /// Stops speech listening.
  Future<void> stopListening() async {
    await _inputProvider.stopListening();
    notifyListeners();
  }

  /// Processes spoken transcript or typed message through intent parsing and slot filling.
  Future<void> processUserInput(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user turn to session history
    _session.addMessage(
      VoiceMessage(
        sender: VoiceSender.user,
        text: text,
        mode: _session.mode,
      ),
    );

    _session.setProcessing(true);
    await stopListening();

    try {
      final voiceLang = _session.voiceLanguage;
      final isTe = voiceLang.startsWith('te') || AppPreferencesService.instance.isTelugu;
      final isHi = voiceLang.startsWith('hi') || AppPreferencesService.instance.isHindi;

      // 2. Extract structured intent with progressive slot filling
      final intent = await _intentProvider.extractIntent(
        text: text,
        language: voiceLang,
        previousIntent: _session.currentIntent,
      );

      _session.setCurrentIntent(intent);

      // 3. Handle slot filling vs complete actionable vs information query
      if (intent.missingFields.isNotEmpty) {
        // Prompt for the first missing field
        final missing = intent.missingFields.first;
        final followUpText = _responseService.getMissingFieldPrompt(
          intent: intent,
          missingField: missing,
          isTelugu: isTe,
          isHindi: isHi,
        );

        _session.addMessage(
          VoiceMessage(
            sender: VoiceSender.assistant,
            text: followUpText,
            intent: intent,
            mode: _session.mode,
          ),
        );

        await _outputProvider.speak(followUpText, language: voiceLang);
      } else if (intent.requiresConfirmation) {
        // All fields present, but requires farmer confirmation card
        final confirmPrompt = _responseService.getBookingConfirmationPrompt(
          intent: intent,
          isTelugu: isTe,
          isHindi: isHi,
        );

        _session.addMessage(
          VoiceMessage(
            sender: VoiceSender.assistant,
            text: confirmPrompt,
            intent: intent,
            mode: _session.mode,
          ),
        );

        await _outputProvider.speak(confirmPrompt, language: voiceLang);
      } else if (intent.isInformation) {
        // Direct information query (Queue, Go-Time, Token, Payment)
        final result = await _actionRouter.executeIntent(
          intent,
          isTelugu: isTe,
          isHindi: isHi,
        );

        _session.addMessage(
          VoiceMessage(
            sender: VoiceSender.assistant,
            text: result.message,
            intent: intent,
            mode: _session.mode,
          ),
        );

        if (result.spokenFeedback != null) {
          await _outputProvider.speak(result.spokenFeedback!, language: voiceLang);
        }
      } else {
        // Unclear or unknown intent
        final fallback = _responseService.getUnclearIntentMessage(
          isTelugu: isTe,
          isHindi: isHi,
        );

        _session.addMessage(
          VoiceMessage(
            sender: VoiceSender.assistant,
            text: fallback,
            intent: intent,
            mode: _session.mode,
          ),
        );

        await _outputProvider.speak(fallback, language: voiceLang);
      }
    } finally {
      _session.setProcessing(false);
    }
  }

  /// Confirms an actionable intent (e.g. farmer taps [CONFIRM & CONTINUE] on confirmation card).
  Future<VoiceActionResult> confirmAction() async {
    final current = _session.currentIntent;
    if (current == null) {
      return const VoiceActionResult(
        isSuccess: false,
        message: 'No pending action to confirm.',
      );
    }

    final isTe = AppPreferencesService.instance.isTelugu;
    final isHi = AppPreferencesService.instance.isHindi;

    _session.setProcessing(true);
    try {
      final result = await _actionRouter.executeIntent(
        current,
        isTelugu: isTe,
        isHindi: isHi,
      );

      _session.addMessage(
        VoiceMessage(
          sender: VoiceSender.assistant,
          text: result.message,
          intent: current,
          mode: _session.mode,
        ),
      );

      if (result.spokenFeedback != null) {
        await _outputProvider.speak(
          result.spokenFeedback!,
          language: _session.voiceLanguage,
        );
      }

      // Action executed; clear active intent
      _session.setCurrentIntent(null);
      return result;
    } finally {
      _session.setProcessing(false);
    }
  }

  /// Cancels the ongoing actionable intent.
  void cancelAction() {
    final isTe = AppPreferencesService.instance.isTelugu;
    final isHi = AppPreferencesService.instance.isHindi;

    final msg = _responseService.getCancellationMessage(
      isTelugu: isTe,
      isHindi: isHi,
    );

    _session.addMessage(
      VoiceMessage(
        sender: VoiceSender.assistant,
        text: msg,
        mode: _session.mode,
      ),
    );

    _session.setCurrentIntent(null);
  }

  /// Replays audio for a specific text string.
  Future<void> speakText(String text) async {
    await _outputProvider.speak(text, language: _session.voiceLanguage);
  }

  /// Resets the conversation session.
  void reset() {
    _session.reset();
    _outputProvider.stop();
    _inputProvider.stopListening();
  }
}
