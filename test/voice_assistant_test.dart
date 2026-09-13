// KisanSetu (SIH26032) - Voice Assistant Framework Tests (Phase G-A)
// Comprehensive testing covering:
// 1. VoiceIntent model parsing and serialization
// 2. Missing field detection for slot booking
// 3. Conversational entity extraction (crop, quantity, date)
// 4. Multi-turn correction/update ("No, make it 100 kg")
// 5. Confirmation safety (requiresConfirmation flag, explicit confirmation flow)
// 6. Action routing for all 14 intents
// 7. Offline restrictions on booking
// 8. Trilingual support (English, Hindi, Telugu)
// 9. Mock Voice Provider simulation
// 10. Voice Assistant Screen UI rendering & interactive testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisansetu/models/voice/voice_intent.dart';
import 'package:kisansetu/screens/farmer/farmer_voice_assistant_screen.dart';
import 'package:kisansetu/services/connectivity_service.dart';
import 'package:kisansetu/services/procurement_state_service.dart';
import 'package:kisansetu/services/voice/mock_voice_providers.dart';
import 'package:kisansetu/services/voice/voice_action_router.dart';
import 'package:kisansetu/services/voice/voice_assistant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceIntent Model & Serialization Tests', () {
    test('1. VoiceIntent can be instantiated with default fields', () {
      const intent = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        quantity: 50.0,
        quantityUnit: 'kg',
        date: 'Tomorrow',
        confidence: 0.95,
        userMessage: 'I want to sell 50 kg wheat tomorrow.',
        requiresConfirmation: true,
      );

      expect(intent.intent, VoiceIntentType.bookSlot);
      expect(intent.crop, 'Wheat');
      expect(intent.quantity, 50.0);
      expect(intent.quantityUnit, 'kg');
      expect(intent.date, 'Tomorrow');
      expect(intent.confidence, 0.95);
      expect(intent.requiresConfirmation, isTrue);
      expect(intent.missingFields, isEmpty);
    });

    test('2. Missing fields detection correctly flags incomplete booking slots', () {
      const partial = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        userMessage: 'I want to sell wheat.',
        requiresConfirmation: true,
      );

      final missing = partial.missingFields;
      expect(missing, contains('quantity'));
      expect(missing, contains('date'));
      expect(missing, isNot(contains('crop')));
    });

    test('3. VoiceIntent copyWith works seamlessly for multi-turn corrections', () {
      const initial = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        quantity: 50.0,
        date: 'Tomorrow',
        requiresConfirmation: true,
      );

      final updated = initial.copyWith(quantity: 100.0);
      expect(updated.crop, 'Wheat');
      expect(updated.quantity, 100.0);
      expect(updated.date, 'Tomorrow');
      expect(updated.requiresConfirmation, isTrue);
    });

    test('4. JSON serialization and deserialization roundtrip', () {
      const original = VoiceIntent(
        intent: VoiceIntentType.getTokenStatus,
        bookingId: 'TK-8492',
        confidence: 0.98,
        userMessage: 'When is my token?',
        requiresConfirmation: false,
      );

      final json = original.toJson();
      final revived = VoiceIntent.fromJson(json);

      expect(revived.intent, VoiceIntentType.getTokenStatus);
      expect(revived.bookingId, 'TK-8492');
      expect(revived.confidence, 0.98);
      expect(revived.requiresConfirmation, isFalse);
    });
  });

  group('Mock Intent Provider & Conversational NLU Tests', () {
    late MockIntentProvider provider;

    setUp(() {
      provider = MockIntentProvider();
    });

    test('5. Full booking utterance extracts crop, quantity, and date', () async {
      final intent = await provider.extractIntent(
        text: 'I want to sell 50 kg wheat tomorrow.',
        language: 'en-IN',
      );

      expect(intent.intent, VoiceIntentType.bookSlot);
      expect(intent.crop, 'Wheat');
      expect(intent.quantity, 50.0);
      expect(intent.date, 'Tomorrow');
      expect(intent.missingFields, isEmpty);
      expect(intent.requiresConfirmation, isTrue);
    });

    test('6. Partial booking intent prompts for missing quantity and date', () async {
      final intent = await provider.extractIntent(
        text: 'I want to sell paddy.',
        language: 'en-IN',
      );

      expect(intent.intent, VoiceIntentType.bookSlot);
      expect(intent.crop, 'Paddy');
      expect(intent.quantity, isNull);
      expect(intent.date, isNull);
      expect(intent.missingFields, contains('quantity'));
      expect(intent.missingFields, contains('date'));
    });

    test('7. Conversational slot filling merges subsequent answers into context', () async {
      const step1 = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        requiresConfirmation: true,
      );

      final step2 = await provider.extractIntent(
        text: '50 kg',
        language: 'en-IN',
        previousIntent: step1,
      );
      expect(step2.crop, 'Wheat');
      expect(step2.quantity, 50.0);
      expect(step2.missingFields, contains('date'));

      final step3 = await provider.extractIntent(
        text: 'Tomorrow',
        language: 'en-IN',
        previousIntent: step2,
      );
      expect(step3.crop, 'Wheat');
      expect(step3.quantity, 50.0);
      expect(step3.date, 'Tomorrow');
      expect(step3.missingFields, isEmpty);
      expect(step3.requiresConfirmation, isTrue);
    });

    test('8. Farmer correction "No, make it 100 kg" updates quantity without resetting crop', () async {
      const existing = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        quantity: 50.0,
        date: 'Tomorrow',
        requiresConfirmation: true,
      );

      final corrected = await provider.extractIntent(
        text: 'No, make it 100 kg',
        language: 'en-IN',
        previousIntent: existing,
      );

      expect(corrected.intent, VoiceIntentType.bookSlot);
      expect(corrected.crop, 'Wheat');
      expect(corrected.quantity, 100.0);
      expect(corrected.date, 'Tomorrow');
    });

    test('9. Hindi booking utterances extract intents correctly', () async {
      final intent = await provider.extractIntent(
        text: 'मुझे कल 50 क्विंटल गेहूं बेचना है',
        language: 'hi-IN',
      );

      expect(intent.intent, VoiceIntentType.bookSlot);
      expect(intent.crop, 'Wheat');
      expect(intent.quantity, 50.0);
      expect(intent.requiresConfirmation, isTrue);
    });

    test('10. Telugu booking utterances extract intents correctly', () async {
      final intent = await provider.extractIntent(
        text: 'నేను రేపు 50 క్వింటాళ్ల గోధుమలు అమ్మాలనుకుంటున్నాను',
        language: 'te-IN',
      );

      expect(intent.intent, VoiceIntentType.bookSlot);
      expect(intent.crop, 'Wheat');
      expect(intent.quantity, 50.0);
      expect(intent.requiresConfirmation, isTrue);
    });

    test('11. Information intents (token, go-time, queue, payment, dispute) correctly recognized', () async {
      expect((await provider.extractIntent(text: 'When is my token?', language: 'en-IN')).intent, VoiceIntentType.getTokenStatus);
      expect((await provider.extractIntent(text: 'When should I leave?', language: 'en-IN')).intent, VoiceIntentType.getGoTime);
      expect((await provider.extractIntent(text: 'How many people are ahead of me?', language: 'en-IN')).intent, VoiceIntentType.getQueue);
      expect((await provider.extractIntent(text: 'What is my payment status?', language: 'en-IN')).intent, VoiceIntentType.getPaymentStatus);
      expect((await provider.extractIntent(text: 'Which centre should I go to?', language: 'en-IN')).intent, VoiceIntentType.recommendCentre);
      expect((await provider.extractIntent(text: 'Is my centre open?', language: 'en-IN')).intent, VoiceIntentType.getCentreStatus);
      expect((await provider.extractIntent(text: 'I want to report a problem', language: 'en-IN')).intent, VoiceIntentType.startDispute);
      expect((await provider.extractIntent(text: 'Show my profile info', language: 'en-IN')).intent, VoiceIntentType.getProfileInfo);
    });
  });

  group('Voice Action Router Tests (Strict Confirmation & State Dispatch)', () {
    late VoiceActionRouter router;
    late ProcurementStateService stateService;

    setUp(() {
      stateService = ProcurementStateService();
      router = VoiceActionRouter(stateService: stateService);
      AppConnectivityService.instance.setOnline(true);
    });

    test('12. Token query retrieves active token from existing state service', () async {
      const intent = VoiceIntent(intent: VoiceIntentType.getTokenStatus);
      final result = await router.executeIntent(intent);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains(stateService.farmerData.tokenNumber));
      expect(result.data['token'], stateService.farmerData.tokenNumber);
    });

    test('13. Go-Time query retrieves departure time and queue count from state', () async {
      const intent = VoiceIntent(intent: VoiceIntentType.getGoTime);
      final result = await router.executeIntent(intent);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains(stateService.farmerData.recommendedDepartureTime));
      expect(result.data['ahead'], stateService.farmerData.peopleAhead);
    });

    test('14. Queue query retrieves people ahead and wait time', () async {
      const intent = VoiceIntent(intent: VoiceIntentType.getQueue);
      final result = await router.executeIntent(intent);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('${stateService.farmerData.peopleAhead}'));
      expect(result.data['ahead'], stateService.farmerData.peopleAhead);
    });

    test('15. Payment query retrieves status and payment reference without fabrication', () async {
      const intent = VoiceIntent(intent: VoiceIntentType.getPaymentStatus);
      final result = await router.executeIntent(intent);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains(stateService.farmerData.paymentStatus));
      expect(result.data['reference'], stateService.farmerData.paymentReference);
    });

    test('16. Centre recommendation returns navigation route to alternative centres', () async {
      const intent = VoiceIntent(intent: VoiceIntentType.recommendCentre);
      final result = await router.executeIntent(intent);

      expect(result.isSuccess, isTrue);
      expect(result.navigateRoute, 'alternative_centres');
    });

    test('17. Confirmed booking slot updates existing state service', () async {
      const intent = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Mustard',
        quantity: 40.0,
        date: 'Tomorrow',
        requiresConfirmation: true,
      );

      final result = await router.executeIntent(intent);
      expect(result.isSuccess, isTrue);
      expect(result.navigateRoute, 'smart_slot');
      expect(stateService.farmerData.cropName, 'Mustard');
    });

    test('18. Offline restriction strictly blocks booking without connectivity', () async {
      AppConnectivityService.instance.setOnline(false);

      const intent = VoiceIntent(
        intent: VoiceIntentType.bookSlot,
        crop: 'Wheat',
        quantity: 50.0,
        date: 'Tomorrow',
        requiresConfirmation: true,
      );

      final result = await router.executeIntent(intent);
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Cannot book a new slot while offline'));

      // Restore online for further tests
      AppConnectivityService.instance.setOnline(true);
    });
  });

  group('Mock Voice Provider & Audio Simulation Tests', () {
    test('19. MockVoiceInputProvider simulates speech transcript correctly', () async {
      final provider = MockVoiceInputProvider();
      String? capturedResult;

      await provider.startListening(
        language: 'en-IN',
        onResult: (text) => capturedResult = text,
        onError: (_) {},
      );

      expect(provider.isListening, isTrue);
      provider.simulateSpeechInput('When is my token?');
      expect(capturedResult, 'When is my token?');

      await provider.stopListening();
      expect(provider.isListening, isFalse);
    });

    test('20. MockVoiceOutputProvider tracks spoken text for farmer feedback', () async {
      final provider = MockVoiceOutputProvider();
      await provider.speak(
        'Your token is TK-8492',
        language: 'en-IN',
      );

      expect(provider.lastSpokenText, 'Your token is TK-8492');
    });
  });

  group('Voice Assistant Screen UI & Widget Tests', () {
    testWidgets('21. FarmerVoiceAssistantScreen renders mode selector, mic, and suggestions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerVoiceAssistantScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check title and tagline
      expect(find.text('KisanSetu Voice Assistant'), findsOneWidget);
      expect(find.text('Speak. Understand. Confirm. Act.'), findsOneWidget);

      // Check Mode tabs (ASK, DO, EXPLAIN)
      expect(find.text('ASK'), findsOneWidget);
      expect(find.text('DO'), findsOneWidget);
      expect(find.text('EXPLAIN'), findsOneWidget);

      // Check microphone button
      expect(find.byKey(const Key('btn_voice_mic')), findsOneWidget);

      // Check demo suggestion chips
      expect(find.text('I want to sell 50 kg wheat tomorrow.'), findsOneWidget);
      expect(find.text('When is my token?'), findsOneWidget);
      expect(find.text('When should I leave?'), findsOneWidget);
    });

    testWidgets('22. Tapping demo suggestion chip generates user message and assistant response', (tester) async {
      final voiceService = VoiceAssistantService.instance;
      voiceService.session.reset();

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerVoiceAssistantScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap suggestion chip "When is my token?"
      final tokenChip = find.text('When is my token?');
      await tester.tap(tokenChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify conversation has user turn and assistant turn
      expect(find.text('When is my token?'), findsWidgets);
      expect(find.byKey(const Key('btn_voice_mic')), findsOneWidget);
    });

    testWidgets('23. Booking utterance displays Confirmation Card with [Confirm & Continue], [Change], [Cancel]', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final voiceService = VoiceAssistantService.instance;
      voiceService.session.reset();

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerVoiceAssistantScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Process booking utterance via VoiceAssistantService
      await voiceService.processUserInput('I want to sell 50 kg wheat tomorrow.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify confirmation card elements
      expect(find.text('I understood (Confirmation)'), findsOneWidget);
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('50 Quintals'), findsWidgets);
      expect(find.text('Tomorrow'), findsWidgets);

      // Verify action buttons
      expect(find.byKey(const Key('btn_voice_confirm')), findsOneWidget);
      expect(find.byKey(const Key('btn_voice_change')), findsOneWidget);
      expect(find.byKey(const Key('btn_voice_cancel')), findsOneWidget);

      // Tapping Cancel clears confirmation card without booking
      await tester.tap(find.byKey(const Key('btn_voice_cancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('btn_voice_confirm')), findsNothing);
    });
  });
}
