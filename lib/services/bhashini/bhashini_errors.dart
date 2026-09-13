// KisanSetu (SIH26032) - Bhashini Error Taxonomy & Safe User Feedback
// Strongly-typed errors for Bhashini pipeline operations.
//
// SECURITY DIRECTIVE:
// Technical details, stack traces, and credential status are sanitized.
// Farmer-facing messages are localized and reassuring.

/// Base exception for all Bhashini voice and translation pipeline errors.
abstract class BhashiniException implements Exception {
  const BhashiniException(this.technicalMessage, {this.cause});

  final String technicalMessage;
  final dynamic cause;

  /// Farmer-safe message localized for English, Hindi, and Telugu.
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false});

  @override
  String toString() => '$runtimeType: $technicalMessage';
}

/// Thrown when Bhashini services or proxy endpoints are unreachable or offline.
class BhashiniUnavailableException extends BhashiniException {
  const BhashiniUnavailableException([super.technicalMessage = 'Bhashini service is temporarily unavailable.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'వాయిస్ సేవ తాత్కాలికంగా అందుబాటులో లేదు. మీరు మీ అభ్యర్థనను టైప్ చేయవచ్చు.';
    }
    if (isHindi) {
      return 'आवाज़ सेवा अस्थायी रूप से अनुपलब्ध है। आप अपना अनुरोध टाइप कर सकते हैं।';
    }
    return 'Voice service is temporarily unavailable. You can type your request instead.';
  }
}

/// Thrown when API keys/tokens are missing, invalid, or rejected.
/// Never exposes credentials or server error messages to the farmer.
class InvalidCredentialsException extends BhashiniException {
  const InvalidCredentialsException([super.technicalMessage = 'Bhashini credentials invalid or unconfigured.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'వాయిస్ సేవ అందుబాటులో లేదు. దయచేసి టైప్ చేయండి.';
    }
    if (isHindi) {
      return 'आवाज़ सेवा अभी उपलब्ध नहीं है। कृपया टाइप करें।';
    }
    return 'Voice service is currently not available. Please type your request.';
  }
}

/// Thrown when requested language is not supported by the specific Bhashini model/service.
class UnsupportedLanguageException extends BhashiniException {
  const UnsupportedLanguageException(this.languageCode, [String msg = 'Language not supported by service.'])
      : super('$msg (lang: $languageCode)');

  final String languageCode;

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'ఎంచుకున్న భాషలో వాయిస్ సేవ అందుబాటులో లేదు. దయచేసి ఆంగ్లం లేదా హిందీ ఎంచుకోండి.';
    }
    if (isHindi) {
      return 'चुनी गई भाषा में आवाज़ सेवा उपलब्ध नहीं है। कृपया अंग्रेज़ी या हिंदी चुनें।';
    }
    return 'Voice is not supported in this language yet. Please try English or Hindi.';
  }
}

/// Thrown when ASR (Speech Recognition) fails to process the audio stream.
class AsrFailureException extends BhashiniException {
  const AsrFailureException([super.technicalMessage = 'Bhashini ASR recognition failed.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'మీ మాట స్పష్టంగా వినిపించలేదు. దయచేసి మళ్లీ చెప్పండి లేదా టైప్ చేయండి.';
    }
    if (isHindi) {
      return 'आपकी आवाज़ स्पष्ट नहीं सुनाई दी। कृपया दोबारा बोलें या टाइप करें।';
    }
    return 'Could not understand the audio. Please speak again or type your request.';
  }
}

/// Thrown when ALD (Audio Language Identification) cannot determine language.
class AldFailureException extends BhashiniException {
  const AldFailureException([super.technicalMessage = 'Audio language identification failed.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'భాషను గుర్తించలేకపోయాము. దయచేసి మాట్లాడే భాషను మాన్యువల్‌గా ఎంచుకోండి.';
    }
    if (isHindi) {
      return 'भाषा पहचानी नहीं जा सकी। कृपया अपनी भाषा का चयन करें।';
    }
    return 'Could not identify language. Please select your preferred language.';
  }
}

/// Thrown when NMT (Machine Translation) fails.
class NmtFailureException extends BhashiniException {
  const NmtFailureException([super.technicalMessage = 'Translation service failed.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'అనువాదంలో సమస్య వచ్చింది. దయచేసి మళ్లీ ప్రయత్నించండి.';
    }
    if (isHindi) {
      return 'अनुवाद में समस्या आई। कृपया पुनः प्रयास करें।';
    }
    return 'Translation failed. Please try again.';
  }
}

/// Thrown when TTS (Text to Speech) synthesis fails.
class TtsFailureException extends BhashiniException {
  const TtsFailureException([super.technicalMessage = 'Speech synthesis failed.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'ఆడియో ప్లేబ్యాక్ విఫలమైంది.';
    }
    if (isHindi) {
      return 'ऑडियो प्लेबैक विफल रहा।';
    }
    return 'Audio playback failed.';
  }
}

/// Thrown when network request times out.
class BhashiniTimeoutException extends BhashiniException {
  const BhashiniTimeoutException([super.technicalMessage = 'Request timed out.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'వాయిస్ సర్వర్ స్పందించడానికి ఎక్కువ సమయం పట్టింది. దయచేసి మళ్లీ ప్రయత్నించండి.';
    }
    if (isHindi) {
      return 'सर्वर से जवाब आने में समय लग रहा है। कृपया दोबारा कोशिश करें।';
    }
    return 'Voice request timed out. Please try again or type.';
  }
}

/// Thrown when device has no connectivity or network drop occurs.
class NetworkFailureException extends BhashiniException {
  const NetworkFailureException([super.technicalMessage = 'Network connection failed.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'ఇంటర్నెట్ కనెక్షన్ లేదు. నెట్‌వర్క్ తనిఖీ చేయండి.';
    }
    if (isHindi) {
      return 'इंटरनेट कनेक्शन नहीं है। कृपया नेटवर्क चेक करें।';
    }
    return 'No internet connection. Please check your network.';
  }
}

/// Thrown when recorded audio buffer contains no sound data.
class EmptyAudioException extends BhashiniException {
  const EmptyAudioException([super.technicalMessage = 'Recorded audio is empty or below threshold.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'ఎటువంటి శబ్దం వినిపించలేదు. మైక్రోఫోన్ దగ్గర మాట్లాడండి.';
    }
    if (isHindi) {
      return 'कोई आवाज़ सुनाई नहीं दी। कृपया माइक के पास बोलें।';
    }
    return 'No audio detected. Please speak clearly into the microphone.';
  }
}

/// Thrown when speech was received but recognized transcript is blank.
class EmptyTranscriptException extends BhashiniException {
  const EmptyTranscriptException([super.technicalMessage = 'Recognized transcript is blank.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'స్పష్టంగా వినిపించలేదు. దయచేసి మళ్లీ చెప్పండి.';
    }
    if (isHindi) {
      return 'स्पष्ट नहीं सुनाई दिया। कृपया दोबारा बोलें।';
    }
    return 'Speech not recognized. Please speak again.';
  }
}

/// Thrown when upstream rate limit / quota is exceeded.
class RateLimitException extends BhashiniException {
  const RateLimitException([super.technicalMessage = 'Rate limit exceeded for Bhashini pipeline.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'చాలా అభ్యర్థనలు వచ్చాయి. దయచేసి కాసేపటి తర్వాత ప్రయత్నించండి.';
    }
    if (isHindi) {
      return 'अधिक अनुरोध आए हैं। कृपया कुछ देर बाद प्रयास करें।';
    }
    return 'Too many requests. Please wait a moment and try again.';
  }
}

/// Thrown when server returns 5xx error.
class ServerErrorException extends BhashiniException {
  const ServerErrorException([super.technicalMessage = 'Bhashini server error.']);

  @override
  String getUserFriendlyMessage({bool isTelugu = false, bool isHindi = false}) {
    if (isTelugu) {
      return 'సర్వర్ లోపం సంభవించింది. దయచేసి తర్వాత ప్రయత్నించండి.';
    }
    if (isHindi) {
      return 'सर्वर त्रुटि। कृपया बाद में प्रयास करें।';
    }
    return 'Server error occurred. Please try again later.';
  }
}
