// KisanSetu (SIH26032) - Voice Audio Data Contract
// Models in-memory audio payloads for speech recognition (ASR) and synthesis (TTS).
//
// PRIVACY & SECURITY DIRECTIVE:
// Farmer audio data is strictly ephemeral and held in memory only during processing.
// Never persist raw audio payloads to SQLite, Supabase, local files, or external logging.

import 'dart:typed_data';

/// Supported audio encoding / MIME types for voice pipeline.
enum AudioFormat {
  wav('audio/wav'),
  webm('audio/webm'),
  flac('audio/flac'),
  mp4('audio/mp4'),
  pcm('audio/pcm');

  const AudioFormat(this.mimeType);
  final String mimeType;

  static AudioFormat fromMimeType(String mime) {
    return AudioFormat.values.firstWhere(
      (f) => f.mimeType.toLowerCase() == mime.toLowerCase(),
      orElse: () => AudioFormat.wav,
    );
  }
}

/// In-memory audio payload passed between microphone, ASR, ALD, and TTS services.
class AudioPayload {
  const AudioPayload({
    required this.bytes,
    required this.mimeType,
    required this.languageCode,
    this.transcript,
    this.confidence,
    this.responseAudio,
    this.sampleRate = 16000,
    this.channels = 1,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _DefaultTimestamp();

  /// Ephemeral raw audio bytes (PCM/WAV/WebM).
  final Uint8List bytes;

  /// MIME type string, e.g., 'audio/wav', 'audio/webm'.
  final String mimeType;

  /// BCP-47 language tag, e.g., 'en-IN', 'hi-IN', 'te-IN'.
  final String languageCode;

  /// Recognized speech transcript (if returned by ASR).
  final String? transcript;

  /// Recognition confidence score (0.0 - 1.0) if provided by ASR engine.
  final double? confidence;

  /// Synthesized response audio from TTS engine (if applicable).
  final Uint8List? responseAudio;

  /// Audio sampling rate in Hz (standard 16000 for speech recognition).
  final int sampleRate;

  /// Number of audio channels (1 = mono, 2 = stereo).
  final int channels;

  /// Generation timestamp for latency measurements.
  final dynamic timestamp;

  /// Whether the payload contains valid non-empty audio data.
  bool get isValid => bytes.isNotEmpty;

  /// Audio size in kilobytes.
  double get sizeKb => bytes.lengthInBytes / 1024.0;

  AudioPayload copyWith({
    Uint8List? bytes,
    String? mimeType,
    String? languageCode,
    String? transcript,
    double? confidence,
    Uint8List? responseAudio,
    int? sampleRate,
    int? channels,
  }) {
    return AudioPayload(
      bytes: bytes ?? this.bytes,
      mimeType: mimeType ?? this.mimeType,
      languageCode: languageCode ?? this.languageCode,
      transcript: transcript ?? this.transcript,
      confidence: confidence ?? this.confidence,
      responseAudio: responseAudio ?? this.responseAudio,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'AudioPayload(format: $mimeType, lang: $languageCode, bytes: ${bytes.lengthInBytes}, hasTranscript: ${transcript != null})';
  }
}

class _DefaultTimestamp {
  const _DefaultTimestamp();
  DateTime get now => DateTime.now();
}
