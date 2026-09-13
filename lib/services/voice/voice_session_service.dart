// KisanSetu (SIH26032) - Voice Session Service
// Manages multi-turn conversation state, history, and active slot-filling context.

import 'package:flutter/foundation.dart';
import '../../models/voice/voice_intent.dart';
import '../../models/voice/voice_message.dart';

/// State management service for an active voice assistant session.
class VoiceSessionService extends ChangeNotifier {
  final List<VoiceMessage> _messages = [];
  VoiceIntent? _currentIntent;
  VoiceAssistantMode _mode = VoiceAssistantMode.ask;
  String _voiceLanguage = 'en-IN';
  String _appLanguage = 'en';
  bool _isProcessing = false;

  List<VoiceMessage> get messages => List.unmodifiable(_messages);
  VoiceIntent? get currentIntent => _currentIntent;
  VoiceAssistantMode get mode => _mode;
  String get voiceLanguage => _voiceLanguage;
  String get appLanguage => _appLanguage;
  bool get isProcessing => _isProcessing;

  /// Sets the operational mode (Ask, Do, Explain).
  void setMode(VoiceAssistantMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  /// Sets the voice recognition & TTS language code (e.g. 'te-IN', 'hi-IN', 'en-IN').
  void setVoiceLanguage(String lang) {
    if (_voiceLanguage != lang) {
      _voiceLanguage = lang;
      notifyListeners();
    }
  }

  /// Sets the app UI language ('en', 'hi', 'te').
  void setAppLanguage(String lang) {
    if (_appLanguage != lang) {
      _appLanguage = lang;
      notifyListeners();
    }
  }

  /// Appends a new conversation message turn.
  void addMessage(VoiceMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Updates or clears the ongoing slot-filling intent context.
  void setCurrentIntent(VoiceIntent? intent) {
    _currentIntent = intent;
    notifyListeners();
  }

  /// Sets processing state (e.g. thinking / calling NLU).
  void setProcessing(bool value) {
    if (_isProcessing != value) {
      _isProcessing = value;
      notifyListeners();
    }
  }

  /// Resets the conversation session, history, and active intent.
  void reset() {
    _messages.clear();
    _currentIntent = null;
    _isProcessing = false;
    notifyListeners();
  }
}
