import 'voice_assistant_speech_stub.dart'
    if (dart.library.html) 'voice_assistant_speech_web.dart';

/// Platform-agnostic speech synthesis service for KisanSetu Voice Assistant.
///
/// On Chrome Web: Uses the browser's native Web Speech API (`window.speechSynthesis`).
/// On Native/Mobile/VM: Uses graceful stub/recorder for tests and non-web platforms.
abstract class VoiceAssistantSpeechService {
  static VoiceAssistantSpeechService? _instance;

  /// Global singleton instance.
  static VoiceAssistantSpeechService get instance =>
      _instance ??= createVoiceSpeechService();

  /// Sets or overrides the singleton instance (e.g. for testing).
  static void setMockInstance(VoiceAssistantSpeechService? mock) {
    _instance = mock;
  }

  /// Speaks the given [text] in the requested [language].
  ///
  /// Cancels any previous speech before starting to prevent duplicate simultaneous playback.
  void speak(String text, {String? language});

  /// Immediately cancels any ongoing or queued speech.
  void stop();

  /// Whether speech synthesis is supported and available in the current environment.
  bool get isSupported;

  /// Whether speech is currently active/playing.
  bool get isSpeaking;

  /// Resolves user-facing language labels to standard BCP 47 locale codes.
  ///
  /// Supported:
  /// - Telugu: 'te-IN'
  /// - Hindi: 'hi-IN'
  /// - English: 'en-IN'
  static String resolveLocale(String? language) {
    if (language == null) return 'en-IN';
    final lower = language.toLowerCase().trim();
    if (lower.startsWith('te') ||
        lower.contains('telugu') ||
        lower.contains('తెలుగు')) {
      return 'te-IN';
    }
    if (lower.startsWith('hi') ||
        lower.contains('hindi') ||
        lower.contains('हिंदी')) {
      return 'hi-IN';
    }
    return 'en-IN';
  }
}
