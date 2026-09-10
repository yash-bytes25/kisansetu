// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;
import 'voice_assistant_speech_service.dart';

/// Factory returning the Chrome Web implementation.
VoiceAssistantSpeechService createVoiceSpeechService() =>
    VoiceAssistantSpeechWeb();

/// Chrome Web implementation of [VoiceAssistantSpeechService].
///
/// STRATEGY:
///   • Telugu / Hindi  → Google Translate TTS (audio element, no voice install needed)
///   • English         → Web Speech API (reliable natively on all platforms)
///
/// WHY Google Translate TTS for regional languages:
///   Chrome's Web Speech API on Windows uses only locally installed TTS voices.
///   Windows ships with NO Telugu or Hindi TTS voice by default.  Setting
///   `utterance.lang = 'te-IN'` without a matching installed voice causes Chrome
///   to silently fall back to its default English voice.
///   The Google Translate TTS endpoint returns proper audio for any BCP-47
///   language code without requiring any system voice installation, making it
///   the only reliable option for regional languages in a browser demo context.
class VoiceAssistantSpeechWeb implements VoiceAssistantSpeechService {
  bool _speaking = false;
  String? _lastText;
  String? _lastLocale;
  bool _jsInjected = false;

  // ── JavaScript helper injection ────────────────────────────────────────────

  void _ensureJsInjected() {
    if (_jsInjected) return;
    _jsInjected = true;
    try {
      // Inject via <script> element (avoids CSP eval restriction)
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = _jsHelperCode;
      html.document.head!.children.add(script);
    } catch (_) {
      // Script element injection failed — try eval fallback
      try {
        js.context.callMethod('eval', [_jsHelperCode]);
      } catch (_) {}
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  bool get isSupported {
    try {
      return html.window.speechSynthesis != null;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isSpeaking => _speaking;

  @override
  void stop() {
    try {
      _ensureJsInjected();
      js.context.callMethod('__kisanSetuStop', []);
    } catch (_) {
      try {
        html.window.speechSynthesis?.cancel();
      } catch (_) {}
    }
    _speaking = false;
  }

  @override
  void speak(String text, {String? language}) {
    try {
      _ensureJsInjected();
      stop();

      final cleanText = text.trim();
      if (cleanText.isEmpty) return;

      final locale = VoiceAssistantSpeechService.resolveLocale(language);
      _lastText   = cleanText;
      _lastLocale = locale;
      _speaking   = true;

      js.context.callMethod('__kisanSetuSpeak', [cleanText, locale]);

      // Reset speaking flag after generous timeout (JS callbacks not wired back)
      Future.delayed(const Duration(seconds: 30), () => _speaking = false);
    } catch (_) {
      _speaking = false;
    }
  }

  /// Exposed for diagnostic inspection.
  String? get lastText   => _lastText;
  String? get lastLocale => _lastLocale;
}

// ── Injected JavaScript ──────────────────────────────────────────────────────
//
// Kept as a const string so it is tree-shaken when not on web.
const String _jsHelperCode = r'''
(function () {
  "use strict";

  // ── Text chunking (Google TTS ~200 char limit) ─────────────────────────
  function splitChunks(text, maxChars) {
    if (!text || text.length === 0) return [];
    if (text.length <= maxChars) return [text];
    var chunks = [];
    var rem = text;
    var seps = ['. ', '। ', ', ', ' '];
    while (rem.length > maxChars) {
      var cut = maxChars;
      for (var s = 0; s < seps.length; s++) {
        var idx = rem.lastIndexOf(seps[s], maxChars - 1);
        if (idx > maxChars * 0.35) { cut = idx + seps[s].length; break; }
      }
      chunks.push(rem.substring(0, cut).trim());
      rem = rem.substring(cut).trim();
    }
    if (rem.length > 0) chunks.push(rem);
    return chunks;
  }

  // ── Google Translate TTS (primary for te / hi) ─────────────────────────
  // Uses the <audio> element which is NOT subject to CORS restrictions,
  // so it works even though translate.google.com has no CORS headers.
  // The `client=tw-ob` parameter selects the "Translate for Android" voice
  // which provides natural-sounding multilingual audio.
  function playGoogleTTS(text, langCode, onFail) {
    var chunks = splitChunks(text, 190);
    if (chunks.length === 0) return;
    var idx = 0;

    function next() {
      if (idx >= chunks.length) {
        window.__ksAudio = null;
        return;
      }
      var chunk = chunks[idx++];
      var url =
        "https://translate.google.com/translate_tts" +
        "?ie=UTF-8" +
        "&q="       + encodeURIComponent(chunk) +
        "&tl="      + encodeURIComponent(langCode) +
        "&client=tw-ob" +
        "&ttsspeed=0.90";

      var audio = new Audio(url);
      window.__ksAudio = audio;
      audio.onended = next;
      audio.onerror = function () {
        window.__ksAudio = null;
        if (onFail) onFail();
        onFail = null; // only call once
      };

      var p = audio.play();
      if (p && typeof p.catch === "function") {
        p.catch(function (err) {
          window.__ksAudio = null;
          if (onFail) onFail();
          onFail = null;
        });
      }
    }
    next();
  }

  // ── Web Speech API (primary for en, fallback for others) ───────────────
  function playWebSpeech(text, lang) {
    var synth = window.speechSynthesis;
    if (!synth) return;
    var utt = new SpeechSynthesisUtterance(text);
    utt.lang  = lang;
    utt.rate  = 0.92;
    utt.pitch = 1.0;
    // Do NOT set utt.voice — let the browser match via utt.lang.
    // Assigning an explicit voice (especially a mismatched English one)
    // would override the lang setting and produce English audio.
    synth.speak(utt);
  }

  // ── Public interface ───────────────────────────────────────────────────
  window.__kisanSetuSpeak = function (text, lang) {
    window.__kisanSetuStop();

    var langCode = lang.split("-")[0].toLowerCase(); // "te", "hi", "en"

    if (langCode === "te" || langCode === "hi") {
      // Regional languages: use Google Translate TTS which doesn't need
      // any system voice and always produces the correct language audio.
      playGoogleTTS(text, langCode, function () {
        // If network call fails (offline / blocked), try Web Speech API.
        playWebSpeech(text, lang);
      });
    } else {
      // English: Web Speech API is reliable and sounds better.
      playWebSpeech(text, lang);
    }
  };

  window.__kisanSetuStop = function () {
    // Stop Web Speech
    var synth = window.speechSynthesis;
    if (synth) { try { synth.cancel(); } catch (e) {} }
    // Stop any playing audio element
    var a = window.__ksAudio;
    if (a) {
      a.onended = null;
      a.onerror = null;
      try { a.pause(); } catch (e) {}
      window.__ksAudio = null;
    }
  };

  window.__ksAudio = null;

  // Pre-warm Web Speech voice list so English is ready instantly
  if (window.speechSynthesis) {
    window.speechSynthesis.getVoices();
  }
})();
''';
