import 'package:flutter/foundation.dart';

/// Global session-level language and voice preferences for KisanSetu.
///
/// This is a [ChangeNotifier] singleton. Screens add themselves as listeners in
/// [State.initState] and remove in [State.dispose] so they call [setState]
/// whenever the user changes a preference — giving an immediate, app-wide update
/// without requiring a full widget tree rebuild from the root.
///
/// Usage:
/// ```dart
/// final _prefs = AppPreferencesService.instance;
///
/// @override
/// void initState() {
///   super.initState();
///   _prefs.addListener(_onPrefsChanged);
/// }
///
/// @override
/// void dispose() {
///   _prefs.removeListener(_onPrefsChanged);
///   super.dispose();
/// }
///
/// void _onPrefsChanged() => setState(() {});
/// ```
class AppPreferencesService extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────

  AppPreferencesService._();

  static final AppPreferencesService instance = AppPreferencesService._();

  // ── State ─────────────────────────────────────────────────────────────────

  /// BCP-47 prefix for the UI display language.
  /// Values: 'en' | 'hi' | 'te'
  String _uiLanguage = 'en';

  /// BCP-47 prefix for the voice/speech language.
  /// Defaults to the same as [_uiLanguage] but can be set independently.
  /// Values: 'en' | 'hi' | 'te'
  String _voiceLanguage = 'en';

  // ── Getters ───────────────────────────────────────────────────────────────

  String get uiLanguage => _uiLanguage;
  String get voiceLanguage => _voiceLanguage;

  bool get isHindi  => _uiLanguage == 'hi';
  bool get isTelugu => _uiLanguage == 'te';
  bool get isEnglish => _uiLanguage == 'en';

  bool get voiceIsHindi  => _voiceLanguage == 'hi';
  bool get voiceIsTelugu => _voiceLanguage == 'te';

  /// Full BCP-47 locale for the UI language (e.g. 'te-IN').
  String get uiLocale => _localeFor(_uiLanguage);

  /// Full BCP-47 locale for the voice/speech engine (e.g. 'hi-IN').
  String get voiceLocale => _localeFor(_voiceLanguage);

  // ── Setters ───────────────────────────────────────────────────────────────

  /// Sets the UI display language and (by default) the voice language to the
  /// same value.  Pass [syncVoice: false] to only change the UI language.
  void setUiLanguage(String code, {bool syncVoice = true}) {
    assert(code == 'en' || code == 'hi' || code == 'te',
        'Language code must be en, hi, or te. Got: $code');
    if (_uiLanguage == code && (!syncVoice || _voiceLanguage == code)) return;
    _uiLanguage = code;
    if (syncVoice) _voiceLanguage = code;
    notifyListeners();
  }

  /// Sets only the voice/speech language independently of the UI language.
  void setVoiceLanguage(String code) {
    assert(code == 'en' || code == 'hi' || code == 'te',
        'Language code must be en, hi, or te. Got: $code');
    if (_voiceLanguage == code) return;
    _voiceLanguage = code;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a short language code to a full BCP-47 locale string.
  static String _localeFor(String code) {
    switch (code) {
      case 'hi': return 'hi-IN';
      case 'te': return 'te-IN';
      default:   return 'en-IN';
    }
  }

  /// Returns the native language name for a given language code.
  static String nativeName(String code) {
    switch (code) {
      case 'hi': return 'हिंदी';
      case 'te': return 'తెలుగు';
      default:   return 'English';
    }
  }

  /// Returns the English label for a given language code.
  static String englishName(String code) {
    switch (code) {
      case 'hi': return 'Hindi';
      case 'te': return 'Telugu';
      default:   return 'English';
    }
  }

  /// Converts legacy selectedLanguage strings (like 'తెలుగు', 'हिंदी') used
  /// by older screens into the short code used by this service.
  static String codeFromLegacy(String selectedLanguage) {
    final s = selectedLanguage.toLowerCase();
    if (s == 'te' || s.contains('తెలుగు')) return 'te';
    if (s == 'hi' || s.contains('हिंदी') || s.contains('hindi')) return 'hi';
    return 'en';
  }
}
