import 'voice_assistant_speech_service.dart';

/// Factory returning the native / VM stub implementation.
VoiceAssistantSpeechService createVoiceSpeechService() =>
    VoiceAssistantSpeechStub();

/// Stub implementation of VoiceAssistantSpeechService for Dart VM, testing, and native builds.
///
/// Records the last invocation parameters so unit and widget tests can verify
/// that speech was triggered with the appropriate text and locale.
class VoiceAssistantSpeechStub implements VoiceAssistantSpeechService {
  String? lastSpokenText;
  String? lastSpokenLocale;
  int speakCallCount = 0;
  int stopCallCount = 0;
  bool _speaking = false;

  @override
  bool get isSupported => true;

  @override
  bool get isSpeaking => _speaking;

  @override
  void stop() {
    stopCallCount++;
    _speaking = false;
  }

  @override
  void speak(String text, {String? language}) {
    stop(); // cancel previous
    speakCallCount++;
    lastSpokenText = text;
    lastSpokenLocale = VoiceAssistantSpeechService.resolveLocale(language);
    _speaking = true;
  }

  /// Resets test counters and recording fields.
  void reset() {
    lastSpokenText = null;
    lastSpokenLocale = null;
    speakCallCount = 0;
    stopCallCount = 0;
    _speaking = false;
  }
}
