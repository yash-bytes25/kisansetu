// KisanSetu (SIH26032) - Voice Assistant Message Model
// Represents a single turn in a farmer voice conversation.

import 'voice_intent.dart';

/// Speaker role in voice conversation.
enum VoiceSender { user, assistant, system }

/// Operational mode for the voice assistant.
enum VoiceAssistantMode {
  /// Information retrieval (Queue, Go-Time, Token, Payment).
  ask,

  /// Actionable task execution (Book slot, Change crop/quantity, Dispute).
  doAction,

  /// Knowledge and policy guidance (MSP, CCEA rules, how it works).
  explain,
}

/// A single message turn within a voice assistant session.
class VoiceMessage {
  final String id;
  final VoiceSender sender;
  final String text;
  final DateTime timestamp;
  final VoiceIntent? intent;
  final VoiceAssistantMode mode;
  final bool isAudioPlayed;

  VoiceMessage({
    String? id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.intent,
    this.mode = VoiceAssistantMode.ask,
    this.isAudioPlayed = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  VoiceMessage copyWith({
    String? id,
    VoiceSender? sender,
    String? text,
    DateTime? timestamp,
    VoiceIntent? intent,
    VoiceAssistantMode? mode,
    bool? isAudioPlayed,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      intent: intent ?? this.intent,
      mode: mode ?? this.mode,
      isAudioPlayed: isAudioPlayed ?? this.isAudioPlayed,
    );
  }
}
