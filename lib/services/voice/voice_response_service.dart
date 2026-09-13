// KisanSetu (SIH26032) - Voice Response Generator
// Formats farmer-friendly, respectful trilingual responses and follow-up prompts.

import '../../models/voice/voice_intent.dart';

/// Generates localized assistant responses in English, Hindi, and Telugu.
class VoiceResponseService {
  VoiceResponseService._();
  static final VoiceResponseService instance = VoiceResponseService._();

  /// Welcomes the farmer based on the active mode and language.
  String getWelcomeMessage({
    required String language,
    bool isTelugu = false,
    bool isHindi = false,
  }) {
    if (isTelugu) {
      return 'నమస్కారం! నేను కిసాన్ సేతు వాయిస్ అసిస్టెంట్. స్లాట్ బుకింగ్, టోకెన్, క్యూ లేదా చెల్లింపు వివరాల కోసం మాట్లాడండి.';
    }
    if (isHindi) {
      return 'नमस्ते! मैं किसानसेतु वॉइस असिस्टेंट हूँ। स्लॉट बुकिंग, टोकन, कतार या भुगतान की जानकारी के लिए बोलें।';
    }
    return 'Welcome to KisanSetu Voice Assistant. Speak naturally to book a slot, check your queue, Go-Time, or payment.';
  }

  /// Generates conversational slot filling follow-up prompts when required fields are missing.
  String getMissingFieldPrompt({
    required VoiceIntent intent,
    required String missingField,
    bool isTelugu = false,
    bool isHindi = false,
  }) {
    switch (missingField) {
      case 'crop':
        if (isTelugu) return 'మీరు ఏ పంట అమ్మాలనుకుంటున్నారు? (ఉదాహరణకు: గోధుమలు, వరి, మక్కా)';
        if (isHindi) return 'आप कौन सी फसल बेचना चाहते हैं? (जैसे: गेहूं, धान, मक्का)';
        return 'Which crop do you want to sell? (e.g., Wheat, Paddy, Maize)';

      case 'quantity':
        final cropName = intent.crop ?? (isTelugu ? 'పంట' : (isHindi ? 'फसल' : 'produce'));
        if (isTelugu) return 'మీరు ఎంత పరిమాణంలో $cropName అమ్మాలనుకుంటున్నారు? (క్వింటాళ్లలో చెప్పండి)';
        if (isHindi) return 'आप कितना $cropName बेचना चाहते हैं? (क्विंटल या किलो में बताएं)';
        return 'How much $cropName do you want to sell? (in Quintals or kg)';

      case 'date':
        if (isTelugu) return 'మీరు ఏ రోజు సేకరణ కేంద్రానికి వెళ్లాలనుకుంటున్నారు? (రేపు లేదా ఈరోజు)';
        if (isHindi) return 'आप किस तारीख को केंद्र जाना चाहते हैं? (जैसे: कल या आज)';
        return 'What date would you like to visit? (e.g., Tomorrow or Today)';

      default:
        if (isTelugu) return 'దయచేసి మరింత సమాచారం చెప్పండి.';
        if (isHindi) return 'कृपया और जानकारी बताएं।';
        return 'Please provide more details.';
    }
  }

  /// Formats the confirmation prompt when all necessary booking fields have been extracted.
  String getBookingConfirmationPrompt({
    required VoiceIntent intent,
    bool isTelugu = false,
    bool isHindi = false,
  }) {
    final crop = intent.crop ?? 'Produce';
    final qty = intent.quantity?.toStringAsFixed(0) ?? '50';
    final unit = intent.quantityUnit;
    final date = intent.date ?? 'Tomorrow';

    if (isTelugu) {
      return 'నేను అర్థం చేసుకున్నాను: $crop – $qty $unit – $date.\nఉత్తమ సేకరణ స్లాట్‌ను ఖరారు చేయమంటారా?';
    }
    if (isHindi) {
      return 'मैंने समझा: $crop – $qty $unit – $date.\nक्या मैं आपके लिए सबसे अच्छा स्लॉट तय करूँ?';
    }
    return 'I understood: $crop – $qty $unit – $date.\nWould you like me to find and confirm the best slot?';
  }

  /// Formats error or fallback prompts.
  String getUnclearIntentMessage({
    bool isTelugu = false,
    bool isHindi = false,
  }) {
    if (isTelugu) {
      return 'క్షమించండి, మీ మాట స్పష్టంగా అర్థం కాలేదు. స్లాట్ బుకింగ్, క్యూ లేదా టోకెన్ గురించి మళ్లీ మాట్లాడండి.';
    }
    if (isHindi) {
      return 'क्षमा करें, मुझे समझ नहीं आया। स्लॉट बुकिंग, टोकन या कतार के बारे में फिर से बोलें।';
    }
    return "I didn't quite understand that. Please speak again to book a slot, check your queue, or query payment status.";
  }

  /// Formats cancellation response.
  String getCancellationMessage({
    bool isTelugu = false,
    bool isHindi = false,
  }) {
    if (isTelugu) return 'అభ్యర్థన రద్దు చేయబడింది. మీకు ఇంకేమైనా సహాయం కావాలా?';
    if (isHindi) return 'अनुरोध रद्द कर दिया गया है। क्या मैं किसी और चीज़ में मदद कर सकता हूँ?';
    return 'Request cancelled. How else can I assist you?';
  }
}
