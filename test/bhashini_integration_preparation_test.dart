// KisanSetu (SIH26032) - Phase G-B0: Bhashini Integration Preparation Tests
// Validates:
// 1. Provider selection mechanism & mock default
// 2. Bhashini configuration validation & missing credential safety
// 3. Service contracts: ALD, ASR, NMT, TTS
// 4. Unsupported language handling
// 5. Provider failure handling & error taxonomy
// 6. Ephemeral audio payload contract
// 7. Safe offline fallback
// 8. Gemini architectural boundary (zero direct database mutations)
// 9. Mandatory farmer confirmation safety

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisansetu/models/voice/voice_audio_data.dart';
import 'package:kisansetu/models/voice/voice_intent.dart';
import 'package:kisansetu/services/ai/gemini_service.dart';
import 'package:kisansetu/services/bhashini/bhashini_ald_service.dart';
import 'package:kisansetu/services/bhashini/bhashini_asr_service.dart';
import 'package:kisansetu/services/bhashini/bhashini_config.dart';
import 'package:kisansetu/services/bhashini/bhashini_errors.dart';
import 'package:kisansetu/services/bhashini/bhashini_service.dart';
import 'package:kisansetu/services/bhashini/bhashini_translation_service.dart';
import 'package:kisansetu/services/bhashini/bhashini_tts_service.dart';
import 'package:kisansetu/services/procurement_state_service.dart';
import 'package:kisansetu/services/voice/mock_voice_providers.dart';
import 'package:kisansetu/services/voice/voice_assistant_service.dart';
import 'package:kisansetu/services/voice/voice_provider_interfaces.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Provider Selection & Mock Default', () {
    test('Mock provider is active by default during approval pending phase', () {
      final service = VoiceAssistantService.instance;
      expect(service.providerMode, equals(VoiceProviderMode.mock));
      expect(service.inputProvider, isA<MockVoiceInputProvider>());
      expect(service.outputProvider, isA<MockVoiceOutputProvider>());
      expect(service.intentProvider, isA<MockIntentProvider>());
    });

    test('Can switch to REAL_BHASHINI mode and back to DEMO/MOCK without code edits', () {
      final service = VoiceAssistantService.instance;

      service.setProviderMode(VoiceProviderMode.realBhashini);
      expect(service.providerMode, equals(VoiceProviderMode.realBhashini));
      expect(service.inputProvider, isA<BhashiniAsrService>());
      expect(service.outputProvider, isA<BhashiniTtsService>());
      expect(service.intentProvider, isA<GeminiService>());

      // Reset to mock default
      service.setProviderMode(VoiceProviderMode.mock);
      expect(service.providerMode, equals(VoiceProviderMode.mock));
      expect(service.inputProvider, isA<MockVoiceInputProvider>());
    });

    test('VoiceProviderMode parses string values safely', () {
      expect(VoiceProviderMode.fromString('REAL_BHASHINI'), equals(VoiceProviderMode.realBhashini));
      expect(VoiceProviderMode.fromString('bhashini'), equals(VoiceProviderMode.realBhashini));
      expect(VoiceProviderMode.fromString('DEMO/MOCK'), equals(VoiceProviderMode.mock));
      expect(VoiceProviderMode.fromString('unknown'), equals(VoiceProviderMode.mock));
    });
  });

  group('2. Bhashini Configuration & Credential Safety', () {
    test('Default BhashiniConfig has empty credentials and indicates pending approval', () {
      const config = BhashiniConfig();
      expect(config.userId, isEmpty);
      expect(config.apiKey, isEmpty);
      expect(config.pipelineEndpoint, isEmpty);
      expect(config.isConfigured, isFalse);
      expect(config.validate(), contains('pending official approval'));
    });

    test('BhashiniService reports pending approval status by default', () {
      final bhashini = BhashiniService.instance;
      expect(bhashini.isConfigured, isFalse);
      expect(bhashini.statusMessage, contains('approval pending'));
    });

    test('Language support capability checks behave correctly', () {
      const config = BhashiniConfig(
        aldConfig: BhashiniServiceConfig(
          supportedLanguages: ['en', 'hi', 'te'],
          isEnabled: true,
        ),
        asrConfig: BhashiniServiceConfig(
          supportedLanguages: ['en', 'hi', 'te'],
          isEnabled: true,
        ),
      );

      expect(config.isLanguageSupported(BhashiniServiceType.ald, 'hi'), isTrue);
      expect(config.isLanguageSupported(BhashiniServiceType.ald, 'te'), isTrue);
      expect(config.isLanguageSupported(BhashiniServiceType.ald, 'en'), isTrue);
      expect(config.isLanguageSupported(BhashiniServiceType.ald, 'fr'), isFalse);
      expect(config.isLanguageSupported(BhashiniServiceType.tts, 'hi'), isFalse); // not enabled
    });
  });

  group('3. Service Contracts: ALD, ASR, NMT, TTS', () {
    test('ALD (Audio Language Identification) handles empty audio and unconfigured state', () async {
      final ald = BhashiniAldService();
      expect(ald.isReady, isFalse);

      // Empty audio throws EmptyAudioException
      final emptyAudio = AudioPayload(
        bytes: Uint8List(0),
        mimeType: 'audio/wav',
        languageCode: 'en',
      );
      expect(() => ald.identifyLanguage(emptyAudio), throwsA(isA<EmptyAudioException>()));

      // Non-empty audio when unconfigured throws BhashiniUnavailableException
      final validAudio = AudioPayload(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'audio/wav',
        languageCode: 'en',
      );
      expect(() => ald.identifyLanguage(validAudio), throwsA(isA<BhashiniUnavailableException>()));
    });

    test('ASR (Speech Recognition) contract validates inputs and handles pending status', () async {
      final asr = BhashiniAsrService();
      expect(asr.isReady, isFalse);
      expect(asr.isListening, isFalse);

      String? errorMsg;
      final started = await asr.startListening(
        language: 'hi-IN',
        onResult: (_) {},
        onError: (err) => errorMsg = err,
      );

      expect(started, isFalse);
      expect(errorMsg, isNotNull);
      expect(errorMsg, contains('Voice service is temporarily unavailable'));

      // transcribeAudio on unconfigured throws BhashiniUnavailableException
      final audio = AudioPayload(
        bytes: Uint8List.fromList([10, 20, 30]),
        mimeType: 'audio/wav',
        languageCode: 'hi-IN',
      );
      expect(() => asr.transcribeAudio(audio), throwsA(isA<BhashiniUnavailableException>()));
    });

    test('TTS (Speech Synthesis) contract enforces valid inputs and handles pending status', () async {
      final tts = BhashiniTtsService();
      expect(tts.isReady, isFalse);
      expect(tts.isSpeaking, isFalse);

      // Blank text throws EmptyTranscriptException
      expect(
        () => tts.synthesizeAudio('', language: 'en-IN'),
        throwsA(isA<EmptyTranscriptException>()),
      );

      // Non-empty text when unconfigured throws BhashiniUnavailableException
      expect(
        () => tts.synthesizeAudio('Namaste', language: 'hi-IN'),
        throwsA(isA<BhashiniUnavailableException>()),
      );
    });

    test('NMT (Machine Translation) returns source text when identical or unconfigured', () async {
      final nmt = BhashiniTranslationService();
      expect(nmt.isReady, isFalse);

      // Same source and target
      final same = await nmt.translate(
        sourceText: 'Wheat',
        sourceLang: 'en',
        targetLang: 'en',
      );
      expect(same, equals('Wheat'));

      // Unconfigured translation gracefully falls back to source text
      final translated = await nmt.translate(
        sourceText: 'Namaste',
        sourceLang: 'hi',
        targetLang: 'en',
      );
      expect(translated, equals('Namaste'));
    });
  });

  group('4. Ephemeral Audio Data Handling', () {
    test('AudioPayload holds audio data strictly in memory with proper metadata', () {
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
      final payload = AudioPayload(
        bytes: bytes,
        mimeType: 'audio/wav',
        languageCode: 'te-IN',
        sampleRate: 16000,
        channels: 1,
      );

      expect(payload.isValid, isTrue);
      expect(payload.mimeType, equals('audio/wav'));
      expect(payload.languageCode, equals('te-IN'));
      expect(payload.sizeKb, closeTo(8.0 / 1024.0, 0.001));
      expect(payload.toString(), contains('audio/wav'));
    });
  });

  group('5. Error Taxonomy & Farmer-Safe Messages', () {
    test('Bhashini errors generate reassuring trilingual farmer messages without secrets', () {
      const unavail = BhashiniUnavailableException();
      expect(unavail.getUserFriendlyMessage(), contains('Voice service is temporarily unavailable'));
      expect(unavail.getUserFriendlyMessage(isHindi: true), contains('आवाज़ सेवा अस्थायी रूप से'));
      expect(unavail.getUserFriendlyMessage(isTelugu: true), contains('వాయిస్ సేవ తాత్కాలికంగా'));

      const badCreds = InvalidCredentialsException('Server key rejected');
      // Technical details must NOT be leaked
      expect(badCreds.getUserFriendlyMessage(), isNot(contains('Server key rejected')));
      expect(badCreds.getUserFriendlyMessage(), contains('Please type your request'));

      const unsuppLang = UnsupportedLanguageException('xx');
      expect(unsuppLang.getUserFriendlyMessage(), contains('not supported'));

      const emptyAud = EmptyAudioException();
      expect(emptyAud.getUserFriendlyMessage(), contains('No audio detected'));
    });
  });

  group('6. Offline Fallback & Failure Handling', () {
    test('Real Bhashini mode displays offline guidance when unconfigured', () async {
      final service = VoiceAssistantService.instance;
      service.setProviderMode(VoiceProviderMode.realBhashini);

      final listened = await service.startListening();
      expect(listened, isFalse);

      final lastMessage = service.session.messages.last;
      expect(lastMessage.text, equals('Voice service is temporarily unavailable. You can type your request instead.'));

      // Restore to mock
      service.setProviderMode(VoiceProviderMode.mock);
    });
  });

  group('7. Gemini Boundary & Zero Direct Database Mutation', () {
    test('GeminiService returns structured VoiceIntent without mutating database', () async {
      final gemini = GeminiService.instance;
      expect(gemini.isConfigured, isFalse);

      final initialCrop = ProcurementStateService.instance.farmerData.crop;

      final intent = await gemini.extractIntent(
        text: 'I want to book slot for 50 quintals of wheat',
        language: 'en-IN',
      );

      expect(intent, isA<VoiceIntent>());
      expect(intent.intent, equals(VoiceIntentType.unknown));

      // Verify that no bookings or crops were mutated in ProcurementStateService
      expect(ProcurementStateService.instance.farmerData.crop, equals(initialCrop));
    });

    test('Actionable intents strictly require farmer confirmation before any state mutation', () async {
      final service = VoiceAssistantService.instance;
      service.reset();

      // Reset state to baseline with Paddy
      ProcurementStateService.instance.updateFarmerBooking(
        centreName: 'Khanna Grain Market',
        bookedSlot: '11:30 AM',
        tokenNumber: 'KS-8821',
        crop: 'Paddy',
        quantity: '40 Quintals',
      );

      final initialCrop = ProcurementStateService.instance.farmerData.crop;
      expect(initialCrop, equals('Paddy'));

      // Send actionable booking intent to VoiceAssistantService for Cotton
      await service.processUserInput('Book cotton slot for 50 kg tomorrow');

      // The intent must be flagged as requiring confirmation
      final current = service.session.currentIntent;
      expect(current, isNotNull);
      expect(current!.requiresConfirmation, isTrue);

      // Bookings in database must NOT be modified yet (still Paddy)
      expect(ProcurementStateService.instance.farmerData.crop, equals('Paddy'));

      // Only upon explicit confirmation does it mutate
      await service.confirmAction();

      // Queue and booking now reflect confirmed action (Cotton)
      expect(ProcurementStateService.instance.farmerData.crop, equals('Cotton'));
    });
  });
}
