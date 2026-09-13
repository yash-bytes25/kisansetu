// KisanSetu (SIH26032) - Mock Voice Providers
// Mock implementations of VoiceInputProvider, VoiceOutputProvider, and IntentProvider for Phase G-A.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/voice/voice_intent.dart';
import '../voice_assistant_speech/voice_assistant_speech_service.dart';
import 'voice_provider_interfaces.dart';

/// Mock ASR provider simulating speech recognition.
class MockVoiceInputProvider implements VoiceInputProvider {
  bool _isListening = false;
  ValueChanged<String>? _onResult;
  ValueChanged<String>? _onError;
  String _currentLanguage = 'en-IN';

  @override
  bool get isListening => _isListening;

  /// Current simulated listening language (e.g. 'en-IN', 'hi-IN', 'te-IN')
  String get currentLanguage => _currentLanguage;

  @override
  Future<bool> startListening({
    required String language,
    required ValueChanged<String> onResult,
    required ValueChanged<String> onError,
  }) async {
    _isListening = true;
    _currentLanguage = language;
    _onResult = onResult;
    _onError = onError;
    return true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _onResult = null;
    _onError = null;
  }

  /// Manually simulates speech input for testing or UI demonstration chips.
  void simulateSpeechInput(String transcript) {
    if (_onResult != null) {
      _onResult!(transcript);
    }
  }

  /// Simulates an ASR error.
  void simulateError(String message) {
    if (_onError != null) {
      _onError!(message);
    }
  }
}

/// Mock TTS provider using KisanSetu's existing speech synthesis with verification tracking.
class MockVoiceOutputProvider implements VoiceOutputProvider {
  String? lastSpokenText;
  String? lastSpokenLanguage;
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text, {required String language}) async {
    lastSpokenText = text;
    lastSpokenLanguage = language;
    _isSpeaking = true;

    // Delegate to existing Web Speech API / native stub
    VoiceAssistantSpeechService.instance.speak(text, language: language);
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    VoiceAssistantSpeechService.instance.stop();
  }
}

/// Rule-based mock intent and entity extractor supporting English, Hindi, and Telugu.
class MockIntentProvider implements IntentProvider {
  // Crop dictionaries
  static const Map<String, String> _cropAliases = {
    'wheat': 'Wheat',
    'gehun': 'Wheat',
    'gehu': 'Wheat',
    'गेहूं': 'Wheat',
    'गेहू': 'Wheat',
    'godhumalu': 'Wheat',
    'గోధుమలు': 'Wheat',
    'గోధుమ': 'Wheat',
    'paddy': 'Paddy',
    'rice': 'Paddy',
    'dhan': 'Paddy',
    'धान': 'Paddy',
    'vari': 'Paddy',
    'వరి': 'Paddy',
    'maize': 'Maize',
    'makka': 'Maize',
    'मक्का': 'Maize',
    'mokkajonna': 'Maize',
    'మొక్కజొన్న': 'Maize',
    'cotton': 'Cotton',
    'kapas': 'Cotton',
    'कपास': 'Cotton',
    'patthi': 'Cotton',
    'పత్తి': 'Cotton',
    'groundnut': 'Groundnut',
    'moongfali': 'Groundnut',
    'मूंगफली': 'Groundnut',
    'verusenaga': 'Groundnut',
    'వేరుశనగ': 'Groundnut',
    'tur': 'Red Gram',
    'arhar': 'Red Gram',
    'red gram': 'Red Gram',
    'अरहर': 'Red Gram',
    'కందులు': 'Red Gram',
  };

  @override
  Future<VoiceIntent> extractIntent({
    required String text,
    required String language,
    VoiceIntent? previousIntent,
  }) async {
    final lower = text.toLowerCase().trim();

    // 1. Check for conversational cancellation
    if (_isCancellation(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.unknown,
        userMessage: text,
        confidence: 1.0,
      );
    }

    // 2. Progressive Slot Filling / Correction if we have an incomplete previous intent
    if (previousIntent != null && previousIntent.intent == VoiceIntentType.bookSlot) {
      // Check for quantity correction or missing slot answer
      final updated = _fillBookingSlots(lower, previousIntent, text);
      if (updated != null) {
        return updated;
      }
    }

    // 3. Information Queries
    if (_matchesTokenQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getTokenStatus,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesGoTimeQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getGoTime,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesQueueQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getQueue,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesPaymentQuery(lower)) {
      if (lower.contains('history') ||
          lower.contains('receipt') ||
          lower.contains('రశీదు') ||
          lower.contains('रसीद')) {
        return VoiceIntent(
          intent: VoiceIntentType.getPaymentHistory,
          userMessage: text,
          confidence: 0.95,
        );
      }
      return VoiceIntent(
        intent: VoiceIntentType.getPaymentStatus,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesProcurementStatusQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getProcurementStatus,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesCentreRecommendationQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.recommendCentre,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesCentreStatusQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getCentreStatus,
        userMessage: text,
        confidence: 0.95,
      );
    }

    if (_matchesDisputeQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.startDispute,
        userMessage: text,
        confidence: 0.95,
        requiresConfirmation: true,
      );
    }

    if (_matchesProfileQuery(lower)) {
      return VoiceIntent(
        intent: VoiceIntentType.getProfileInfo,
        userMessage: text,
        confidence: 0.95,
      );
    }

    // 4. Booking / Sell Produce Intent
    if (_matchesBookingIntent(lower)) {
      final crop = _extractCrop(lower);
      final quantity = _extractQuantity(lower);
      final date = _extractDate(lower);

      final missing = <String>[];
      if (crop == null) missing.add('crop');
      if (quantity == null) missing.add('quantity');
      if (date == null) missing.add('date');

      return VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: crop,
        quantity: quantity,
        quantityUnit: 'Quintals',
        date: date,
        missingFields: missing,
        userMessage: text,
        confidence: 0.92,
        requiresConfirmation: missing.isEmpty,
      );
    }

    // 5. Change crop or quantity standalone
    if (lower.contains('change crop') ||
        lower.contains('फसल बदल') ||
        lower.contains('పంట మార్చు')) {
      final crop = _extractCrop(lower);
      return VoiceIntent(
        intent: VoiceIntentType.changeCrop,
        crop: crop,
        missingFields: crop == null ? ['crop'] : [],
        userMessage: text,
        confidence: 0.9,
        requiresConfirmation: crop != null,
      );
    }

    if (lower.contains('change quantity') ||
        lower.contains('मात्रा बदल') ||
        lower.contains('పరిమాణం మార్చు')) {
      final quantity = _extractQuantity(lower);
      return VoiceIntent(
        intent: VoiceIntentType.changeQuantity,
        quantity: quantity,
        missingFields: quantity == null ? ['quantity'] : [],
        userMessage: text,
        confidence: 0.9,
        requiresConfirmation: quantity != null,
      );
    }

    // Default fallback
    return VoiceIntent.unknown(message: text);
  }

  // --- Progressive Slot Filling Helper ---
  VoiceIntent? _fillBookingSlots(String lower, VoiceIntent prev, String rawText) {
    // Check for explicit correction: "no, make it 100", "nahi, 100 quintal", "వద్దు 100"
    final isCorrection = lower.startsWith('no') ||
        lower.startsWith('nahi') ||
        lower.startsWith('नहीं') ||
        lower.startsWith('vaddu') ||
        lower.startsWith('వద్దు') ||
        lower.contains('make it') ||
        lower.contains('instead');

    String? newCrop = _extractCrop(lower) ?? prev.crop;
    double? newQty = _extractQuantity(lower) ?? prev.quantity;
    String? newDate = _extractDate(lower) ?? prev.date;

    if (isCorrection) {
      final correctedQty = _extractQuantity(lower);
      if (correctedQty != null) newQty = correctedQty;

      final correctedCrop = _extractCrop(lower);
      if (correctedCrop != null) newCrop = correctedCrop;

      final correctedDate = _extractDate(lower);
      if (correctedDate != null) newDate = correctedDate;
    }

    // Only return updated intent if at least one field changed or was filled
    if (newCrop != prev.crop || newQty != prev.quantity || newDate != prev.date || isCorrection) {
      final missing = <String>[];
      if (newCrop == null) missing.add('crop');
      if (newQty == null) missing.add('quantity');
      if (newDate == null) missing.add('date');

      return prev.copyWith(
        crop: newCrop,
        quantity: newQty,
        date: newDate,
        missingFields: missing,
        userMessage: rawText,
        requiresConfirmation: missing.isEmpty,
      );
    }

    return null;
  }

  // --- Entity Extractors ---
  String? _extractCrop(String lower) {
    for (final entry in _cropAliases.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  double? _extractQuantity(String lower) {
    // Matches e.g. "50 kg", "50kg", "50 quintals", "50 qtl", "50 किलो", "50 క్వింటాళ్లు", or standalone numbers
    final regExp = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kilos|quintals|quintal|qtl|किलो|क्विंटल|క్వింటాళ్లు)?');
    final match = regExp.firstMatch(lower);
    if (match != null) {
      final val = double.tryParse(match.group(1) ?? '');
      if (val != null && val > 0 && val <= 1000) {
        return val;
      }
    }
    return null;
  }

  String? _extractDate(String lower) {
    if (lower.contains('tomorrow') ||
        lower.contains('kal') ||
        lower.contains('कल') ||
        lower.contains('repu') ||
        lower.contains('రేపు')) {
      return 'Tomorrow';
    }
    if (lower.contains('today') ||
        lower.contains('aaj') ||
        lower.contains('आज') ||
        lower.contains('eeroju') ||
        lower.contains('ఈరోజు')) {
      return 'Today';
    }
    if (lower.contains('day after') ||
        lower.contains('parso') ||
        lower.contains('परसों') ||
        lower.contains('ఎల్లుండి')) {
      return 'Day After Tomorrow';
    }
    return null;
  }

  // --- Query Intent Matchers ---
  bool _isCancellation(String lower) =>
      lower == 'cancel' ||
      lower == 'stop' ||
      lower == 'रद्द' ||
      lower == 'రద్దు' ||
      lower.contains('cancel booking');

  bool _matchesTokenQuery(String lower) =>
      lower.contains('token') ||
      lower.contains('digital pass') ||
      lower.contains('pass') ||
      lower.contains('टोकन') ||
      lower.contains('టోకెన్');

  bool _matchesGoTimeQuery(String lower) =>
      lower.contains('when should i leave') ||
      lower.contains('go time') ||
      lower.contains('departure') ||
      lower.contains('leave') ||
      lower.contains('कब निकलना') ||
      lower.contains('ఎప్పుడు బయలుదేరాలి');

  bool _matchesQueueQuery(String lower) =>
      lower.contains('queue') ||
      lower.contains('how many people') ||
      lower.contains('ahead') ||
      lower.contains('wait time') ||
      lower.contains('कतार') ||
      lower.contains('लोग आगे') ||
      lower.contains('క్యూ') ||
      lower.contains('ఎంత మంది');

  bool _matchesPaymentQuery(String lower) =>
      lower.contains('payment') ||
      lower.contains('dbt') ||
      lower.contains('money') ||
      lower.contains('भुगतान') ||
      lower.contains('पैसे') ||
      lower.contains('చెల్లింపు') ||
      lower.contains('డబ్బులు');

  bool _matchesProcurementStatusQuery(String lower) =>
      lower.contains('procurement status') ||
      lower.contains('status of my produce') ||
      lower.contains('inspection') ||
      lower.contains('weighment status') ||
      lower.contains('खरीद स्थिति') ||
      lower.contains('సేకరణ స్థితి');

  bool _matchesCentreRecommendationQuery(String lower) =>
      lower.contains('which centre') ||
      lower.contains('better centre') ||
      lower.contains('recommend centre') ||
      lower.contains('alternative centre') ||
      lower.contains('बेहतर केंद्र') ||
      lower.contains('नजदीकी केंद्र') ||
      lower.contains('మంచి కేంద్రం') ||
      lower.contains('సమీప కేంద్రం');

  bool _matchesCentreStatusQuery(String lower) =>
      lower.contains('is centre open') ||
      lower.contains('centre status') ||
      lower.contains('delay') ||
      lower.contains('centre open') ||
      lower.contains('केंद्र खुला') ||
      lower.contains('కేంద్రం తెరిచి');

  bool _matchesDisputeQuery(String lower) =>
      lower.contains('report a problem') ||
      lower.contains('problem') ||
      lower.contains('dispute') ||
      lower.contains('complaint') ||
      lower.contains('issue') ||
      lower.contains('शिकायत') ||
      lower.contains('समस्या') ||
      lower.contains('సమస్య') ||
      lower.contains('ఫిర్యాదు');

  bool _matchesProfileQuery(String lower) =>
      lower.contains('profile') ||
      lower.contains('kyc') ||
      lower.contains('bank account') ||
      lower.contains('aadhaar') ||
      lower.contains('प्रोफाइल') ||
      lower.contains('खाता') ||
      lower.contains('ప్రొఫైల్') ||
      lower.contains('ఖాతా');

  bool _matchesBookingIntent(String lower) =>
      lower.contains('sell') ||
      lower.contains('book') ||
      lower.contains('slot') ||
      lower.contains('procure') ||
      lower.contains('बेच') ||
      lower.contains('बुक') ||
      lower.contains('స్లాట్') ||
      lower.contains('అమ్మ') ||
      lower.contains('బుక్');
}
