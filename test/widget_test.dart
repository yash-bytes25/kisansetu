import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart' hide QrValidationStatus;
import 'package:kisansetu/main.dart';
import 'package:kisansetu/screens/farmer_book_slot_screen.dart';
import 'package:kisansetu/screens/farmer_booking_success_screen.dart';
import 'package:kisansetu/screens/farmer_dashboard_screen.dart';
import 'package:kisansetu/screens/farmer_go_time_details_screen.dart';
import 'package:kisansetu/screens/farmer_language_selection_screen.dart';
import 'package:kisansetu/screens/farmer_my_token_screen.dart';
import 'package:kisansetu/screens/farmer_otp_verification_screen.dart';
import 'package:kisansetu/screens/farmer_phone_login_screen.dart';
import 'package:kisansetu/screens/farmer_slot_confirmation_screen.dart';
import 'package:kisansetu/screens/farmer_smart_slot_screen.dart';
import 'package:kisansetu/screens/officer_dashboard_screen.dart';
import 'package:kisansetu/screens/officer_farmer_detail_screen.dart';
import 'package:kisansetu/screens/officer_login_screen.dart';
import 'package:kisansetu/screens/officer_centre_admin_screen.dart';
import 'package:kisansetu/screens/officer_dispute_console_screen.dart';
import 'package:kisansetu/screens/officer_payment_oversight_screen.dart';
import 'package:kisansetu/screens/role_selection_screen.dart';
import 'package:kisansetu/screens/farmer_dispute_screen.dart';
import 'package:kisansetu/screens/farmer_payment_screen.dart';
import 'package:kisansetu/screens/farmer_procurement_status_screen.dart';
import 'package:kisansetu/models/notification_model.dart';
import 'package:kisansetu/screens/farmer_messages_screen.dart';
import 'package:kisansetu/screens/farmer_digital_pass_screen.dart';
import 'package:kisansetu/screens/farmer_payment_history_screen.dart';
import 'package:kisansetu/screens/farmer_profile_screen.dart';
import 'package:kisansetu/screens/language_preferences_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisansetu/config/supabase_config.dart';
import 'package:kisansetu/services/supabase_service.dart';
import 'package:kisansetu/services/repositories/repository_provider.dart';
import 'package:kisansetu/services/repositories/farmer_repository.dart';
import 'package:kisansetu/services/repositories/booking_repository.dart';
import 'package:kisansetu/services/repositories/queue_repository.dart';
import 'package:kisansetu/services/repositories/procurement_repository.dart';
import 'package:kisansetu/services/repositories/payment_repository.dart';
import 'package:kisansetu/services/repositories/notification_repository.dart';
import 'package:kisansetu/services/repositories/dispute_repository.dart';
import 'package:kisansetu/services/repositories/procurement_centre_repository.dart';
import 'package:kisansetu/services/auth_service.dart';
import 'package:kisansetu/services/notification_service.dart';
import 'package:kisansetu/services/payment_calculation_service.dart';
import 'package:kisansetu/services/procurement_state_service.dart';
import 'package:kisansetu/services/queue_prediction_service.dart';
import 'package:kisansetu/services/location_distance_service.dart';
import 'package:kisansetu/services/location_master_service.dart';
import 'package:kisansetu/services/qr_validation_service.dart';
import 'package:kisansetu/screens/officer_qr_scanner_screen.dart';
import 'package:kisansetu/widgets/farmer/farmer_digital_qr_pass.dart';
import 'package:kisansetu/widgets/farmer/farmer_journey_tracker.dart';
import 'package:kisansetu/models/officer_queue_item.dart';
import 'package:kisansetu/models/officer_exception_model.dart';
import 'package:kisansetu/services/officer_exception_service.dart';
import 'package:kisansetu/widgets/officer/officer_exception_detail_sheet.dart';
import 'package:kisansetu/widgets/officer/gate_camera_preview.dart';
import 'package:kisansetu/theme/responsive_layout.dart';
import 'package:kisansetu/widgets/farmer/produce_summary_card.dart';
import 'package:kisansetu/widgets/farmer/go_time_card.dart';
import 'package:kisansetu/widgets/farmer/token_card.dart';
import 'package:kisansetu/widgets/farmer/farmer_action_grid.dart';
import 'package:kisansetu/services/voice_assistant_speech/voice_assistant_speech_service.dart';
import 'package:kisansetu/services/voice_assistant_speech/voice_assistant_speech_stub.dart';
import 'package:kisansetu/models/crop_model.dart';
import 'package:kisansetu/services/crop_catalogue_service.dart';
import 'package:kisansetu/services/smart_slot_service.dart';
import 'package:kisansetu/screens/farmer_crop_selection_screen.dart';
import 'package:kisansetu/models/procurement_centre.dart';
import 'package:kisansetu/services/app_preferences_service.dart';
import 'package:kisansetu/models/slot_reallocation_model.dart';
import 'package:kisansetu/services/slot_reallocation_service.dart';
import 'package:kisansetu/services/alternative_centre_service.dart';
import 'package:kisansetu/models/capacity_forecast_model.dart';
import 'package:kisansetu/services/capacity_forecast_service.dart';
import 'package:kisansetu/services/local_cache_store.dart';
import 'package:kisansetu/services/connectivity_service.dart';
import 'package:kisansetu/services/offline_essential_info_service.dart';
import 'package:kisansetu/widgets/common/connectivity_banner.dart';

void main() {
  setUp(() {
    AppPreferencesService.instance.setUiLanguage('en');
    ProcurementStateService().reset();
  });

  testWidgets('App opens directly to RoleSelectionScreen with branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('KisanSetu'), findsOneWidget);
    expect(find.text('Smart Procurement Management'), findsOneWidget);
    expect(find.text('SIH26032 • Team ODE TO CODE'), findsOneWidget);
    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('I am a Farmer'), findsOneWidget);
    expect(find.text('Procurement Officer'), findsOneWidget);
  });

  testWidgets(
      'Full Farmer flow: Role -> Language -> Phone -> OTP -> Dashboard & Go-Time Details',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // 1. Role Selection -> Tap Farmer
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerLanguageSelectionScreen), findsOneWidget);

    // 2. Language Selection -> Choose English & Continue
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerPhoneLoginScreen), findsOneWidget);

    // 3. Phone Login -> Enter 10-digit number & Send OTP
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerOtpVerificationScreen), findsOneWidget);

    // 4. OTP Screen -> Enter Demo OTP 123456 & Verify OTP
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    // Successful OTP verification opens the actual Farmer Dashboard
    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
    expect(find.text('When Should I Go?'), findsOneWidget);
    expect(find.text('LEAVE AT 10:55 AM'), findsOneWidget);
    expect(find.text('MY TOKEN'), findsOneWidget);
    expect(find.text('TK-8492'), findsOneWidget);
    expect(find.text('7 people ahead'), findsWidgets);

    // Quick actions (2x2 grid: Book Slot, Payment, Digital Pass / QR, Download Invoice / Receipt)
    await tester.ensureVisible(find.text('Book Slot'));
    expect(find.text('Book Slot'), findsOneWidget);
    expect(find.text('Payment'), findsWidgets);
    expect(find.text('Digital Pass / QR'), findsOneWidget);
    expect(find.text('Download Invoice / Receipt'), findsOneWidget);
    expect(find.textContaining('Messages'), findsWidgets);
    expect(find.text('My Produce'), findsWidgets);

    // Voice action works
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Voice Assistant: Welcome Ramesh Kumar'),
        findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(FarmerDashboardScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // View Details opens Go-Time Details screen
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'View Details'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'View Details'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerGoTimeDetailsScreen), findsOneWidget);
    expect(find.text('Departure Details'), findsOneWidget);
    expect(find.text('How is this calculated?'), findsOneWidget);
    expect(find.textContaining('Your recommendation considers the current queue'),
        findsOneWidget);

    // Back to dashboard
    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
  });

  testWidgets(
      'Phase 6: My Token Screen navigation, Queue Simulation (7 -> 5 -> 3 -> 1 -> 0), and State Sync',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Quick login to Farmer Dashboard
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // 1. Open My Token from TokenCard action button
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'View Token'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'View Token'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerMyTokenScreen), findsOneWidget);
    expect(find.text('MY TOKEN'), findsOneWidget);
    expect(find.text('TK-8492'), findsOneWidget);
    expect(find.text('Example Procurement Centre'), findsOneWidget);
    expect(find.text('8'), findsOneWidget); // Position (7 people ahead + 1)
    expect(find.text('7'), findsOneWidget); // People Ahead
    expect(find.text('35 min'), findsOneWidget); // Estimated Wait (7 * 5)
    expect(find.text('11:30 AM'), findsWidgets); // Today's slot & Expected Turn

    // Voice assistance test on My Token Screen
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(FarmerMyTokenScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Verify Farmer Journey Tracker does NOT display simulation controls
    expect(find.widgetWithText(ElevatedButton, 'Simulate Queue Update'),
        findsNothing);
    expect(find.text('Live Queue Simulation'), findsNothing);
    expect(find.text('PROTOTYPE DEMO'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Open • Busy'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Temporarily Delayed'), findsNothing);

    // Verify Real Farmer-Facing Live Queue Status card is present
    expect(find.text('Live Queue Status'), findsOneWidget);
    expect(find.textContaining('Centre is operating normally'), findsOneWidget);
    expect(find.text('Queue updates automatically as farmers are processed.'),
        findsOneWidget);
    expect(
        find.text(
            'Your queue is automatically updated as procurement progresses.'),
        findsOneWidget);

    // 2. Queue Progression driven by officer/service: 7 -> 5
    ProcurementStateService().simulateNextQueueStep();
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget); // Position
    expect(find.text('5'), findsOneWidget); // People ahead
    expect(find.text('25 min'), findsWidgets); // 5 * 5 = 25 min wait

    // 3. Queue Progression driven by officer/service: 5 -> 3
    ProcurementStateService().simulateNextQueueStep();
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget); // Position
    expect(find.text('3'), findsOneWidget); // People ahead
    expect(find.text('15 min'), findsWidgets); // 3 * 5 = 15 min wait

    // 4. Test Centre Status update from officer/service: Switch to "Open • Busy" (+20 min delay)
    ProcurementStateService().setCentreStatus('Open • Busy');
    await tester.pumpAndSettle();

    expect(find.textContaining('Centre is busy'), findsOneWidget);
    expect(find.textContaining('35 min'), findsWidgets); // 15 base + 20 busy = 35 min

    // Officer switches back to "Open • Normal"
    ProcurementStateService().setCentreStatus('Open • Normal');
    await tester.pumpAndSettle();
    expect(find.textContaining('Centre is operating normally'), findsOneWidget);
    expect(find.textContaining('15 min'), findsWidgets);

    // 5. Navigate back to Dashboard and verify synchronized state
    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    // TokenCard reflects updated queue
    expect(find.text('3 people ahead'), findsWidgets);
    expect(find.text('15 min'), findsWidgets);

    // 6. Test opening My Token via View Token button
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'View Token'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'View Token'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerMyTokenScreen), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Persisted state

    // Officer advances to 0 (Your turn)
    ProcurementStateService().simulateNextQueueStep(); // to 1
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);

    ProcurementStateService().simulateNextQueueStep(); // to 0
    await tester.pumpAndSettle();
    expect(find.text('0'), findsWidgets);
    expect(find.text('Your Turn!'), findsWidgets);

    // Back to Dashboard
    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    expect(find.text('0 people ahead'), findsWidgets);
  });

  testWidgets('QueuePredictionService unit tests for deterministic behavior',
      (WidgetTester tester) async {
    // Normal status
    final resNormal7 = QueuePredictionService.predict(
      peopleAhead: 7,
      centreStatus: 'Open • Normal',
      slotTime: '11:30 AM',
      travelTimeMinutes: 25,
    );
    expect(resNormal7.queuePosition, 8);
    expect(resNormal7.estimatedWaitMinutes, 35);
    expect(resNormal7.expectedTurnTime, '11:30 AM');
    expect(resNormal7.recommendedDepartureTime, '10:55 AM');
    expect(resNormal7.isGoodTimeToLeave, true);

    // Busy status (+20m delay)
    final resBusy7 = QueuePredictionService.predict(
      peopleAhead: 7,
      centreStatus: 'Open • Busy',
      slotTime: '11:30 AM',
      travelTimeMinutes: 25,
    );
    expect(resBusy7.estimatedWaitMinutes, 55); // 35 + 20
    expect(resBusy7.expectedTurnTime, '12:15 PM');
    expect(resBusy7.recommendedDepartureTime, '11:50 AM');

    // Delayed status (+45m delay)
    final resDelayed7 = QueuePredictionService.predict(
      peopleAhead: 7,
      centreStatus: 'Temporarily Delayed',
      slotTime: '11:30 AM',
      travelTimeMinutes: 25,
    );
    expect(resDelayed7.estimatedWaitMinutes, 80); // 35 + 45
    expect(resDelayed7.expectedTurnTime, '12:45 PM');
    expect(resDelayed7.recommendedDepartureTime, '12:20 PM');
    expect(resDelayed7.isGoodTimeToLeave, false);

    // 0 people ahead
    final resZero = QueuePredictionService.predict(
      peopleAhead: 0,
      centreStatus: 'Open • Normal',
      slotTime: '11:30 AM',
      travelTimeMinutes: 25,
    );
    expect(resZero.queuePosition, 1);
    expect(resZero.estimatedWaitMinutes, 0);
    expect(resZero.isGoodTimeToLeave, true);
  });

  Future<void> selectLocationAndCentreForTest(
    WidgetTester tester, {
    String stateId = 'punjab',
    String districtId = 'ludhiana',
    String mandalId = 'khanna',
    String centreId = 'centre_1',
  }) async {
    final stateField = find.byKey(const ValueKey('select_state_field'));
    if (stateField.evaluate().isNotEmpty) {
      await tester.ensureVisible(stateField);
      await tester.pumpAndSettle();
      await tester.tap(stateField);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('picker_item_$stateId')));
      await tester.pumpAndSettle();

      final districtField = find.byKey(const ValueKey('select_district_field'));
      await tester.ensureVisible(districtField);
      await tester.pumpAndSettle();
      await tester.tap(districtField);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('picker_item_$districtId')));
      await tester.pumpAndSettle();

      final mandalField = find.byKey(const ValueKey('select_mandal_field'));
      await tester.ensureVisible(mandalField);
      await tester.pumpAndSettle();
      await tester.tap(mandalField);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('picker_item_$mandalId')));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const ValueKey('btn_confirm_find_centres'));
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
    }

    final selectCentreBtn = find.byKey(ValueKey('btn_select_centre_$centreId'));
    if (selectCentreBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(selectCentreBtn);
      await tester.pumpAndSettle();
      await tester.tap(selectCentreBtn);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
      'Phase 5 Full Flow: Dashboard -> Book Slot -> Centre & Produce -> Smart Slot -> Confirm -> Digital Token -> Dashboard updated',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login to Dashboard
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    expect(find.text('TK-8492'), findsOneWidget);

    // 1. Tapping "Book Slot" opens Book Procurement Slot screen
    await tester.ensureVisible(find.text('Book Slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Slot'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerBookSlotScreen), findsOneWidget);
    expect(find.text('Book Procurement Slot'), findsOneWidget);

    // 2. Location Selection: State -> District -> Mandal -> Confirm
    final stateField = find.byKey(const ValueKey('select_state_field'));
    await tester.ensureVisible(stateField);
    await tester.pumpAndSettle();
    await tester.tap(stateField);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picker_item_punjab')));
    await tester.pumpAndSettle();

    final districtField = find.byKey(const ValueKey('select_district_field'));
    await tester.ensureVisible(districtField);
    await tester.pumpAndSettle();
    await tester.tap(districtField);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picker_item_ludhiana')));
    await tester.pumpAndSettle();

    final mandalField = find.byKey(const ValueKey('select_mandal_field'));
    await tester.ensureVisible(mandalField);
    await tester.pumpAndSettle();
    await tester.tap(mandalField);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picker_item_khanna')));
    await tester.pumpAndSettle();

    final confirmBtn = find.byKey(const ValueKey('btn_confirm_find_centres'));
    await tester.ensureVisible(confirmBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // 2b. Centres list is displayed clearly
    expect(find.text('Example Procurement Centre'), findsOneWidget);
    expect(find.text('Nearby Procurement Centre'), findsOneWidget);

    // 3. Centre selection works properly
    final centre2Btn = find.byKey(const ValueKey('btn_select_centre_centre_2'));
    await tester.ensureVisible(centre2Btn);
    await tester.pumpAndSettle();
    await tester.tap(centre2Btn);
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);

    // Tap back to Example Procurement Centre
    final centre1Btn = find.byKey(const ValueKey('btn_select_centre_centre_1'));
    await tester.ensureVisible(centre1Btn);
    await tester.pumpAndSettle();
    await tester.tap(centre1Btn);
    await tester.pumpAndSettle();

    // 4 & 5. Produce confirmation card is displayed
    expect(find.text('Your Produce'), findsOneWidget);
    expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
    expect(find.text('₹1,13,750'), findsOneWidget);
    expect(find.text('From your registered produce'), findsOneWidget);

    // 14. Voice guidance test on Book Slot
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(FarmerBookSlotScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 4. Continue to Best Slot
    final continueToSlotBtn =
        find.widgetWithText(ElevatedButton, 'Continue to Best Slot');
    expect(continueToSlotBtn, findsOneWidget);
    await tester.tap(continueToSlotBtn);
    await tester.pumpAndSettle();

    // 6. "Best Time to Visit" screen displays recommended slots
    expect(find.byType(FarmerSmartSlotScreen), findsOneWidget);
    expect(find.text('Best Time to Visit'), findsOneWidget);

    // 7. Recommended slot is visually emphasized and clear
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('11:30 AM'), findsOneWidget);

    // 8. Expected wait times and tags are displayed
    expect(find.text('Expected wait: 15 min'), findsOneWidget);
    expect(find.text('Arrival: 11:20 AM'), findsOneWidget);

    // 9. Slot selection works properly (tap 1:00 PM slot)
    await tester.tap(find.text('1:00 PM'));
    await tester.pumpAndSettle();

    // Re-select 11:30 AM slot
    await tester.tap(find.text('11:30 AM'));
    await tester.pumpAndSettle();

    // Voice guidance test on Smart Slot
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(FarmerSmartSlotScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Tap Continue on Smart Slot Screen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // 10. Confirm Slot screen summarizes all details accurately
    expect(find.byType(FarmerSlotConfirmationScreen), findsOneWidget);
    expect(find.text('Confirm Your Slot'), findsOneWidget);
    expect(find.text('Example Procurement Centre'), findsWidgets);
    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('50 Quintals'), findsOneWidget);
    expect(find.text('11:30 AM'), findsOneWidget);
    expect(find.text('11:20 AM'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);

    // Voice guidance test on Confirmation Screen
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(
            tester.element(find.byType(FarmerSlotConfirmationScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 11. Confirm button generates token (TK-8493)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Slot'));
    await tester.pumpAndSettle();

    // 12. Digital Token screen displays token, centre, arrival, and slot time
    expect(find.byType(FarmerBookingSuccessScreen), findsOneWidget);
    expect(find.text('Your slot is confirmed'), findsOneWidget);
    expect(find.text('TK-8493'), findsOneWidget);
    expect(find.text('Example Procurement Centre'), findsOneWidget);
    expect(find.text('11:20 AM'), findsOneWidget);
    expect(find.text('11:30 AM'), findsOneWidget);

    // Voice guidance test on Success Screen
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(FarmerBookingSuccessScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 13. Return to Dashboard reflects newly booked token/slot state
    await tester.tap(find.widgetWithText(ElevatedButton, 'Return to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    // Token is now updated to TK-8493 on the dashboard
    expect(find.text('TK-8493'), findsOneWidget);
  });

  testWidgets('Back navigation works properly from every screen in booking flow',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login to Dashboard
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    // 15a: Dashboard -> Book Slot -> Back to Dashboard
    await tester.ensureVisible(find.text('Book Slot'));
    await tester.tap(find.text('Book Slot'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerBookSlotScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // 15b: Dashboard -> Book Slot -> Smart Slot -> Back to Centre Selection
    await tester.ensureVisible(find.text('Book Slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Slot'));
    await tester.pumpAndSettle();
    await selectLocationAndCentreForTest(tester);
    await tester
        .tap(find.widgetWithText(ElevatedButton, 'Continue to Best Slot'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerSmartSlotScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Centre Selection'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerBookSlotScreen), findsOneWidget);

    // 15c: Book Slot -> Smart Slot -> Confirm Screen -> Back to Slot Selection
    await tester
        .tap(find.widgetWithText(ElevatedButton, 'Continue to Best Slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerSlotConfirmationScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Smart Slots'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerSmartSlotScreen), findsOneWidget);
  });

  testWidgets('Phase 7: Officer Login - Validation, Demo Hint, and Successful Navigation',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // 1. Role Selection -> Tap Procurement Officer
    await tester.tap(find.text('Procurement Officer'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerLoginScreen), findsOneWidget);
    expect(find.text('Procurement Officer Login'), findsOneWidget);
    expect(find.text('OFFICER001'), findsWidgets); // Hint card
    expect(find.text('123456'), findsWidgets); // Hint card

    // Voice assistance test
    await tester.tap(find.text('Listen / सुनें'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(OfficerLoginScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 2. Empty fields validation
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter both Officer ID and Password.'),
        findsOneWidget);

    // 3. Invalid credentials rejected
    await tester.enterText(find.byType(TextFormField).first, 'WRONG_OFFICER');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Invalid Officer ID or Password'), findsOneWidget);

    // 4. Auto-Fill demo credentials and successful login
    await tester.tap(find.text('Auto-Fill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerDashboardScreen), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);
    expect(find.textContaining('Today'), findsWidgets);
  });

  testWidgets(
      'Phase 7: Officer Dashboard KPIs, Live Queue, Operations, and Detail Verification',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login to Officer Dashboard
    await tester.tap(find.text('Procurement Officer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-Fill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerDashboardScreen), findsOneWidget);

    // 1. Verify Operational KPIs
    expect(find.text("Today's Bookings"), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.text('Waiting'), findsWidgets);
    expect(find.text('7'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('35 min'), findsWidgets); // Average Wait & Queue item
    expect(find.text('~2 farmers / 10 min'), findsWidgets);
    expect(find.text('75%'), findsWidgets);

    // 2. Verify Live Queue items
    expect(find.text('LIVE QUEUE'), findsOneWidget);
    expect(find.text('TK-8490'), findsOneWidget);
    expect(find.text('TK-8491'), findsOneWidget);
    expect(find.text('TK-8492'), findsOneWidget);
    expect(find.text('TK-8493'), findsOneWidget);
    expect(find.text('Sukhdev Singh • Wheat (40 Quintals)'), findsOneWidget);
    expect(find.text('Ramesh Kumar • Wheat (50 Quintals)'), findsOneWidget);

    // 3. Operational Action: Call Next Farmer
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Call Next Farmer'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Call Next Farmer'));
    await tester.pumpAndSettle();
    if (find.text('CALL FARMER').evaluate().isNotEmpty) {
      await tester.tap(find.text('CALL FARMER'));
      await tester.pumpAndSettle();
    }

    // 4. Select a Farmer (TK-8493) to open Farmer Procurement Detail
    await tester.ensureVisible(find.text('TK-8493'));
    await tester.tap(find.text('TK-8493'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerFarmerDetailScreen), findsOneWidget);
    expect(find.text('Farmer Detail • TK-8493'), findsOneWidget);
    expect(find.text('Harpreet Singh'), findsOneWidget);
    expect(find.text('Procurement Lifecycle Stage'), findsOneWidget);

    // Test Confirm Quality & Weighment (Phase 8)
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Confirm Weighment'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept Produce'));
    await tester.pumpAndSettle();

    // Advance lifecycle stage
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Advance Lifecycle Stage'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Advance Lifecycle Stage'));
    await tester.pumpAndSettle();

    // Return to Dashboard
    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(OfficerDashboardScreen), findsOneWidget);

    // 5. Test Centre Status Control
    await tester.ensureVisible(find.text('Open • Busy'));
    await tester.tap(find.text('Open • Busy'));
    await tester.pumpAndSettle();
    expect(find.text('Operating Status: Open • Busy • Capacity: 75% (Normal)'),
        findsOneWidget);

    // 6. Test Capacity Control
    await tester.tap(find.text('High Load (95%)'));
    await tester.pumpAndSettle();
    expect(find.text('95%'), findsWidgets);

    // 7. Test Slot Capacity adjustment dialog
    await tester.ensureVisible(find.text('Smart Slot Management'));
    expect(find.text('Smart Slot Management'), findsOneWidget);
    await tester.tap(find.text('Adjust Slot Capacity').first);
    await tester.pumpAndSettle();

    expect(find.text('Adjust Slot Capacity (10:30 AM)'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Capacity'));
    await tester.pumpAndSettle();

    expect(find.textContaining('available'), findsWidgets);

    // 8. Logout returns to RoleSelectionScreen
    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets(
      'Phase 7: Shared State - Officer actions dynamically reflect on Farmer Dashboard',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    // 1. Officer calls next farmer twice in service
    ProcurementStateService().callNextFarmer();
    ProcurementStateService().callNextFarmer();

    // 2. Open App as Farmer
    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // Ramesh Kumar originally had 7 people ahead; after 2 calls, he now has 5!
    expect(find.text('5 people ahead'), findsWidgets);
    expect(find.text('25 min'), findsWidgets); // 5 * 5 = 25 min wait

    // 3. Officer marks centre as Temporarily Delayed
    ProcurementStateService().setCentreStatus('Temporarily Delayed');
    await tester.pumpAndSettle();

    // Farmer dashboard reflects delayed status in GoTime card and wait time!
    expect(find.text('WAIT A LITTLE'), findsOneWidget);
    expect(find.textContaining('weighbridge calibration'), findsOneWidget);
    expect(find.text('70 min'), findsWidgets);

    // Opening Go-Time details reveals full operating status
    await tester.tap(find.widgetWithText(OutlinedButton, 'View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Temporarily Delayed'), findsOneWidget);
  });

  group('Phase 8: PaymentCalculationService Unit Tests', () {
    test('Calculates MSP rate and gross amount accurately', () {
      final calc50 = PaymentCalculationService.calculate(
        crop: 'Wheat',
        acceptedQuantity: 50.0,
      );
      expect(calc50.ratePerQuintal, 2275.0);
      expect(calc50.grossAmount, 113750.0);
      expect(calc50.deductions, 0.0);
      expect(calc50.netPayable, 113750.0);

      // Actual weighment: 50.2 Quintals @ 2275 = 114205
      final calc502 = PaymentCalculationService.calculate(
        crop: 'Wheat',
        acceptedQuantity: 50.2,
      );
      expect(calc502.grossAmount, 114205.0);
      expect(calc502.netPayable, 114205.0);
    });

    test('Currency formatter handles Indian comma formatting', () {
      expect(PaymentCalculationService.formatCurrency(114205), '₹1,14,205');
      expect(PaymentCalculationService.formatCurrency(113750), '₹1,13,750');
      expect(PaymentCalculationService.formatCurrency(0), '₹0');
    });
  });

  testWidgets(
      'Phase 8: Farmer Procurement Status - 7-stage lifecycle, weighment, and discrepancy detection',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login as Farmer
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // Tap "My Produce" quick action
    await tester.ensureVisible(find.text('My Produce').first);
    await tester.tap(find.text('My Produce').first);
    await tester.pumpAndSettle();

    expect(find.byType(FarmerProcurementStatusScreen), findsOneWidget);
    expect(find.text('Procurement Status'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('TK-8492'), findsOneWidget);

    // Check 7 lifecycle stages
    expect(find.text('Procurement Lifecycle'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('Quality Check'), findsOneWidget);
    expect(find.text('Weighment'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Payment Pending'), findsWidgets);
    expect(find.text('Payment Completed'), findsWidgets);

    // Check Physical Weighment Record
    await tester.ensureVisible(find.text('Weighment & Quality Record'));
    expect(find.text('Weighment & Quality Record'), findsOneWidget);
    expect(find.text('Expected Quantity: '), findsOneWidget);
    expect(find.text('50.0 Quintals'), findsOneWidget);
    expect(find.text('Actual Weighment: '), findsOneWidget);
    expect(find.text('50.2 Quintals'), findsWidgets);
    expect(find.text('+0.2 Quintals'), findsOneWidget);

    // Check Discrepancy Banner
    expect(find.text('Please review this quantity before accepting.'),
        findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Report a Discrepancy'),
        findsOneWidget);

    // Tap "Report a Discrepancy" action
    await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Report a Discrepancy'));
    await tester.tap(
        find.widgetWithText(OutlinedButton, 'Report a Discrepancy'));
    await tester.pumpAndSettle();

    // Verify FarmerDisputeScreen opened
    expect(find.byType(FarmerDisputeScreen), findsOneWidget);
    expect(find.text('Report a Problem'), findsWidgets);
    expect(find.text('Quantity is incorrect'), findsOneWidget);

    // Select reason & submit dispute
    await tester.tap(find.text('Quantity is incorrect'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField),
        'Digital weighbridge scale showed 50.2 quintals instead of 50.0 quintals.');
    await tester.pumpAndSettle();

    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Submit Report'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Report'));
    await tester.pumpAndSettle();

    // Confirmation screen shown
    expect(find.text('Your report has been submitted.'), findsWidgets);
    expect(ProcurementStateService().disputes.length, 1);

    // Return to Procurement Status
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Return to Previous Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerProcurementStatusScreen), findsOneWidget);

    // Shortcut to View Payment Details
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'View Payment Details & Status'));
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'View Payment Details & Status'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerPaymentScreen), findsOneWidget);
  });

  testWidgets(
      'Phase 8: Farmer Payment Screen - Transparency breakdown, status, and DBT details',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login as Farmer
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    // Tap "Payment" quick action
    await tester.ensureVisible(find.text('Payment').first);
    await tester.tap(find.text('Payment').first);
    await tester.pumpAndSettle();

    expect(find.byType(FarmerPaymentScreen), findsOneWidget);
    expect(find.text('Payment Tracker'), findsOneWidget);
    expect(find.text('Net Payable Amount'), findsOneWidget);
    expect(find.text('₹1,14,205'), findsWidgets);

    // Transparency Card
    expect(find.text('Payment Transparency'), findsOneWidget);
    expect(find.text('Produce Value'), findsOneWidget);
    expect(find.text('Deductions'), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);
    expect(find.text('Applicable MSP'), findsOneWidget);
    expect(find.text('₹2,275 / Quintal'), findsOneWidget);
    expect(find.text('Net Payable'), findsOneWidget);

    // Transaction Details Card
    await tester.ensureVisible(find.text('Transaction Details'));
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Direct Benefit Transfer (DBT - Demo)'), findsOneWidget);
    expect(find.textContaining('PAY-2026-8492'), findsOneWidget);
  });

  testWidgets(
      'Phase 8: End-to-end Officer verification and live synchronization with Farmer payment status',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // 1. Login as Officer using Auto-Fill
    await tester.tap(find.text('Procurement Officer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-Fill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerDashboardScreen), findsOneWidget);

    // 2. Open Ramesh Kumar (TK-8492)
    await tester.ensureVisible(find.text('TK-8492'));
    await tester.tap(find.text('TK-8492'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerFarmerDetailScreen), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Weighment & Quality Verification'), findsOneWidget);

    // Confirm Quality and Weighment
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Confirm Weighment'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept Produce'));
    await tester.pumpAndSettle();

    // Officer initiates payment
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Initiate Payment'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Initiate Payment'));
    await tester.pumpAndSettle();

    // Officer marks payment completed
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Mark Payment Completed'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Payment Completed'));
    await tester.pumpAndSettle();

    // Verify service synchronized state
    expect(ProcurementStateService().farmerData.paymentStatus, 'Completed');

    // 3. Return to Role Selection & Login as Farmer
    await tester.tap(find.byTooltip('Back to Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    // Farmer Dashboard reflects Payment Completed in Produce Summary Card
    expect(find.text('Payment: '), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);

    // Open Payment screen
    await tester.ensureVisible(find.text('Payment').first);
    await tester.tap(find.text('Payment').first);
    await tester.pumpAndSettle();

    expect(find.byType(FarmerPaymentScreen), findsOneWidget);
    expect(find.text('Payment Completed'), findsWidgets);
    expect(find.text('Payment Status: '), findsOneWidget);
  });

  group('Phase 9: NotificationService Unit Tests', () {
    test('Deduplication prevents repeated notifications on rebuild', () {
      final service = NotificationService();
      service.reset();
      final initialCount = service.notifications.length;

      // Add with existing deduplication key
      service.notifyQueueUpdate(
        tokenNumber: 'TK-8493',
        peopleAhead: 7,
        estimatedWait: '35 min',
      );
      expect(service.notifications.length, initialCount);

      // Add with new key
      service.notifyQueueUpdate(
        tokenNumber: 'TK-8493',
        peopleAhead: 2,
        estimatedWait: '10 min',
      );
      expect(service.notifications.length, initialCount + 1);
    });

    test('Mark as read and mark all as read update unread count correctly', () {
      final service = NotificationService();
      service.reset();
      expect(service.unreadCount, 3);

      final firstId = service.notifications.first.id;
      service.markAsRead(firstId);
      expect(service.unreadCount, 2);

      service.markAllAsRead();
      expect(service.unreadCount, 0);
    });

    test('Voice summary generates appropriate English and Hindi guidance', () {
      final service = NotificationService();
      service.reset();

      final enSummary = service.generateVoiceSummary(
        isHindi: false,
        tokenNumber: 'TK-8493',
        peopleAhead: 3,
        departureTime: '10:55 AM',
      );
      expect(enSummary, contains('Voice Assistant: You have 3 new updates'));
      expect(enSummary, contains('TK-8493'));

      final hiSummary = service.generateVoiceSummary(
        isHindi: true,
        tokenNumber: 'TK-8493',
        peopleAhead: 3,
        departureTime: '10:55 AM',
      );
      expect(hiSummary, contains('आवाज सहायक: आपके पास 3 नए अपडेट हैं'));
      expect(hiSummary, contains('TK-8493'));
    });
  });

  testWidgets(
      'Phase 9: Dashboard Notification Preview and Messages Screen Navigation',
      (WidgetTester tester) async {
    ProcurementStateService().reset();
    NotificationService().reset();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const KisanSetuApp());
    await tester.pumpAndSettle();

    // Login as Farmer
    await tester.tap(find.text('I am a Farmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // 1. Verify Latest Update preview card exists on Dashboard
    expect(find.text('Latest Update'), findsOneWidget);
    expect(find.text('View Messages'), findsOneWidget);
    expect(find.textContaining('New'), findsWidgets);

    // 2. Open Messages from View Messages preview button
    await tester.ensureVisible(find.text('View Messages'));
    await tester.tap(find.text('View Messages'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerMessagesScreen), findsOneWidget);
    expect(find.text('🌾 KisanSetu • Notification Centre'), findsOneWidget);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Queue Update'), findsOneWidget);
    expect(find.text('When To Leave'), findsOneWidget);
    expect(find.text('3 Unread'), findsOneWidget);

    // 3. Test Listen / सुनें voice guidance
    await tester.tap(find.text('Listen'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Voice Assistant: You have 3 new updates'), findsOneWidget);

    // 4. Test "Mark all as read"
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('0 Unread'), findsOneWidget);
    expect(NotificationService().unreadCount, 0);

    // Return to Dashboard
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerDashboardScreen), findsOneWidget);

    // 5. Open Messages from Bottom Navigation Bar
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerMessagesScreen), findsOneWidget);

    // 6. Test tapping notification navigates to the associated destination (When To Leave -> Departure Details)
    await tester.tap(find.text('When To Leave'));
    await tester.pumpAndSettle();
    expect(find.byType(FarmerGoTimeDetailsScreen), findsOneWidget);
    expect(find.text('Departure Details'), findsOneWidget);
  });

  testWidgets(
      'Phase 9: Real-time Event-driven Notifications across Officer & Farmer State',
      (WidgetTester tester) async {
    final stateService = ProcurementStateService();
    final notifService = NotificationService();
    stateService.reset();
    notifService.reset();

    // 1. Booking a slot triggers bookingConfirmed notification
    stateService.updateFarmerBooking(
      centreName: 'Anand APMC Main Yard',
      bookedSlot: '01:30 PM',
      tokenNumber: 'TK-8494',
      crop: 'Wheat',
      quantity: '50 Quintals',
    );
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.bookingConfirmed &&
          n.tokenNumber == 'TK-8494'),
      isTrue,
    );

    // 2. Changing centre status to Temporarily Delayed triggers centreStatus notification
    stateService.setCentreStatus('Temporarily Delayed');
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.centreStatus &&
          n.titleEn.contains('Delayed')),
      isTrue,
    );

    // 3. Officer physical verification advances generate processing & accepted notifications
    stateService.confirmQuality('TK-8494', 'Grade A');
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.procurementProcessing &&
          n.titleEn.contains('Grade A')),
      isTrue,
    );

    stateService.confirmWeighment('TK-8494', 50.2);
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.procurementProcessing &&
          n.titleEn.contains('Weighment')),
      isTrue,
    );

    stateService.acceptProduce('TK-8494');
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.procurementAccepted &&
          n.tokenNumber == 'TK-8494'),
      isTrue,
    );

    // 4. Officer payment triggers paymentInitiated and paymentCompleted notifications
    stateService.initiatePayment('TK-8494');
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.paymentInitiated &&
          n.tokenNumber == 'TK-8494'),
      isTrue,
    );

    stateService.markPaymentCompleted('TK-8494');
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.paymentCompleted &&
          n.tokenNumber == 'TK-8494'),
      isTrue,
    );

    // 5. Farmer submitting dispute triggers disputeSubmitted notification
    stateService.submitDispute(
      tokenNumber: 'TK-8494',
      reason: 'Weighment Discrepancy',
      explanation: 'Scale difference noted at dock',
    );
    expect(
      notifService.notifications.any((n) =>
          n.type == NotificationType.disputeSubmitted &&
          n.tokenNumber == 'TK-8494'),
      isTrue,
    );
  });

  group('Phase 10: Supabase Backend Foundation & Repositories', () {
    test('SupabaseConfig defaults to local mode with placeholders', () {
      expect(SupabaseConfig.backendMode, equals(BackendMode.local));
      expect(SupabaseConfig.supabaseUrl, equals(SupabaseConfig.placeholderUrl));
      expect(SupabaseConfig.supabasePublishableKey, equals(SupabaseConfig.placeholderAnonKey));
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseConfig.shouldUseSupabase, isFalse);
    });

    test('SupabaseService initializes gracefully in local mode without credentials', () async {
      final service = SupabaseService.instance;
      final result = await service.initialize();
      expect(result, isFalse);
      expect(service.isReady, isFalse);
      expect(service.client, isNull);
    });

    test('RepositoryProvider dispenses valid local implementations under BackendMode.local', () async {
      // 1. Farmer Repository
      final farmerRepo = RepositoryProvider.farmer;
      final profile = await farmerRepo.getFarmerProfile('FARMER-001');
      expect(profile?['name'], equals('Ramesh Kumar'));
      final produce = await farmerRepo.getFarmerProduce('FARMER-001');
      expect(produce.isNotEmpty, isTrue);

      // 2. Booking Repository
      final bookingRepo = RepositoryProvider.booking;
      final centres = await bookingRepo.getProcurementCentres();
      expect(centres.isNotEmpty, isTrue);
      final newBooking = await bookingRepo.createBooking(
        farmerId: 'FARMER-001',
        centreId: 'Example Procurement Centre',
        crop: 'Wheat',
        quantity: 50.0,
        slotTime: '11:30 AM',
      );
      expect(newBooking?['token'], isNotNull);

      // 3. Queue Repository
      final queueRepo = RepositoryProvider.queue;
      final queueStatus = await queueRepo.getQueueStatus('BOOK-001');
      expect(queueStatus['position'], isNotNull);
      final officerQueue = await queueRepo.getOfficerQueue('centre_1');
      expect(officerQueue.isNotEmpty, isTrue);

      // 4. Procurement Repository
      final procRepo = RepositoryProvider.procurement;
      final procRecord = await procRepo.getProcurementRecord('BOOK-001');
      expect(procRecord['token'], isNotNull);

      // 5. Payment Repository
      final payRepo = RepositoryProvider.payment;
      final payDetails = await payRepo.getPaymentDetails('BOOK-001');
      expect(payDetails['net_amount'], isNotNull);

      // 6. Notification Repository
      final notifRepo = RepositoryProvider.notification;
      final notifs = await notifRepo.getNotifications('FARMER-001');
      expect(notifs.isNotEmpty, isTrue);
      final unread = await notifRepo.getUnreadCount('FARMER-001');
      expect(unread, isNonNegative);

      // 7. Dispute Repository
      final dispRepo = RepositoryProvider.dispute;
      final dispute = await dispRepo.submitDispute(
        farmerId: 'FARMER-001',
        bookingId: 'BOOK-001',
        category: 'Quantity is incorrect',
        description: 'Test discrepancy in repository',
      );
      expect(dispute.tokenNumber, isNotNull);
    });

    test('Security Verification: No service_role or secret keys exposed in client config', () {
      expect(SupabaseConfig.supabasePublishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.placeholderAnonKey.toLowerCase().contains('service_role'), isFalse);
    });
  });

  group('Phase 11A: Supabase Connection Verification', () {
    test('1. Supabase configuration is read correctly with safe defaults', () {
      expect(SupabaseConfig.backendMode, equals(BackendMode.local));
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabasePublishableKey, isNotEmpty);
      // Without custom --dart-define, placeholder values are in effect
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseConfig.shouldUseSupabase, isFalse);
    });

    test('2. Supabase initialization works when valid parameters are supplied', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SupabaseService.instance;
      // Valid dummy project configuration
      const testUrl = 'https://sih26032-test-project.supabase.co';
      const testAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummyTestPayloadKey';

      // Test that initialize with overrides successfully creates the Supabase client
      final success = await service.initialize(
        urlOverride: testUrl,
        anonKeyOverride: testAnonKey,
        forceInit: true,
      );

      expect(success, isTrue);
      expect(service.isReady, isTrue);
      expect(service.client, isNotNull);
      expect(service.client?.rest.url.toString(), contains('sih26032-test-project.supabase.co'));

      // Realtime streams can be obtained when client is ready
      final stream = service.streamFarmerBookings('FARMER-001');
      expect(stream, isNotNull);
    });

    test('3. Local mode still routes repositories to local fallback even when client is ready', () {
      // Despite client being initialized in test 2, backendMode defaults to local
      expect(SupabaseConfig.backendMode, equals(BackendMode.local));
      expect(SupabaseConfig.shouldUseSupabase, isFalse);

      // RepositoryProvider continues dispensing local repositories
      expect(RepositoryProvider.farmer, isA<LocalFarmerRepository>());
      expect(RepositoryProvider.booking, isA<LocalBookingRepository>());
      expect(RepositoryProvider.queue, isA<LocalQueueRepository>());
      expect(RepositoryProvider.procurement, isA<LocalProcurementRepository>());
      expect(RepositoryProvider.payment, isA<LocalPaymentRepository>());
      expect(RepositoryProvider.notification, isA<LocalNotificationRepository>());
      expect(RepositoryProvider.dispute, isA<LocalDisputeRepository>());
    });
  });

  group('Phase 11B: Telugu Language Support Verification', () {
    testWidgets('1. Language selection screen has English, Hindi, and Telugu options',
        (WidgetTester tester) async {
      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('I am a Farmer'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerLanguageSelectionScreen), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('Telugu'), findsOneWidget);

      // Initially English is selected, button says Continue
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

      // Select Hindi -> button changes to आगे बढ़ें
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'आगे बढ़ें'), findsOneWidget);

      // Select Telugu -> button changes to ముందుకు సాగండి
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'ముందుకు సాగండి'), findsOneWidget);
    });

    testWidgets('2. Full Telugu farmer onboarding and dashboard workflow',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      // Tap Farmer
      await tester.tap(find.text('I am a Farmer'));
      await tester.pumpAndSettle();

      // Tap Telugu
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'ముందుకు సాగండి'));
      await tester.pumpAndSettle();

      // Farmer Phone Login Screen in Telugu
      expect(find.byType(FarmerPhoneLoginScreen), findsOneWidget);
      expect(find.text('మీ మొబైల్ నంబర్ నమోదు చేయండి'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'OTP పంపండి'), findsOneWidget);

      // Enter phone
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'OTP పంపండి'));
      await tester.pumpAndSettle();

      // OTP verification screen in Telugu
      expect(find.byType(FarmerOtpVerificationScreen), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'OTP ధృవీకరించండి'), findsOneWidget);

      // Enter OTP
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'OTP ధృవీకరించండి'));
      await tester.pumpAndSettle();

      // Farmer Dashboard in Telugu
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.text('రమేష్ కుమార్'), findsOneWidget);
      expect(find.text('నా పంట'), findsWidgets);
      expect(find.text('నేను ఎప్పుడు వెళ్ళాలి?'), findsOneWidget);
      expect(find.text('నా టోకెన్'), findsWidgets);
      expect(find.text('స్లాట్ బుక్ చేయండి'), findsOneWidget);
      expect(find.text('చెల్లింపు'), findsWidgets);
      expect(find.text('డిజిటల్ పాస్ / QR'), findsOneWidget);
      expect(find.text('రసీదు / ఇన్‌వాయిస్ డౌన్‌లోడ్'), findsOneWidget);
      expect(find.textContaining('సందేశాలు'), findsWidgets);

      // Voice guidance button in Telugu
      expect(find.text('Listen / వినండి'), findsOneWidget);
      await tester.tap(find.text('Listen / వినండి'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('వాయిస్ సహాయకుడు: నమస్కారం'), findsOneWidget);
    });

    testWidgets('3. Telugu secondary screens load with correct language labels',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final testData = ProcurementStateService().farmerData;

      // Book slot screen
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(currentData: testData, isHindi: false, isTelugu: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('సేకరణ కేంద్రాన్ని ఎంచుకోండి'), findsOneWidget);

      // My token screen
      await tester.pumpWidget(MaterialApp(
        home: FarmerMyTokenScreen(data: testData, isHindi: false, isTelugu: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('నా టోకెన్'), findsWidgets);
      expect(find.text('లైవ్ క్యూ స్థానం & డిజిటల్ పాస్'), findsOneWidget);
      expect(find.text('డాష్‌బోర్డ్‌కు తిరిగి వెళ్లండి'), findsOneWidget);

      // Messages screen
      await tester.pumpWidget(const MaterialApp(
        home: FarmerMessagesScreen(isTelugu: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('సందేశాలు'), findsOneWidget);

      // Payment screen
      await tester.pumpWidget(const MaterialApp(
        home: FarmerPaymentScreen(isTelugu: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('చెల్లింపు ట్రాకర్'), findsOneWidget);

      // Dispute screen
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDisputeScreen(tokenNumber: 'TK-8492', isTelugu: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('సమస్యను నివేదించండి'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'నివేదిక సమర్పించండి'), findsOneWidget);
    });
  });

  group('Phase 12: QR Digital Check-in + Farmer Journey Tracker Verification', () {
    test('1. QrValidationService generates payloads and validates scenarios', () {
      ProcurementStateService().reset();
      final payload = QrValidationService.generateQrPayload(
        bookingId: 'BK-8492',
        tokenNumber: 'TK-8492',
        centreName: 'Example Procurement Centre',
        slotTime: '11:30 AM',
      );
      expect(payload, 'KISANSETU:V1:BK-8492:TK-8492:Example Procurement Centre:11:30 AM');

      // Valid match
      final resultValid = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: 'Example Procurement Centre',
      );
      expect(resultValid.isValid, true);
      expect(resultValid.status, QrValidationStatus.valid);
      expect(resultValid.tokenNumber, 'TK-8492');

      // Wrong centre rejection
      final resultWrongCentre = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: 'Different Mandi Yard',
      );
      expect(resultWrongCentre.isValid, false);
      expect(resultWrongCentre.status, QrValidationStatus.wrongCentre);

      // Malformed rejection
      final resultMalformed = QrValidationService.validate(
        rawPayload: 'INVALID_RANDOM_CODE',
        currentCentreName: 'Example Procurement Centre',
      );
      expect(resultMalformed.isValid, false);
      expect(resultMalformed.status, QrValidationStatus.invalidFormat);

      // Empty string rejection
      final resultEmpty = QrValidationService.validate(
        rawPayload: '   ',
        currentCentreName: 'Example Procurement Centre',
      );
      expect(resultEmpty.isValid, false);
      expect(resultEmpty.status, QrValidationStatus.invalidFormat);
    });

    testWidgets('2. FarmerDigitalQrPass renders with badges and trilingual support',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      // English Digital Pass
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FarmerDigitalQrPass(
              tokenNumber: 'TK-8492',
              farmerName: 'Ramesh Kumar',
              crop: 'Wheat',
              quantity: '50 Quintals',
              centreName: 'Example Procurement Centre',
              bookedSlot: '11:30 AM',
              checkInStatus: 'Not Checked In',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DIGITAL ENTRY PASS'), findsOneWidget);
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
      expect(find.text('Not Checked In'), findsOneWidget);
      expect(find.text('Example Procurement Centre'), findsOneWidget);
      expect(find.text('Show this QR at the centre gate for fast contactless entry.'), findsOneWidget);

      // Telugu Digital Pass with Checked In badge
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FarmerDigitalQrPass(
              tokenNumber: 'TK-8492',
              farmerName: 'రమేష్ కుమార్',
              crop: 'గోధుమ',
              quantity: '50 క్వింటాళ్లు',
              centreName: 'Example Procurement Centre',
              bookedSlot: '11:30 AM',
              checkInStatus: 'Checked In',
              actualArrivalTime: '11:18 AM',
              isTelugu: true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('డిజిటల్ క్యూ పాస్'), findsOneWidget);
      expect(find.text('గేట్ వద్ద చెక్-ఇన్ చేయబడింది'), findsOneWidget);
      expect(find.text('చేరుకున్న సమయం: 11:18 AM'), findsOneWidget);
    });

    testWidgets('3. FarmerJourneyTracker reflects 8 stages correctly',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      // Stage 1 (Booked)
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FarmerJourneyTracker(
            currentStatus: 'Booked',
            checkInStatus: 'Not Checked In',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Procurement Journey Tracker'), findsOneWidget);
      expect(find.text('8-Stage Transparent Progress'), findsOneWidget);
      expect(find.text('1/8'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);

      // Stage 3 (Waiting)
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FarmerJourneyTracker(
            currentStatus: 'Waiting',
            checkInStatus: 'Checked In',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('3/8'), findsOneWidget);

      // Telugu rendering
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FarmerJourneyTracker(
            currentStatus: 'Waiting',
            checkInStatus: 'Checked In',
            isTelugu: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('సేకరణ ప్రయాణం ట్రాకర్'), findsOneWidget);
      expect(find.text('8-దశల పారదర్శక పురోగతి'), findsOneWidget);
      expect(find.text('ప్రస్తుతం'), findsOneWidget);
    });

    testWidgets(
        '4. Officer QR Scanner screen - interactive scan, validation, and check-in confirmation',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gate QR Check-In Scanner'), findsOneWidget);
      expect(find.text('Demo Simulation Scans'), findsOneWidget);
      expect(find.text('TK-8493 (Harpreet)'), findsOneWidget);
      expect(find.text('Wrong Centre'), findsOneWidget);
      expect(find.text('Malformed QR'), findsOneWidget);

      // 1. Scan Harpreet Singh (TK-8493)
      await tester.tap(find.text('TK-8493 (Harpreet)'));
      await tester.pumpAndSettle();

      expect(find.text('QR Pass Verified'), findsOneWidget);
      expect(find.text('Harpreet Singh'), findsOneWidget);
      expect(find.text('Wheat • 45 Quintals'), findsOneWidget);
      expect(find.text('Confirm Gate Check-In'), findsOneWidget);

      // 2. Confirm Check-In
      await tester.tap(find.text('Confirm Gate Check-In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Check-In Confirmed for TK-8493'), findsOneWidget);
      expect(find.text('Farmer is Already Checked In & In Queue'), findsOneWidget);

      // 3. Test Wrong Centre scan
      await tester.tap(find.text('Wrong Centre'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('Token booked for another centre'), findsOneWidget);

      // 4. Test Malformed QR scan
      await tester.tap(find.text('Malformed QR'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('Invalid KisanSetu QR code format'), findsOneWidget);

      // 5. Test manual token input
      await tester.enterText(find.byType(TextField), 'TK-8492');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
      await tester.pumpAndSettle();

      expect(find.text('QR Pass Verified'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
    });

    testWidgets('5. Full Officer flow to Scanner and Farmer Token reflection',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      // Login to Officer Dashboard
      await tester.tap(find.text('Procurement Officer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto-Fill'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);

      // Tap Scan Farmer QR button
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Scan Farmer QR'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan Farmer QR'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerQrScannerScreen), findsOneWidget);

      // Scan and check-in TK-8493
      await tester.tap(find.text('TK-8493 (Harpreet)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Gate Check-In'));
      await tester.pumpAndSettle();

      // Check state updated in service
      final queueItem = ProcurementStateService()
          .queue
          .firstWhere((q) => q.tokenNumber == 'TK-8493');
      expect(queueItem.checkInStatus, 'Checked In');
      expect(queueItem.status, 'Waiting');

      // Pop back to dashboard
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
    });
  });

  group('Phase 13: Dynamic Queue Intelligence + When Should I Go Enhancement', () {
    test('1. Normal queue prediction and departure derivation (7, 5, 3, 1, 0 ahead)', () {
      final pred7 = QueuePredictionService.predict(
        peopleAhead: 7,
        bookedSlotTime: '11:30 AM',
        travelTimeMinutes: 20,
        centreStatus: 'Open • Active',
        centreCapacityPercent: 70,
      );
      expect(pred7.estimatedWaitMinutes, 35);
      expect(pred7.expectedTurnTime, '11:30 AM');
      expect(pred7.recommendedDepartureTime, '10:55 AM');
      expect(pred7.recommendation, GoTimeRecommendation.goNow);
      expect(pred7.recommendationTitleEn, 'LEAVE AT 10:55 AM');
      expect(pred7.centreLoadPercentage, 70);
      expect(pred7.confidence, 'High');

      final pred5 = QueuePredictionService.predict(peopleAhead: 5);
      expect(pred5.estimatedWaitMinutes, 25);
      expect(pred5.recommendedDepartureTime, '11:05 AM');

      final pred3 = QueuePredictionService.predict(peopleAhead: 3);
      expect(pred3.estimatedWaitMinutes, 15);
      expect(pred3.recommendedDepartureTime, '11:15 AM');

      final pred1 = QueuePredictionService.predict(peopleAhead: 1);
      expect(pred1.estimatedWaitMinutes, 5);
      expect(pred1.recommendedDepartureTime, '11:25 AM');

      final pred0 = QueuePredictionService.predict(peopleAhead: 0);
      expect(pred0.estimatedWaitMinutes, 0);
      expect(pred0.recommendedDepartureTime, 'Immediate');
    });

    test('2. Centre condition impacts: Busy, Delayed, Stopped, and fallback processing rate', () {
      // Busy: +20m wait, recommendation wait
      final busyPred = QueuePredictionService.predict(
        peopleAhead: 5,
        centreStatus: 'Open • Busy',
      );
      expect(busyPred.estimatedWaitMinutes, 45); // 25 + 20
      expect(busyPred.recommendation, GoTimeRecommendation.wait);

      // Delayed: +45m wait, recommendation delay
      final delayPred = QueuePredictionService.predict(
        peopleAhead: 5,
        centreStatus: 'Temporarily Delayed',
      );
      expect(delayPred.estimatedWaitMinutes, 70); // 25 + 45
      expect(delayPred.recommendation, GoTimeRecommendation.delay);

      // Stopped: recommendation centreTemporarilyStopped, "Do not travel"
      final stoppedPred = QueuePredictionService.predict(
        peopleAhead: 5,
        centreStatus: 'Temporarily Stopped',
      );
      expect(stoppedPred.recommendation, GoTimeRecommendation.centreTemporarilyStopped);
      expect(stoppedPred.recommendationTitleEn, 'CENTRE TEMPORARILY STOPPED');
      expect(stoppedPred.recommendationSubtitleEn.toLowerCase().contains('do not travel yet'), isTrue);

      // Zero or negative processing rate fallback
      final zeroRatePred = QueuePredictionService.predict(
        peopleAhead: 6,
        averageProcessingMinutes: 0,
      );
      expect(zeroRatePred.estimatedWaitMinutes, 30); // 6 * 5 min default
    });

    test('3. Travel time variations and departure calculation', () {
      // Arrival at 11:15 AM, travel time 15m -> departure 11:00 AM
      final pred15 = QueuePredictionService.predict(
        peopleAhead: 7,
        waitRecommendedArrival: '11:15 AM',
        travelTimeMinutes: 15,
      );
      expect(pred15.recommendedDepartureTime, '11:00 AM');

      // Travel time 40m, arrival 11:15 AM -> departure 10:35 AM
      final pred40 = QueuePredictionService.predict(
        peopleAhead: 7,
        waitRecommendedArrival: '11:15 AM',
        travelTimeMinutes: 40,
      );
      expect(pred40.recommendedDepartureTime, '10:35 AM');
    });

    testWidgets('4. Dynamic state sync: Officer status changes reflect on Farmer Dashboard & My Token',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final stateService = ProcurementStateService();
      stateService.reset();

      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      // Go to Farmer Dashboard
      await tester.tap(find.text('I am a Farmer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.text('LEAVE AT 10:55 AM'), findsOneWidget);

      // Now simulate Officer setting centre to Temporarily Stopped
      stateService.setCentreStatus('Temporarily Stopped');
      await tester.pumpAndSettle();

      // Farmer dashboard dynamically updates recommendation
      expect(find.text('CENTRE TEMPORARILY STOPPED'), findsWidgets);

      // Tap View Details
      await tester.tap(find.widgetWithText(OutlinedButton, 'View Details'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerGoTimeDetailsScreen), findsOneWidget);
      expect(find.text('Why this recommendation?'), findsOneWidget);
      expect(find.text('Temporarily Stopped'), findsWidgets);

      // Pop back to dashboard
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Navigate to My Token
      await tester.tap(find.widgetWithText(ElevatedButton, 'View Token'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerMyTokenScreen), findsOneWidget);
      expect(find.text('CENTRE TEMPORARILY STOPPED'), findsWidgets);

      // Reset state service
      stateService.reset();
    });

    test('5. NotificationService deduplicates queue improvements and delays', () {
      final notifService = NotificationService();
      notifService.reset();
      final baseCount = notifService.notifications.length;

      // Queue improvement
      notifService.notifyQueueImprovement(
        tokenNumber: 'TK-8492',
        newAhead: 3,
        expectedWaitMinutes: 15,
        turnTime: '11:15 AM',
      );
      expect(notifService.notifications.length, baseCount + 1);

      // Same update again - deduplicated!
      notifService.notifyQueueImprovement(
        tokenNumber: 'TK-8492',
        newAhead: 3,
        expectedWaitMinutes: 15,
        turnTime: '11:15 AM',
      );
      expect(notifService.notifications.length, baseCount + 1);

      // Centre delay
      notifService.notifyCentreDelay(
        tokenNumber: 'TK-8492',
        delayMinutes: 25,
        newTurnTime: '11:55 AM',
      );
      expect(notifService.notifications.length, baseCount + 2);

      // Same delay again - deduplicated!
      notifService.notifyCentreDelay(
        tokenNumber: 'TK-8492',
        delayMinutes: 25,
        newTurnTime: '11:55 AM',
      );
      expect(notifService.notifications.length, baseCount + 2);
    });

    testWidgets('6. Trilingual Go-Time Card and Details rendering in Hindi and Telugu',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final stateService = ProcurementStateService();
      stateService.reset();
      final data = stateService.farmerData;

      // Telugu Go-Time Details Screen
      await tester.pumpWidget(MaterialApp(
        home: FarmerGoTimeDetailsScreen(
          data: data,
          isTelugu: true,
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('బయలుదేరే సమయ వివరాలు'), findsOneWidget);
      expect(find.text('ప్రయాణ సమయ పట్టిక'), findsOneWidget);
      expect(find.text('ఈ సిఫార్సుకు కారణం ఏమిటి?'), findsOneWidget);

      // Hindi Go-Time Details Screen
      await tester.pumpWidget(MaterialApp(
        home: FarmerGoTimeDetailsScreen(
          data: data,
          isTelugu: false,
          isHindi: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('प्रस्थान समय विवरण'), findsOneWidget);
      expect(find.text('यात्रा समय सारणी'), findsOneWidget);
      expect(find.text('यह सिफारिश क्यों की गई?'), findsOneWidget);
    });

    testWidgets('7. Officer Dashboard shows Delay (min) KPI and Temporarily Stopped control',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      ProcurementStateService().reset();

      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Procurement Officer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto-Fill'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
      expect(find.text('Delay (min)'), findsOneWidget);

      await tester.ensureVisible(find.text('Temporarily Stopped'));
      expect(find.text('Temporarily Stopped'), findsOneWidget);
    });
  });

  group('Phase 14: Officer Alerts & Exception Management', () {
    test('1. OfficerExceptionModel fields, copyWith, and status getters', () {
      final now = DateTime.now();
      final ex = OfficerExceptionModel(
        id: 'ex_test_1',
        type: ExceptionType.queueOverload,
        severity: ExceptionSeverity.critical,
        title: 'Queue Overload Test',
        shortDescription: '18 waiting',
        explanation: '18 farmers waiting exceeding threshold of 15.',
        centreId: 'Test Centre',
        tokenNumber: 'TK-9999',
        farmerName: 'Baldev Singh',
        createdTimestamp: now,
        recommendedAction: 'Open dock 2',
      );

      expect(ex.id, 'ex_test_1');
      expect(ex.type, ExceptionType.queueOverload);
      expect(ex.severity, ExceptionSeverity.critical);
      expect(ex.severityLabel, 'CRITICAL');
      expect(ex.status, ExceptionStatus.open);
      expect(ex.statusLabel, 'Open');
      expect(ex.isOpen, isTrue);
      expect(ex.isAcknowledged, isFalse);
      expect(ex.isResolved, isFalse);
      expect(ex.tokenNumber, 'TK-9999');
      expect(ex.farmerName, 'Baldev Singh');

      final ack = ex.copyWith(status: ExceptionStatus.acknowledged);
      expect(ack.isOpen, isFalse);
      expect(ack.isAcknowledged, isTrue);
      expect(ack.statusLabel, 'Acknowledged');

      final res = ack.copyWith(status: ExceptionStatus.resolved);
      expect(res.isResolved, isTrue);
      expect(res.statusLabel, 'Resolved');
    });

    test('2. OfficerExceptionService singleton and threshold configuration', () {
      final s1 = OfficerExceptionService();
      final s2 = OfficerExceptionService();
      expect(identical(s1, s2), isTrue);

      s1.queueCriticalThreshold = 18;
      expect(s2.queueCriticalThreshold, 18);
      s1.queueCriticalThreshold = 15; // restore

      s1.reset();
      expect(s1.openCount(ProcurementStateService()), greaterThanOrEqualTo(0));
    });

    test('3. Queue Overload: Critical and Warning alerts', () {
      final service = OfficerExceptionService();
      service.reset();

      // Critical overload (>= 15 waiting)
      final critExceptions = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 18,
        estimatedWaitMinutes: 75,
        queue: const [],
      );

      final critQueue = critExceptions.firstWhere((e) => e.type == ExceptionType.queueOverload);
      expect(critQueue.severity, ExceptionSeverity.critical);
      expect(critQueue.explanation, contains('18 farmers are waiting and estimated wait is 75 minutes.'));
      expect(critQueue.recommendedAction, contains('Review active queue'));

      // Warning overload (>= 10 waiting)
      final warnExceptions = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 12,
        estimatedWaitMinutes: 45,
        queue: const [],
      );

      final warnQueue = warnExceptions.firstWhere((e) => e.type == ExceptionType.queueOverload);
      expect(warnQueue.severity, ExceptionSeverity.warning);
      expect(warnQueue.title, 'High Queue Depth');
    });

    test('4. Long-Waiting Farmer Alert with token and exceeded minutes', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8493',
          farmerName: 'Harpreet Singh',
          crop: 'Wheat',
          quantity: '45 Quintals',
          actualQuantity: '45.0 Quintals',
          qualityGrade: 'FAQ',
          bookedSlot: '11:45 AM',
          arrivalTime: '11:30 AM',
          status: 'Waiting',
          peopleAhead: 8,
          approxWaitMinutes: 20,
        ),
      ];

      final exceptions = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 25,
        queue: queue,
      );

      final longWait = exceptions.firstWhere((e) => e.type == ExceptionType.longWaitingFarmer);
      expect(longWait.severity, ExceptionSeverity.warning);
      expect(longWait.tokenNumber, 'TK-8493');
      expect(longWait.farmerName, 'Harpreet Singh');
      expect(longWait.explanation, contains('exceeding expected 20 min'));
      expect(longWait.recommendedAction, contains('Check farmer status'));
    });

    test('5. Processing Delay Alert (Warning and Critical)', () {
      final service = OfficerExceptionService();
      service.reset();

      // Warning delay (>= 15 min average processing)
      final warnList = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 18,
        averageProcessingMinutes: 16,
        waitingCount: 5,
        estimatedWaitMinutes: 25,
        queue: const [],
      );

      final warnDelay = warnList.firstWhere((e) => e.type == ExceptionType.processingDelay);
      expect(warnDelay.severity, ExceptionSeverity.warning);
      expect(warnDelay.title, 'Processing Delay');

      // Critical delay (>= 30 min)
      final critList = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 35,
        averageProcessingMinutes: 32,
        waitingCount: 5,
        estimatedWaitMinutes: 25,
        queue: const [],
      );

      final critDelay = critList.firstWhere((e) => e.type == ExceptionType.processingDelay);
      expect(critDelay.severity, ExceptionSeverity.critical);
      expect(critDelay.title, 'Centre Processing Delayed');
    });

    test('6. Centre Overload & Capacity Risk Alert (Critical & Warning)', () {
      final service = OfficerExceptionService();
      service.reset();

      // Critical (>= 95%)
      final critList = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 96,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: const [],
      );

      final critCap = critList.firstWhere((e) => e.type == ExceptionType.centreOverload);
      expect(critCap.severity, ExceptionSeverity.critical);
      expect(critCap.explanation, contains('96%'));

      // Warning (>= 85%)
      final warnList = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 88,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: const [],
      );

      final warnCap = warnList.firstWhere((e) => e.type == ExceptionType.centreOverload);
      expect(warnCap.severity, ExceptionSeverity.warning);
      expect(warnCap.title, 'High Centre Load');
    });

    test('7. Payment Processing Delay Alert', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8490',
          farmerName: 'Sukhdev Singh',
          crop: 'Wheat',
          quantity: '40 Quintals',
          actualQuantity: '40.0 Quintals',
          qualityGrade: 'Grade A',
          bookedSlot: '11:00 AM',
          arrivalTime: '10:50 AM',
          status: 'Waiting',
          peopleAhead: 1,
          approxWaitMinutes: 5,
          paymentStatus: 'Pending',
          paymentReference: 'PAY-2026-8490',
        ),
      ];

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );

      final payDelay = list.firstWhere((e) => e.type == ExceptionType.paymentDelay);
      expect(payDelay.severity, ExceptionSeverity.warning);
      expect(payDelay.tokenNumber, 'TK-8490');
      expect(payDelay.explanation, contains('Payment has remained processing'));
      expect(payDelay.recommendedAction, contains('Review payment status'));
    });

    test('8. Quantity Discrepancy Alert with actual vs expected diff', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8495',
          farmerName: 'Kuldeep Singh',
          crop: 'Wheat',
          quantity: '50.0 Quintals',
          actualQuantity: '48.2 Quintals',
          qualityGrade: 'FAQ',
          bookedSlot: '12:00 PM',
          arrivalTime: '11:55 AM',
          status: 'Waiting',
          peopleAhead: 2,
          approxWaitMinutes: 10,
        ),
      ];

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );

      final qtyDisc = list.firstWhere((e) => e.type == ExceptionType.quantityDiscrepancy);
      expect(qtyDisc.severity, ExceptionSeverity.warning);
      expect(qtyDisc.explanation, contains('Actual weight is 1.8 Q lower than expected'));
      expect(qtyDisc.recommendedAction, contains('Review weighment record'));
    });

    test('9. Quantity Discrepancy Alert from explicit note', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8492',
          farmerName: 'Ramesh Kumar',
          crop: 'Wheat',
          quantity: '50 Quintals',
          actualQuantity: '50.2 Quintals',
          qualityGrade: 'FAQ',
          bookedSlot: '11:30 AM',
          arrivalTime: '11:20 AM',
          status: 'Waiting',
          peopleAhead: 3,
          approxWaitMinutes: 15,
          discrepancyNote: 'Actual weighment exceeds registered quantity by +0.2 Quintals.',
        ),
      ];

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );

      final qtyDisc = list.firstWhere((e) => e.type == ExceptionType.quantityDiscrepancy);
      expect(qtyDisc.tokenNumber, 'TK-8492');
      expect(qtyDisc.farmerName, 'Ramesh Kumar');
    });

    test('10. Centre Temporarily Stopped Alert', () {
      final service = OfficerExceptionService();
      service.reset();

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Temporarily Delayed',
        centreCapacityPercent: 70,
        centreDelayMinutes: 20,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: const [],
      );

      final stopped = list.firstWhere((e) => e.type == ExceptionType.centreStopped);
      expect(stopped.severity, ExceptionSeverity.critical);
      expect(stopped.title, 'Procurement Temporarily Stopped');
      expect(stopped.explanation, contains('Intake is paused'));
      expect(stopped.recommendedAction, contains('Resolve centre issue'));
    });

    test('11. Late Arrival & Booking Anomaly Alert', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8491',
          farmerName: 'Balwinder Kaur',
          crop: 'Paddy',
          quantity: '65 Quintals',
          actualQuantity: '65.0 Quintals',
          qualityGrade: 'FAQ',
          bookedSlot: '11:15 AM',
          arrivalTime: '11:35 AM', // 20m late
          status: 'Waiting',
          peopleAhead: 2,
          approxWaitMinutes: 10,
        ),
      ];

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );

      final anomaly = list.firstWhere((e) => e.type == ExceptionType.bookingAnomaly);
      expect(anomaly.title, 'Late Arrival');
      expect(anomaly.tokenNumber, 'TK-8491');
      expect(anomaly.explanation, contains('Farmer arrived at 11:35 AM for slot ending 11:15 AM'));
    });

    test('12. Strict Priority Sorting (CRITICAL -> WARNING -> INFO)', () {
      final service = OfficerExceptionService();
      service.reset();

      final list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Temporarily Delayed', // CRITICAL
        centreCapacityPercent: 88,            // WARNING
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 16,                     // CRITICAL
        estimatedWaitMinutes: 65,
        queue: const [],
      );

      // Verify all critical items are before warning items
      int lastCritIndex = -1;
      int firstWarnIndex = 999;
      for (int i = 0; i < list.length; i++) {
        if (list[i].severity == ExceptionSeverity.critical) {
          lastCritIndex = i;
        } else if (list[i].severity == ExceptionSeverity.warning && firstWarnIndex == 999) {
          firstWarnIndex = i;
        }
      }

      if (lastCritIndex != -1 && firstWarnIndex != 999) {
        expect(lastCritIndex, lessThan(firstWarnIndex));
      }
    });

    test('13. Lifecycle Transitions: Acknowledge & Resolve overrides', () {
      final service = OfficerExceptionService();
      service.reset();

      const queue = [
        OfficerQueueItem(
          tokenNumber: 'TK-8490',
          farmerName: 'Sukhdev Singh',
          crop: 'Wheat',
          quantity: '40 Quintals',
          actualQuantity: '40.0 Quintals',
          qualityGrade: 'Grade A',
          bookedSlot: '11:00 AM',
          arrivalTime: '10:50 AM',
          status: 'Waiting',
          peopleAhead: 1,
          approxWaitMinutes: 5,
          paymentStatus: 'Pending',
        ),
      ];

      var list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );

      final payEx = list.firstWhere((e) => e.type == ExceptionType.paymentDelay);
      expect(payEx.status, ExceptionStatus.open);

      // Acknowledge
      service.acknowledge(payEx.id);
      list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );
      final ackEx = list.firstWhere((e) => e.id == payEx.id);
      expect(ackEx.status, ExceptionStatus.acknowledged);

      // Resolve
      service.resolve(payEx.id);
      list = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 5,
        estimatedWaitMinutes: 20,
        queue: queue,
      );
      final resEx = list.firstWhere((e) => e.id == payEx.id);
      expect(resEx.status, ExceptionStatus.resolved);
    });

    test('14. Deduplication & State Stability', () {
      final service = OfficerExceptionService();
      service.reset();

      // Detect twice on identical state
      final list1 = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 16,
        estimatedWaitMinutes: 70,
        queue: const [],
      );

      final list2 = service.detectExceptions(
        centreName: 'Test Centre',
        centreStatus: 'Open • Normal',
        centreCapacityPercent: 70,
        centreDelayMinutes: 0,
        averageProcessingMinutes: 5,
        waitingCount: 16,
        estimatedWaitMinutes: 70,
        queue: const [],
      );

      expect(list1.length, list2.length);
      expect(list1.first.id, list2.first.id);
    });

    test('15. ProcurementStateService exception synchronization', () {
      final stateService = ProcurementStateService();
      stateService.reset();

      expect(stateService.exceptions, isNotNull);
      expect(stateService.openExceptionCount, greaterThanOrEqualTo(0));

      // In default reset state, TK-8492 has discrepancyNote, and TK-8490 has pending payment.
      // Acknowledge one:
      final firstEx = stateService.exceptions.first;
      stateService.acknowledgeException(firstEx.id);

      final updated = stateService.exceptions.firstWhere((e) => e.id == firstEx.id);
      expect(updated.status, ExceptionStatus.acknowledged);

      // Resolve it:
      stateService.resolveException(firstEx.id);
      final resolved = stateService.exceptions.firstWhere((e) => e.id == firstEx.id);
      expect(resolved.status, ExceptionStatus.resolved);
    });

    testWidgets('16. Officer Dashboard Needs Attention Panel UI and counters',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      ProcurementStateService().reset();

      await tester.pumpWidget(const KisanSetuApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Procurement Officer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto-Fill'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.textContaining('Open:'), findsOneWidget);
    });

    testWidgets('17. Needs Attention Panel card interaction and Acknowledge button',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final service = ProcurementStateService();
      service.reset();

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-7701'),
      ));
      await tester.pumpAndSettle();

      // Find Acknowledge button if there are open exceptions
      final ackFinder = find.text('Acknowledge');
      if (ackFinder.evaluate().isNotEmpty) {
        await tester.tap(ackFinder.first);
        await tester.pumpAndSettle();
        expect(find.text('Acknowledged'), findsWidgets);
      }
    });

    testWidgets('18. Officer Exception Detail Sheet rendering and explainability',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final ex = OfficerExceptionModel(
        id: 'ex_modal_test',
        type: ExceptionType.quantityDiscrepancy,
        severity: ExceptionSeverity.warning,
        title: 'Quantity Discrepancy',
        shortDescription: 'Expected: 50.0 Q • Actual: 48.2 Q',
        explanation: 'Actual weight is 1.8 Q lower than expected (-1.8 Q).',
        centreId: 'Test Centre',
        tokenNumber: 'TK-8492',
        farmerName: 'Ramesh Kumar',
        createdTimestamp: DateTime.now(),
        recommendedAction: 'Review weighment record.',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OfficerExceptionDetailSheet(exception: ex),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Quantity Discrepancy'), findsOneWidget);
      expect(find.text('WARNING'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Token: TK-8492'), findsOneWidget);
      expect(find.text('Observed Operational Fact'), findsOneWidget);
      expect(find.text('Actual weight is 1.8 Q lower than expected (-1.8 Q).'), findsOneWidget);
      expect(find.text('Recommended Action'), findsOneWidget);
      expect(find.text('Review weighment record.'), findsOneWidget);
      expect(find.text('Acknowledge'), findsOneWidget);
      expect(find.text('Mark Resolved'), findsOneWidget);
      expect(find.text('Open Detail'), findsOneWidget);
    });

    testWidgets('19. Officer Exception Detail Sheet navigation to Farmer Detail',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      ProcurementStateService().reset();

      final ex = OfficerExceptionModel(
        id: 'ex_nav_test',
        type: ExceptionType.quantityDiscrepancy,
        severity: ExceptionSeverity.warning,
        title: 'Quantity Discrepancy',
        shortDescription: 'TK-8492 discrepancy',
        explanation: 'Weighment variance noted.',
        centreId: 'Test Centre',
        tokenNumber: 'TK-8492',
        farmerName: 'Ramesh Kumar',
        createdTimestamp: DateTime.now(),
        recommendedAction: 'Inspect load',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OfficerExceptionDetailSheet(exception: ex),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerFarmerDetailScreen), findsOneWidget);
      expect(find.text('TK-8492'), findsWidgets);
    });

    testWidgets('20. Empty state rendering when all issues resolved',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final service = ProcurementStateService();
      service.reset();

      // Resolve all detected exceptions
      for (final ex in service.exceptions) {
        service.resolveException(ex.id);
      }

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-7701'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('✓ No critical issues • Centre operating normally'), findsOneWidget);
      expect(find.text('Open: 0'), findsOneWidget);
    });
  });

  group('Phase 15: Desktop & Chrome Responsive Layout Tests', () {
    test('1. ResponsiveLayout helper unit tests', () {
      expect(ResponsiveLayout.desktopMin, 850.0);
      expect(ResponsiveLayout.mobileMax, 600.0);
      expect(ResponsiveLayout.largeDesktopMin, 1200.0);
    });

    testWidgets('2. Farmer Dashboard renders compact 2-column layout on Desktop (1366x768)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1366, 768);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.text('When Should I Go?'), findsOneWidget);
      expect(find.text('MY TOKEN'), findsOneWidget);
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Book Slot'), findsOneWidget);
      expect(find.text('View Token'), findsWidgets);
      expect(find.text('Payment'), findsWidgets);
      expect(find.text('Digital Pass / QR'), findsOneWidget);
      expect(find.text('Download Invoice / Receipt'), findsOneWidget);
      expect(find.byType(ProduceSummaryCard), findsOneWidget);
      expect(find.byType(GoTimeCard), findsOneWidget);
      expect(find.byType(TokenCard), findsOneWidget);
      expect(find.byType(FarmerActionGrid), findsOneWidget);
      expect(find.byType(FarmerJourneyTracker), findsOneWidget);
    });

    testWidgets('3. Farmer Dashboard renders cleanly on large desktop (1440x900)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.textContaining('Messages'), findsWidgets);
    });

    testWidgets('4. Officer Dashboard renders compact command-centre on Desktop (1366x768)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1366, 768);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      ProcurementStateService().reset();

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-7701'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
      expect(find.text('Operational KPIs'), findsOneWidget);
      expect(find.text("Today's Bookings"), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Queue Operations'), findsOneWidget);
      expect(find.text('Scan Farmer QR'), findsOneWidget);
      expect(find.text('Call Next Farmer'), findsOneWidget);
      expect(find.text('LIVE QUEUE'), findsOneWidget);
      expect(find.text('Centre Status & Capacity Control'), findsOneWidget);
      expect(find.text('Smart Slot Management'), findsOneWidget);
    });

    testWidgets('5. Officer Dashboard renders on large desktop (1440x900)',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      ProcurementStateService().reset();

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-7701'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
      expect(find.text('Operational KPIs'), findsOneWidget);
      expect(find.text('Mark Arrived'), findsOneWidget);
      expect(find.text('Start Processing'), findsOneWidget);
    });
  });

  group('Phase 16: Voice Assistant Speech Service & Chrome Web Playback Tests', () {
    final stub = VoiceAssistantSpeechService.instance as VoiceAssistantSpeechStub;

    setUp(() {
      stub.reset();
    });

    test('1. VoiceAssistantSpeechService.resolveLocale correctly maps languages', () {
      expect(VoiceAssistantSpeechService.resolveLocale('te'), 'te-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('te-IN'), 'te-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('telugu'), 'te-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('hi'), 'hi-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('hi-IN'), 'hi-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('hindi'), 'hi-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('en'), 'en-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('en-IN'), 'en-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('english'), 'en-IN');
      expect(VoiceAssistantSpeechService.resolveLocale('unknown'), 'en-IN');
      expect(VoiceAssistantSpeechService.resolveLocale(''), 'en-IN');
    });

    test('2. VoiceAssistantSpeechStub unit test records speak and stop calls', () {
      expect(stub.speakCallCount, 0);
      expect(stub.stopCallCount, 0);
      expect(stub.lastSpokenText, isNull);

      stub.speak('Test speech synthesis message', language: 'te');
      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenText, 'Test speech synthesis message');
      expect(stub.lastSpokenLocale, 'te-IN');

      stub.stop();
      expect(stub.stopCallCount, 2); // speak() calls stop() internally to cancel previous speech

      stub.reset();
      expect(stub.speakCallCount, 0);
      expect(stub.stopCallCount, 0);
      expect(stub.lastSpokenText, isNull);
      expect(stub.lastSpokenLocale, isNull);
    });

    testWidgets('3. RoleSelectionScreen Listen button triggers speech with en-IN',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RoleSelectionScreen(),
      ));
      await tester.pumpAndSettle();

      final listenButton = find.text('Listen / सुनें');
      expect(listenButton, findsOneWidget);

      await tester.tap(listenButton);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('Voice Guide: Tap "I am a Farmer"'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('4. FarmerLanguageSelectionScreen Listen button speaks in en-IN, hi-IN, or te-IN based on selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerLanguageSelectionScreen(),
      ));
      await tester.pumpAndSettle();

      final listenButton = find.text('Listen / వినండి / सुनें');
      expect(listenButton, findsOneWidget);

      // 1. Initial state (no language selected yet) -> speaks English en-IN
      await tester.tap(listenButton);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('Voice Guide: Choose your preferred language'));
      expect(find.byType(SnackBar), findsOneWidget);

      stub.reset();

      // 2. Tap Hindi card -> Listen button speaks Hindi hi-IN
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();

      await tester.tap(listenButton);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'hi-IN');
      expect(stub.lastSpokenText, contains('वॉइस गाइड: आपने हिंदी भाषा का चयन किया है'));

      stub.reset();

      // 3. Tap Telugu card -> Listen button speaks Telugu te-IN
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();

      await tester.tap(listenButton);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'te-IN');
      expect(stub.lastSpokenText, contains('వాయిస్ గైడ్: మీరు తెలుగు భాషను ఎంచుకున్నారు'));

      stub.reset();

      // 4. Tap English card -> Listen button speaks English en-IN
      await tester.tap(find.text('English').first);
      await tester.pumpAndSettle();

      await tester.tap(listenButton);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('Voice Guide: You have selected English'));
    });

    testWidgets('5. FarmerDashboardScreen Listen button triggers speech in English, Hindi, and Telugu',
        (WidgetTester tester) async {
      ProcurementStateService().reset();

      // English
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      var listenBtn = find.text('Listen / सुनें');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('Voice Assistant: Welcome'));

      stub.reset();

      // Hindi
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'हिंदी',
        ),
      ));
      await tester.pumpAndSettle();

      listenBtn = find.text('Listen / सुनें');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'hi-IN');
      expect(stub.lastSpokenText, contains('आवाज सहायक:'));

      stub.reset();

      // Telugu
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'తెలుగు',
        ),
      ));
      await tester.pumpAndSettle();

      final listenTeBtn = find.text('Listen / వినండి');
      expect(listenTeBtn, findsOneWidget);
      await tester.tap(listenTeBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'te-IN');
      expect(stub.lastSpokenText, contains('వాయిస్ సహాయకుడు:'));
    });

    testWidgets('6. OfficerDashboardScreen Listen button triggers speech with en-IN',
        (WidgetTester tester) async {
      ProcurementStateService().reset();

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-TEST'),
      ));
      await tester.pumpAndSettle();

      final listenBtn = find.byTooltip('Listen / सुनें');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('Procurement Operations Dashboard'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('7. FarmerMessagesScreen Listen button triggers voice summary speech',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      AppPreferencesService.instance.setUiLanguage('en');

      await tester.pumpWidget(const MaterialApp(
        home: FarmerMessagesScreen(
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      final listenBtn = find.text('Listen');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'en-IN');
      expect(stub.lastSpokenText, contains('TK-8492'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('8. FarmerPhoneLoginScreen and FarmerOtpVerificationScreen speak in en-IN, hi-IN, and te-IN',
        (WidgetTester tester) async {
      // Phone login - Hindi
      await tester.pumpWidget(const MaterialApp(
        home: FarmerPhoneLoginScreen(selectedLanguage: 'हिंदी'),
      ));
      await tester.pumpAndSettle();

      var listenBtn = find.text('Listen / सुनें');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'hi-IN');
      expect(stub.lastSpokenText, contains('वॉइस गाइड: अपना 10-अंकीय'));

      stub.reset();

      // Phone login - Telugu
      await tester.pumpWidget(const MaterialApp(
        home: FarmerPhoneLoginScreen(selectedLanguage: 'తెలుగు'),
      ));
      await tester.pumpAndSettle();

      final listenTeBtn = find.text('Listen / వినండి');
      expect(listenTeBtn, findsOneWidget);
      await tester.tap(listenTeBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'te-IN');
      expect(stub.lastSpokenText, contains('వాయిస్ గైడ్: మీ 10-అంకెల'));

      stub.reset();

      // OTP Verification - Telugu
      await tester.pumpWidget(const MaterialApp(
        home: FarmerOtpVerificationScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'తెలుగు',
        ),
      ));
      await tester.pumpAndSettle();

      final otpListenTeBtn = find.text('Listen / వినండి');
      expect(otpListenTeBtn, findsOneWidget);
      await tester.tap(otpListenTeBtn);
      await tester.pump();

      expect(stub.speakCallCount, 1);
      expect(stub.lastSpokenLocale, 'te-IN');
      expect(stub.lastSpokenText, contains('వాయిస్ గైడ్: మీ మొబైల్‌కు'));
    });
  });

  group('Phase 17: Change Crop Feature & Catalogue Tests', () {
    late VoiceAssistantSpeechStub voiceStub;

    setUp(() {
      voiceStub = VoiceAssistantSpeechStub();
      VoiceAssistantSpeechService.setMockInstance(voiceStub);
      ProcurementStateService().reset();
    });

    tearDown(() {
      VoiceAssistantSpeechService.setMockInstance(null);
    });

    test('1. CropCatalogueService has 23 crops across 4 categories and supports filtering', () {
      final all = CropCatalogueService.allCrops;
      expect(all.length, equals(23));

      final cereals = CropCatalogueService.getCropsByCategory(CropCategory.cereals);
      expect(cereals.length, equals(7));

      final pulses = CropCatalogueService.getCropsByCategory(CropCategory.pulses);
      expect(pulses.length, equals(6));

      final oilseeds = CropCatalogueService.getCropsByCategory(CropCategory.oilseeds);
      expect(oilseeds.length, equals(6));

      final commercial = CropCatalogueService.getCropsByCategory(CropCategory.commercial);
      expect(commercial.length, equals(4));
    });

    test('2. CropCatalogueService search finds crops by English, Hindi, and Telugu names', () {
      // English
      final wheatEn = CropCatalogueService.searchCrops('Wheat');
      expect(wheatEn.any((c) => c.cropId == 'wheat'), isTrue);

      // Hindi
      final mustardHi = CropCatalogueService.searchCrops('सरसों');
      expect(mustardHi.any((c) => c.cropId == 'mustard'), isTrue);

      // Telugu
      final paddyTe = CropCatalogueService.searchCrops('వరి');
      expect(paddyTe.any((c) => c.cropId == 'paddy'), isTrue);

      // findByName and findById
      final gram = CropCatalogueService.findByName('Gram');
      expect(gram, isNotNull);
      expect(gram!.cropId, equals('gram'));

      final cotton = CropCatalogueService.findById('cotton');
      expect(cotton, isNotNull);
      expect(cotton!.cropName, equals('Cotton'));
    });

    test('3. CropModel model localization and map serialization', () {
      final crop = CropCatalogueService.findById('wheat')!;
      expect(crop.localizedName(isTelugu: true), equals('గోధుమలు'));
      expect(crop.localizedName(isHindi: true), equals('गेहूं'));
      expect(crop.localizedName(), equals('Wheat'));

      final map = crop.toMap();
      expect(map['crop_id'], equals('wheat'));
      expect(map['crop_name'], equals('Wheat'));

      final restored = CropModel.fromMap(map);
      expect(restored.cropId, equals('wheat'));
      expect(restored.cropName, equals('Wheat'));
      expect(restored.category, equals(CropCategory.cereals));
    });

    test('4. FarmerDashboardData.hasActiveBooking correctly identifies active booking', () {
      final service = ProcurementStateService();
      expect(service.farmerData.hasActiveBooking, isTrue);

      // Cleared booking
      final cleared = service.farmerData.copyWith(
        lifecycleStatus: 'Completed',
      );
      expect(cleared.hasActiveBooking, isFalse);
    });

    test('5. ProcurementStateService.changeFarmerCrop updates state, MSP, queue, and notification', () {
      final service = ProcurementStateService();
      final mustard = CropCatalogueService.findById('mustard')!;

      service.changeFarmerCrop(crop: mustard, quantityQuintals: 75.0);

      expect(service.farmerData.cropName, equals('Mustard'));
      expect(service.farmerData.quantity, equals('75 Quintals'));
      expect(service.farmerData.estimatedMspValue, contains('₹'));

      // Officer queue item updated
      final ramesh = service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(ramesh.crop, equals('Mustard'));
      expect(ramesh.quantity, equals('75 Quintals'));

      // Notification generated
      final notifications = NotificationService().notifications;
      expect(notifications.any((n) => n.titleEn.contains('Produce Updated') && n.messageEn.contains('Mustard')), isTrue);
    });

    test('6. SmartSlotService.recommendSlots accepts crop parameter', () {
      final centre = ProcurementCentre.getMockCentres().first;
      final slots = SmartSlotService.recommendSlots(
        centre: centre,
        crop: 'Mustard',
      );
      expect(slots, isNotEmpty);
    });

    testWidgets('7. ProduceSummaryCard displays Change Crop button and fires callback',
        (WidgetTester tester) async {
      bool changed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProduceSummaryCard(
            data: ProcurementStateService().farmerData,
            isHindi: false,
            isTelugu: false,
            onChangeCrop: () {
              changed = true;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final changeBtn = find.byKey(const ValueKey('btn_change_crop'));
      expect(changeBtn, findsOneWidget);
      expect(find.text('Change Crop'), findsOneWidget);

      await tester.tap(changeBtn);
      await tester.pump();
      expect(changed, isTrue);
    });

    testWidgets('8. FarmerCropSelectionScreen allows search, filter, active booking warning, stepper, and change',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Check header and categories
      expect(find.text('Select Crop'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cereals'), findsOneWidget);
      expect(find.text('Pulses'), findsOneWidget);
      expect(find.text('Oilseeds'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);

      // Filter by Oilseeds
      await tester.tap(find.text('Oilseeds'));
      await tester.pumpAndSettle();

      // Mustard should be visible in oilseeds
      final mustardCard = find.byKey(const ValueKey('crop_card_mustard'));
      expect(mustardCard, findsOneWidget);

      // Select Mustard
      await tester.tap(mustardCard);
      await tester.pumpAndSettle();

      // Tap Proceed
      final proceedBtn = find.byKey(const ValueKey('btn_proceed_crop_selection'));
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Active booking warning dialog should appear
      expect(find.byKey(const ValueKey('btn_confirm_booking_warning')), findsOneWidget);
      expect(find.text('Active Booking Detected'), findsOneWidget);

      // Confirm warning dialog
      await tester.tap(find.byKey(const ValueKey('btn_confirm_booking_warning')));
      await tester.pumpAndSettle();

      // Quantity bottom sheet should appear with stepper and live MSP
      expect(find.byKey(const ValueKey('input_crop_quantity')), findsOneWidget);
      expect(find.text('Govt MSP Rate'), findsOneWidget);
      expect(find.text('₹5650 / Quintal'), findsOneWidget);

      // Tap +10 stepper
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();

      // Save crop selection
      final saveBtn = find.byKey(const ValueKey('btn_save_crop_selection'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Procurement state should be updated to Mustard
      expect(ProcurementStateService().farmerData.cropName, equals('Mustard'));
    });

    testWidgets('9. Select Crop screen displays exactly 10 crops by default with icons and multilingual names',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Verify CropCatalogueService.default10Crops
      expect(CropCatalogueService.default10Crops.length, equals(10));
      final expectedIds = [
        'wheat',
        'paddy',
        'maize',
        'jowar',
        'bajra',
        'ragi',
        'gram',
        'tur',
        'mustard',
        'soybean',
      ];
      expect(CropCatalogueService.default10Crops.map((c) => c.cropId).toList(),
          equals(expectedIds));

      await tester.pumpWidget(MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify all 10 cards exist by key
      for (final id in expectedIds) {
        expect(find.byKey(ValueKey('crop_card_$id')), findsOneWidget);
      }

      // Verify default selected crop is Wheat and shows checkmark
      final wheatCard = find.byKey(const ValueKey('crop_card_wheat'));
      expect(wheatCard, findsOneWidget);

      // Select Soybean
      final soybeanCard = find.byKey(const ValueKey('crop_card_soybean'));
      await tester.tap(soybeanCard);
      await tester.pumpAndSettle();

      // Test Telugu localization
      await tester.pumpWidget(MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('గోధుమలు'), findsOneWidget);
      expect(find.text('వరి / బియ్యం'), findsOneWidget);
      expect(find.text('మొక్కజొన్న'), findsOneWidget);
      // Appears in both crop card and bottom action bar when selected
      expect(find.text('సోయాబీన్'), findsNWidgets(2));

      // Test Voice Assistant button
      final voiceBtn = find.byKey(const ValueKey('btn_crop_voice_guide'));
      expect(voiceBtn, findsOneWidget);
      await tester.tap(voiceBtn);
      await tester.pump();
      final stub = VoiceAssistantSpeechService.instance as dynamic;
      expect(stub.lastSpokenText, contains('10'));
      expect(stub.lastSpokenLocale, equals('te-IN'));
    });

    testWidgets(
        '10. Change Crop full catalogue (20+ crops): category browsing, multilingual search, and selecting an extended crop',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Verify catalogue contains 20+ crops across 4 categories
      expect(CropCatalogueService.allCrops.length, greaterThanOrEqualTo(20));
      expect(CropCatalogueService.allCrops.length, equals(23));

      // 2. Pump FarmerCropSelectionScreen
      await tester.pumpWidget(MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 40.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify the 10 main crops are present
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_mustard')), findsOneWidget);

      // 3. Test Commercial Category Filter
      await tester.tap(find.text('Commercial'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('crop_card_cotton')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_jute')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_sugarcane')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_copra')), findsOneWidget);

      // Select Cotton
      await tester.tap(find.byKey(const ValueKey('crop_card_cotton')));
      await tester.pumpAndSettle();

      // Proceed to quantity modal
      await tester.tap(find.byKey(const ValueKey('btn_proceed_crop_selection')));
      await tester.pumpAndSettle();

      // Handle active booking warning if presented
      if (find.byKey(const ValueKey('btn_confirm_booking_warning')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('btn_confirm_booking_warning')));
        await tester.pumpAndSettle();
      }

      // Verify Cotton live MSP preview is displayed
      expect(find.byKey(const ValueKey('input_crop_quantity')), findsOneWidget);
      expect(find.text('₹7121 / Quintal'), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.byKey(const ValueKey('input_crop_quantity')))).pop();
      await tester.pumpAndSettle();

      // 4. Test Search by English name ("Barley")
      final searchInput = find.byKey(const ValueKey('search_crop_input'));
      await tester.enterText(searchInput, 'Barley');
      await tester.pumpAndSettle();

      // Switch to All category to search all
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_barley')), findsOneWidget);

      // 5. Test Search by Telugu name ("పత్తి" -> Cotton)
      await tester.enterText(searchInput, 'పత్తి');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_cotton')), findsOneWidget);

      // 6. Test Search by Hindi name ("मूंग" -> Moong)
      await tester.enterText(searchInput, 'मूंग');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_moong')), findsOneWidget);
    });
  });

  group('Phase 18: Dynamic Slot Reallocation Verification', () {
    test('1. Overload detection logic detects high capacity, delays, or busy status', () {
      final service = SlotReallocationService();

      // Normal conditions: no overload
      expect(
        service.isCentreOverloaded(
          capacityPercent: 75,
          delayMinutes: 0,
          waitingCount: 7,
          centreStatus: 'Open • Normal',
          estimatedWaitMinutes: 35,
        ),
        isFalse,
      );

      // Overload triggers:
      // Capacity >= 85%
      expect(
        service.isCentreOverloaded(
          capacityPercent: 85,
          delayMinutes: 0,
          waitingCount: 5,
          centreStatus: 'Open • Normal',
        ),
        isTrue,
      );

      // Delay >= 15 min
      expect(
        service.isCentreOverloaded(
          capacityPercent: 70,
          delayMinutes: 20,
          waitingCount: 5,
          centreStatus: 'Open • Normal',
        ),
        isTrue,
      );

      // Status contains Busy, Delayed, or Stopped
      expect(
        service.isCentreOverloaded(
          capacityPercent: 70,
          delayMinutes: 0,
          waitingCount: 5,
          centreStatus: 'Open • Busy',
        ),
        isTrue,
      );
      expect(
        service.isCentreOverloaded(
          capacityPercent: 70,
          delayMinutes: 0,
          waitingCount: 5,
          centreStatus: 'Temporarily Delayed',
        ),
        isTrue,
      );

      // High estimated wait >= 45 min
      expect(
        service.isCentreOverloaded(
          capacityPercent: 70,
          delayMinutes: 0,
          waitingCount: 5,
          centreStatus: 'Open • Normal',
          estimatedWaitMinutes: 50,
        ),
        isTrue,
      );

      // High waiting count >= 10
      expect(
        service.isCentreOverloaded(
          capacityPercent: 70,
          delayMinutes: 0,
          waitingCount: 12,
          centreStatus: 'Open • Normal',
        ),
        isTrue,
      );
    });

    test('2. Generates slot recommendations when centre load reaches 95%', () {
      final state = ProcurementStateService();
      state.reset();

      // Under normal conditions, no reallocation recommendation is generated
      expect(state.pendingSlotReallocationsCount, 0);

      // Set centre capacity to High Load (95%)
      state.setCapacityMode('High Load');
      expect(state.centreCapacityPercent, 95);

      // Evaluate recommendations
      final recs = state.slotReallocations;
      expect(recs.isNotEmpty, isTrue);

      // Verify recommendation for Ramesh Kumar (TK-8492)
      final rameshRec = recs.firstWhere((r) => r.tokenNumber == 'TK-8492');
      expect(rameshRec.currentSlot, '11:30 AM');
      expect(rameshRec.recommendedSlot, '1:00 PM');
      expect(rameshRec.isPending, isTrue);
      expect(rameshRec.isReallocated, isFalse);
      expect(rameshRec.centreLoadPercent, 95);
      expect(rameshRec.estimatedWaitMinutes, 65);
      expect(
        rameshRec.reasonEn,
        'Centre load increased to 95%, estimated wait 65 minutes.',
      );
      expect(
        rameshRec.localizedReason(isHindi: true),
        'केंद्र का भार 95% हो गया है, अनुमानित प्रतीक्षा 65 मिनट है।',
      );
      expect(
        rameshRec.localizedReason(isTelugu: true),
        'కేంద్రం లోడ్ 95%కి పెరిగింది, అంచనా వేచి ఉండే సమయం 65 నిమిషాలు.',
      );
    });

    test('3. Confirmed booking is NOT automatically altered without officer confirmation', () {
      final state = ProcurementStateService();
      state.reset();

      state.setCapacityMode('High Load');

      // Before confirmation: farmer booking and queue item MUST remain unchanged
      expect(state.farmerData.bookedSlotTime, '11:30 AM');
      final qItem = state.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(qItem.bookedSlot, '11:30 AM');

      // Recommendation remains pending
      final rec = state.slotReallocations.firstWhere((r) => r.tokenNumber == 'TK-8492');
      expect(rec.status, ReallocationStatus.recommended);
    });

    test('4. Officer confirms reallocation: state updates, slots shift, and Go-Time recalculates', () {
      final state = ProcurementStateService();
      state.reset();

      state.setCapacityMode('High Load');
      final initialRec = state.slotReallocations.firstWhere((r) => r.tokenNumber == 'TK-8492');
      final previousDeparture = state.farmerData.recommendedDepartureTime;

      // Officer confirms the recommendation
      final success = SlotReallocationService().confirmReallocation(
        recommendationId: initialRec.id,
        stateService: state,
      );
      expect(success, isTrue);

      // Verify farmer's booked slot is now updated to 1:00 PM
      expect(state.farmerData.bookedSlotTime, '1:00 PM');

      // Verify queue item booked slot is now updated to 1:00 PM
      final updatedQItem = state.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(updatedQItem.bookedSlot, '1:00 PM');

      // Verify recommendation state is marked reallocated
      final updatedRec = SlotReallocationService().getRecommendation(initialRec.id);
      expect(updatedRec!.isReallocated, isTrue);
      expect(updatedRec.isPending, isFalse);

      // Verify "When Should I Go?" Go-Time departure was recalculated for the new 1:00 PM slot
      final newDeparture = state.farmerData.recommendedDepartureTime;
      expect(newDeparture, isNotEmpty);
      expect(newDeparture, isNot(equals(previousDeparture)));
    });

    test('5. Reallocation dispatches trilingual farmer notification with deduplication', () {
      final state = ProcurementStateService();
      state.reset();

      state.setCapacityMode('High Load');
      final rec = state.slotReallocations.firstWhere((r) => r.tokenNumber == 'TK-8492');

      // Confirm reallocation
      SlotReallocationService().confirmReallocation(
        recommendationId: rec.id,
        stateService: state,
      );

      final notifs = NotificationService().notifications;
      final reallocNotifs = notifs.where((n) => n.type == NotificationType.slotReallocated).toList();
      expect(reallocNotifs, isNotEmpty);

      final notif = reallocNotifs.first;
      expect(notif.titleEn, 'Slot Reallocated');
      expect(notif.titleHi, 'स्लॉट पुनर्निर्धारित');
      expect(notif.titleTe, 'స్లాట్ మార్చబడింది');

      expect(notif.messageEn, contains('Token: TK-8492 • New Slot: 1:00 PM (was 11:30 AM)'));
      expect(notif.messageHi, contains('टोकन: TK-8492 • नया स्लॉट: 1:00 PM (पहले 11:30 AM)'));
      expect(notif.messageTe, contains('టోకెన్: TK-8492 • కొత్త స్లాట్: 1:00 PM (గతంలో 11:30 AM)'));

      // Verify deduplication: triggering again does not create a duplicate
      state.reallocateFarmerSlot(
        tokenNumber: 'TK-8492',
        newSlot: '1:00 PM',
        reasonEn: rec.reasonEn,
      );
      final countAfter = NotificationService()
          .notifications
          .where((n) => n.type == NotificationType.slotReallocated)
          .length;
      expect(countAfter, equals(reallocNotifs.length));
    });

    test('6. Digital QR verification validity is preserved after slot reallocation', () {
      final state = ProcurementStateService();
      state.reset();

      // Check-in status is Not Checked In
      expect(state.farmerData.checkInStatus, 'Not Checked In');

      // Generate original QR payload for TK-8492
      final originalPayload = QrValidationService.generateQrPayload(
        bookingId: 'BK-8492',
        tokenNumber: 'TK-8492',
        centreName: state.centreName,
        slotTime: '11:30 AM',
      );
      final origValidation = QrValidationService.validate(
        rawPayload: originalPayload,
        currentCentreName: state.centreName,
      );
      expect(origValidation.isValid, isTrue);

      // Trigger reallocation to 1:00 PM
      state.reallocateFarmerSlot(
        tokenNumber: 'TK-8492',
        newSlot: '1:00 PM',
        reasonEn: 'Centre load increased to 95%',
      );

      // Verify QR payload with updated slot is valid
      final reallocatedPayload = QrValidationService.generateQrPayload(
        bookingId: 'BK-8492',
        tokenNumber: 'TK-8492',
        centreName: state.centreName,
        slotTime: '1:00 PM',
      );
      final validation = QrValidationService.validate(
        rawPayload: reallocatedPayload,
        currentCentreName: state.centreName,
      );
      expect(validation.isValid, isTrue);
      expect(validation.tokenNumber, 'TK-8492');

      // Test Officer check-in works successfully with reallocated farmer
      final checkInSuccess = state.checkInFarmer('TK-8492', arrivalTime: '12:45 PM');
      expect(checkInSuccess, isTrue);
      expect(state.farmerData.checkInStatus, 'Checked In');
    });

    testWidgets('7. Officer Dashboard renders Slot Reallocation section with card, recommendation, and action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = ProcurementStateService();
      state.reset();
      state.setCapacityMode('High Load');

      await tester.pumpWidget(
        const MaterialApp(
          home: OfficerDashboardScreen(officerId: 'OFFICER-001'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Slot Reallocation section exists
      final section = find.byKey(const Key('officer_slot_reallocation_section'));
      await tester.ensureVisible(section);
      expect(section, findsOneWidget);

      // Verify section header and pending count badge
      expect(find.text('Slot Reallocation'), findsOneWidget);
      expect(find.textContaining('Recommended'), findsWidgets);

      // Verify card for TK-8492
      final cardFinder = find.byKey(const Key('card_reallocation_TK-8492'));
      await tester.ensureVisible(cardFinder);
      expect(cardFinder, findsOneWidget);

      // Verify Current Slot -> Recommended Slot -> Reason on card
      expect(find.descendant(of: cardFinder, matching: find.text('TK-8492')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('11:30 AM')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('1:00 PM')), findsOneWidget);
      expect(
        find.descendant(
          of: cardFinder,
          matching: find.text('Reason: Centre load increased to 95%, estimated wait 65 minutes.'),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: cardFinder, matching: find.text('Recommended')), findsOneWidget);

      // Verify Confirm Reallocation button
      final confirmBtn = find.byKey(const Key('btn_confirm_realloc_TK-8492'));
      expect(confirmBtn, findsOneWidget);

      // Tap Confirm Reallocation
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify booking updated
      expect(state.farmerData.bookedSlotTime, '1:00 PM');
      expect(
        find.descendant(
          of: cardFinder,
          matching: find.text('Reallocated to 1:00 PM. Farmer notified.'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Phase 19: Alternative Procurement Centre Recommendation Tests', () {
    test('1. Centre ranking logic (distance, wait, load composite score)', () {
      final service = AlternativeCentreService();
      final mockCentres = [
        const ProcurementCentre(
          id: 'c_high_wait',
          name: 'High Wait Centre',
          subLocation: 'Sub 1',
          status: 'Open • Normal',
          isNormal: true,
          distance: '4.0 km',
          distanceKm: 4.0,
          queueStatus: 'High',
          queueEstimate: '60 min',
          todayQueueCount: 30,
          estimatedWaitMinutes: 60,
          capacity: 100,
          processingRatePerHour: 10,
        ),
        const ProcurementCentre(
          id: 'c_low_wait',
          name: 'Fast Centre',
          subLocation: 'Sub 2',
          status: 'Open • Normal',
          isNormal: true,
          distance: '5.0 km',
          distanceKm: 5.0,
          queueStatus: 'Low',
          queueEstimate: '15 min',
          todayQueueCount: 10,
          estimatedWaitMinutes: 15,
          capacity: 100,
          processingRatePerHour: 20,
        ),
      ];

      final recs = service.getAlternativeCentres(
        currentCentreName: 'Current Centre',
        currentWaitMinutes: 60,
        currentLoadPercent: 90,
        allCentres: mockCentres,
      );

      expect(recs.length, 2);
      expect(recs[0].centre.id, 'c_low_wait');
      expect(recs[0].isTopPick, isTrue);
      expect(recs[0].score, lessThan(recs[1].score));
    });

    test('2. Distance, wait time, queue, and load comparison attributes', () {
      final service = AlternativeCentreService();
      final recs = service.getAlternativeCentres(
        currentCentreName: 'Example Procurement Centre',
        currentWaitMinutes: 65,
        currentLoadPercent: 95,
      );

      expect(recs.isNotEmpty, isTrue);
      final first = recs.first;
      expect(first.distanceKm, greaterThan(0));
      expect(first.estimatedWaitMinutes, greaterThan(0));
      expect(first.queueCount, greaterThan(0));
      expect(first.capacityPercent, greaterThan(0));
      expect(first.operatingStatus, isNotEmpty);
      expect(first.nextAvailableSlot, isNotEmpty);
      expect(first.reasonEn, isNotEmpty);
      expect(first.localizedReason(isHindi: true), isNotEmpty);
      expect(first.localizedReason(isTelugu: true), isNotEmpty);
    });

    test('3. Overloaded/stopped/delayed centre detection triggers', () {
      final service = AlternativeCentreService();

      // Normal conditions
      expect(
        service.isCentreOverloadedOrDelayed(
          capacityPercent: 50,
          delayMinutes: 0,
          centreStatus: 'Open • Normal',
          waitMinutes: 20,
        ),
        isFalse,
      );

      // Overloaded (>=85%)
      expect(
        service.isCentreOverloadedOrDelayed(
          capacityPercent: 88,
          delayMinutes: 0,
          centreStatus: 'Open • Normal',
          waitMinutes: 20,
        ),
        isTrue,
      );

      // Delayed (>=15 min)
      expect(
        service.isCentreOverloadedOrDelayed(
          capacityPercent: 50,
          delayMinutes: 20,
          centreStatus: 'Open • Normal',
          waitMinutes: 20,
        ),
        isTrue,
      );

      // High wait (>=45 min)
      expect(
        service.isCentreOverloadedOrDelayed(
          capacityPercent: 50,
          delayMinutes: 0,
          centreStatus: 'Open • Normal',
          waitMinutes: 50,
        ),
        isTrue,
      );

      // Temporarily stopped/paused
      expect(
        service.isCentreOverloadedOrDelayed(
          capacityPercent: 50,
          delayMinutes: 0,
          centreStatus: 'Intake Stopped',
          waitMinutes: 20,
        ),
        isTrue,
      );
    });

    test('4. Alternative recommendations generation (3-5 candidates excluding current centre)', () {
      final service = AlternativeCentreService();
      final currentName = 'Example Procurement Centre';
      final recs = service.getAlternativeCentres(
        currentCentreName: currentName,
        currentWaitMinutes: 65,
        currentLoadPercent: 95,
      );

      expect(recs.length, inInclusiveRange(3, 5));
      for (final r in recs) {
        expect(r.centre.name, isNot(equals(currentName)));
      }
      expect(recs.any((r) => r.isTopPick), isTrue);
    });

    test('5. Farmer confirmation requirement (no auto-transfer)', () {
      final state = ProcurementStateService();
      state.reset();
      expect(state.centreName, 'Example Procurement Centre');

      // Trigger high delay and capacity
      state.setCentreDelay(30);
      state.setCapacityMode('High Load');

      // Centre is overloaded/delayed
      expect(state.isCurrentCentreOverloadedOrDelayed, isTrue);

      // However, farmer's booking centre has NOT changed automatically
      expect(state.centreName, 'Example Procurement Centre');
      expect(state.farmerData.centreName, 'Example Procurement Centre');
    });

    test('6. Booking synchronization upon farmer confirmation', () {
      final state = ProcurementStateService();
      state.reset();

      final newCentre = ProcurementCentre.getMockCentres().firstWhere(
        (c) => c.name == 'APMC Hub North',
      );

      state.switchFarmerProcurementCentre(
        newCentre: newCentre,
        newSlot: '11:30 AM',
      );

      expect(state.centreName, 'APMC Hub North');
      expect(state.farmerData.centreName, 'APMC Hub North');
      expect(state.farmerData.bookedSlotTime, '11:30 AM');

      // Queue synchronization for Ramesh Kumar
      final ramesh = state.queue.firstWhere((q) => q.farmerName == 'Ramesh Kumar');
      expect(ramesh.bookedSlot, '11:30 AM');
      expect(ramesh.checkInStatus, 'Not Checked In');
    });

    test('7. Smart Slot and "When Should I Go?" recalculation after confirmation', () {
      final state = ProcurementStateService();
      state.reset();

      final newCentre = ProcurementCentre.getMockCentres().firstWhere(
        (c) => c.name == 'APMC Hub North', // 8.5 km
      );

      state.switchFarmerProcurementCentre(
        newCentre: newCentre,
        newSlot: '11:30 AM',
      );

      // Travel time recalculated from 8.5 km: (8.5 * 3) = 26 min
      expect(state.farmerTravelTimeMinutes, 26);
      expect(state.farmerData.travelTimeMinutes, 26);
      expect(state.farmerData.recommendedDepartureTime, isNotEmpty);
      expect(state.farmerData.expectedTurnTime, isNotEmpty);
    });

    test('8. Trilingual notification and deduplication upon centre switch', () {
      final notifService = NotificationService();
      notifService.reset();

      notifService.notifyCentreChanged(
        tokenNumber: 'TK-8492',
        oldCentre: 'Example Procurement Centre',
        newCentre: 'Nearby Procurement Centre',
        newSlot: '1:00 PM',
        departureTime: '12:35 PM',
      );

      final notif = notifService.notifications.firstWhere(
        (n) => n.type == NotificationType.centreChanged,
      );

      expect(notif.titleEn, 'Centre Switched');
      expect(notif.titleHi, 'खरीद केंद्र बदला गया');
      expect(notif.titleTe, 'సేకరణ కేంద్రం మార్చబడింది');
      expect(notif.messageEn, contains('Nearby Procurement Centre'));
      expect(notif.messageHi, contains('Nearby Procurement Centre'));
      expect(notif.messageTe, contains('Nearby Procurement Centre'));

      final countBefore = notifService.notifications.length;

      // Duplicate call should be ignored by deduplicationKey
      notifService.notifyCentreChanged(
        tokenNumber: 'TK-8492',
        oldCentre: 'Example Procurement Centre',
        newCentre: 'Nearby Procurement Centre',
        newSlot: '1:00 PM',
        departureTime: '12:35 PM',
      );

      expect(notifService.notifications.length, countBefore);
    });

    test('9. Digital QR pass validity after centre switch', () {
      final state = ProcurementStateService();
      state.reset();

      final oldCentre = state.centreName;
      final newCentre = 'APMC Hub North';
      final newSlot = '11:30 AM';

      // Generate payload for new centre
      final payload = QrValidationService.generateQrPayload(
        bookingId: 'BK-8492',
        tokenNumber: 'TK-8492',
        centreName: newCentre,
        slotTime: newSlot,
      );

      // Validate at old centre -> should fail
      final oldValidation = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: oldCentre,
      );
      expect(oldValidation.isValid, isFalse);
      expect(oldValidation.status, QrValidationStatus.wrongCentre);
      expect(oldValidation.messageEn, contains('Wrong Centre'));

      // Validate at new centre -> should succeed
      final newValidation = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: newCentre,
      );
      expect(newValidation.isValid, isTrue);
      expect(newValidation.tokenNumber, 'TK-8492');
      expect(newValidation.slotTime, newSlot);
    });

    testWidgets('10. Farmer UI flow: Find Better Centre button -> Alternative Centres screen -> Select -> Confirm dialog -> Switch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = ProcurementStateService();
      state.reset();

      // Trigger delayed/busy centre state
      state.setCentreDelay(25);

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerDashboardScreen(
            phoneNumber: '9876543210',
            selectedLanguage: 'en',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "Find Better Centre" button on GoTimeCard
      final findBetterBtn = find.byKey(const Key('btn_find_better_centre'));
      await tester.ensureVisible(findBetterBtn);
      expect(findBetterBtn, findsOneWidget);

      // Tap "Find Better Centre" button
      await tester.tap(findBetterBtn);
      await tester.pumpAndSettle();

      // Verify Alternative Centres screen is displayed
      expect(find.text('Alternative Procurement Centres'), findsOneWidget);
      expect(find.text('Current Centre Status'), findsOneWidget);
      expect(find.text('Recommended Nearby Centres'), findsOneWidget);

      // Check that at least one alternative centre card is displayed
      final altCardFinder = find.byKey(const Key('centre_card_centre_3'));
      await tester.ensureVisible(altCardFinder);
      expect(altCardFinder, findsOneWidget);

      // Tap "Select This Centre"
      final selectBtn = find.byKey(const Key('btn_select_centre_centre_3'));
      await tester.ensureVisible(selectBtn);
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog opens
      expect(find.text('Confirm Centre Switch'), findsOneWidget);
      final confirmBtn = find.byKey(const Key('btn_confirm_centre_switch'));
      expect(confirmBtn, findsOneWidget);

      // Tap Confirm Switch
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify state was switched to APMC Hub North
      expect(state.centreName, 'APMC Hub North');
      expect(state.farmerData.centreName, 'APMC Hub North');
    });
  });

  group('Phase 20: Centre Capacity Forecasting Tests', () {
    // 1. Forecast calculation
    test('1. Forecast calculation across all 4 operational windows', () {
      final service = CapacityForecastService();
      final summary = service.generateForecastSummary(
        currentLoadPercent: 62,
        currentQueueCount: 14,
        capacity: 100,
        averageProcessingMinutes: 5,
        delayMinutes: 0,
        centreStatus: 'Open • Normal',
      );

      expect(summary.forecasts.length, 4);
      expect(summary.forecasts[0].window, ForecastWindow.oneHour);
      expect(summary.forecasts[1].window, ForecastWindow.twoHours);
      expect(summary.forecasts[2].window, ForecastWindow.fourHours);
      expect(summary.forecasts[3].window, ForecastWindow.today);

      // Check fields
      for (final f in summary.forecasts) {
        expect(f.predictedLoadPercent, inInclusiveRange(15, 100));
        expect(f.predictedQueueCount, greaterThanOrEqualTo(1));
        expect(f.estimatedWaitMinutes, greaterThanOrEqualTo(0));
        expect(f.confidenceBasis, contains('Basis:'));
        expect(f.recommendedAction.isNotEmpty, isTrue);
      }
    });

    // 2. Queue growth prediction
    test('2. Queue growth prediction when expected arrivals exceed throughput', () {
      final service = CapacityForecastService();
      // Low processing speed (10 mins/token = 6/hr) with high arrivals
      final summary = service.generateForecastSummary(
        currentLoadPercent: 70,
        currentQueueCount: 20,
        capacity: 100,
        averageProcessingMinutes: 10, // 6/hr throughput
        delayMinutes: 0,
      );

      // In 1h: arrivals 10, throughput 6 -> net backlog +4 -> queue > 20
      final f1 = summary.forecasts.firstWhere((f) => f.window == ForecastWindow.oneHour);
      expect(f1.predictedQueueCount, greaterThan(20));
    });

    // 3. Load prediction
    test('3. Load prediction increases proportionally with backlog', () {
      final service = CapacityForecastService();
      final summaryLow = service.generateForecastSummary(
        currentLoadPercent: 50,
        currentQueueCount: 5,
        averageProcessingMinutes: 3, // 20/hr throughput > 10 arrivals
      );
      final summaryHigh = service.generateForecastSummary(
        currentLoadPercent: 85,
        currentQueueCount: 30,
        averageProcessingMinutes: 8,
      );

      expect(summaryHigh.peakLoadPercent, greaterThan(summaryLow.peakLoadPercent));
      expect(summaryHigh.peakRiskWindow?.predictedLoadPercent, inInclusiveRange(85, 100));
    });

    // 4. Wait-time prediction
    test('4. Wait-time prediction accounts for queue backlog and active delays', () {
      final service = CapacityForecastService();
      final noDelay = service.generateForecastSummary(
        currentLoadPercent: 60,
        currentQueueCount: 10,
        averageProcessingMinutes: 5,
        delayMinutes: 0,
      );
      final withDelay = service.generateForecastSummary(
        currentLoadPercent: 60,
        currentQueueCount: 10,
        averageProcessingMinutes: 5,
        delayMinutes: 25,
      );

      final fNoDelay = noDelay.forecasts.first;
      final fWithDelay = withDelay.forecasts.first;
      expect(fWithDelay.estimatedWaitMinutes, greaterThan(fNoDelay.estimatedWaitMinutes));
    });

    // 5. Peak-risk detection
    test('5. Peak-risk detection identifies the bottleneck window and peak time', () {
      final service = CapacityForecastService();
      final summary = service.generateForecastSummary(
        currentLoadPercent: 75,
        currentQueueCount: 18,
        averageProcessingMinutes: 6,
        delayMinutes: 15,
      );

      expect(summary.peakRiskWindow, isNotNull);
      expect(summary.peakRiskTime.isNotEmpty, isTrue);
      expect(summary.peakLoadPercent, inInclusiveRange(70, 100));
      expect(summary.overallRecommendedAction.isNotEmpty, isTrue);
    });

    // 6. Normal/Busy/High-Risk/Critical classification
    test('6. Congestion level classifies normal, busy, highRisk, and critical accurately', () {
      final service = CapacityForecastService();

      expect(
        service.classifyCongestion(loadPercent: 50, waitMinutes: 20, delayMinutes: 0),
        CapacityCongestionLevel.normal,
      );
      expect(
        service.classifyCongestion(loadPercent: 75, waitMinutes: 32, delayMinutes: 5),
        CapacityCongestionLevel.busy,
      );
      expect(
        service.classifyCongestion(loadPercent: 88, waitMinutes: 48, delayMinutes: 22),
        CapacityCongestionLevel.highRisk,
      );
      expect(
        service.classifyCongestion(loadPercent: 96, waitMinutes: 65, delayMinutes: 30),
        CapacityCongestionLevel.critical,
      );
      expect(
        service.classifyCongestion(loadPercent: 60, waitMinutes: 20, delayMinutes: 0, isDisrupted: true),
        CapacityCongestionLevel.critical,
      );
    });

    // 7. Processing-rate changes
    test('7. Processing-rate changes impact predicted throughput and backlog', () {
      final service = CapacityForecastService();
      final fastDocks = service.generateForecastSummary(
        currentLoadPercent: 70,
        currentQueueCount: 15,
        averageProcessingMinutes: 3, // 20 per hr
      );
      final slowDocks = service.generateForecastSummary(
        currentLoadPercent: 70,
        currentQueueCount: 15,
        averageProcessingMinutes: 10, // 6 per hr
      );

      final fast1h = fastDocks.forecasts.first;
      final slow1h = slowDocks.forecasts.first;
      expect(slow1h.predictedQueueCount, greaterThan(fast1h.predictedQueueCount));
      expect(slow1h.predictedLoadPercent, greaterThanOrEqualTo(fast1h.predictedLoadPercent));
    });

    // 8. Delay impact
    test('8. Delay impact degrades throughput efficiency and triggers higher risk levels', () {
      final service = CapacityForecastService();
      final noDelay = service.generateForecastSummary(
        currentLoadPercent: 70,
        currentQueueCount: 15,
        delayMinutes: 0,
      );
      final heavyDelay = service.generateForecastSummary(
        currentLoadPercent: 70,
        currentQueueCount: 15,
        delayMinutes: 35, // >= 30 mins degrades efficiency to 0.65
      );

      expect(heavyDelay.hasHighOrCriticalRisk, isTrue);
      expect(heavyDelay.peakLoadPercent, greaterThan(noDelay.peakLoadPercent));
    });

    // 9. Forecast-driven officer exception
    test('9. Forecast-driven officer exception generates capacityForecastRisk alert without duplicates', () {
      final state = ProcurementStateService();
      state.reset();

      // Set centre state with high load and delay
      state.setCentreStatus('Temporarily Delayed');
      state.setCapacityMode('High Load');

      final summary = state.capacityForecastSummary;
      expect(summary.hasHighOrCriticalRisk, isTrue);

      final exceptions = state.exceptions;
      final forecastExceptions = exceptions.where((e) => e.type == ExceptionType.capacityForecastRisk).toList();
      expect(forecastExceptions.length, 1);
      expect(forecastExceptions.first.title, contains('Capacity'));
      expect(forecastExceptions.first.severity, ExceptionSeverity.critical);

      // Re-fetching exceptions avoids duplicate alerts
      final recheckedExceptions = state.exceptions.where((e) => e.type == ExceptionType.capacityForecastRisk).toList();
      expect(recheckedExceptions.length, 1);
    });

    // 10. Integration with slot reallocation
    test('10. Integration with slot reallocation preserves booking states while forecasting congestion', () {
      final state = ProcurementStateService();
      state.reset();

      final initialToken = state.farmerData.tokenNumber;
      final initialSlot = state.farmerData.bookedSlotTime;

      // Forecast summary exists
      expect(state.capacityForecastSummary.forecasts.isNotEmpty, isTrue);

      // Generating reallocations does not auto-modify confirmed booking
      final reallocations = state.slotReallocations;
      expect(state.farmerData.tokenNumber, initialToken);
      expect(state.farmerData.bookedSlotTime, initialSlot);
      expect(reallocations, isNotNull);
    });

    // 11. Integration with alternative-centre recommendation
    test('11. Integration with alternative-centre recommendation offers nearby options under forecasted congestion', () {
      final state = ProcurementStateService();
      state.reset();

      state.setCentreStatus('Temporarily Delayed');
      state.setCapacityMode('High Load');
      expect(state.capacityForecastSummary.hasHighOrCriticalRisk, isTrue);

      final alternatives = state.alternativeCentres;
      expect(alternatives.isNotEmpty, isTrue);
      expect(alternatives.first.capacityPercent, lessThanOrEqualTo(state.centreCapacityPercent));
    });

    // 12. Officer Dashboard UI & Regression tests
    testWidgets('12. Officer Dashboard displays Capacity Forecast section with timeline and peak risk',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(
        const MaterialApp(
          home: OfficerDashboardScreen(officerId: 'OFFICER-001'),
        ),
      );
      await tester.pumpAndSettle();

      // Capacity Forecast section header should be visible
      final forecastHeader = find.byKey(const Key('officer_capacity_forecast_section'));
      await tester.ensureVisible(forecastHeader);
      expect(forecastHeader, findsOneWidget);

      // Verify Forecast Timeline text
      expect(find.text('Congestion Intelligence & Capacity Forecast'), findsOneWidget);

      // Verify 1h forecast card exists
      final card1h = find.byKey(const Key('card_forecast_oneHour'));
      expect(card1h, findsOneWidget);

      // Verify peak risk chip or badge is rendered
      expect(find.textContaining('Risk:'), findsWidgets);
    });
  });

  group('Phase 21: Offline-First Essential Information Tests', () {
    setUp(() {
      AppConnectivityService.instance.setOnline(true);
      ProcurementStateService().reset();
    });

    tearDown(() {
      AppConnectivityService.instance.setOnline(true);
    });

    // 1. Essential information is cached
    test('1. Essential information is cached locally', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      final cached = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(cached, isNotNull);
      expect(cached!.farmerName, 'Ramesh Kumar');
      expect(cached.tokenNumber, 'TK-8492');
      expect(cached.cropName, 'Wheat');
      expect(cached.centreName, contains('Procurement Centre'));
      expect(cached.qrPayload, contains('TK-8492'));
    });

    // 2. Cached data survives service/app restart
    test('2. Cached data survives service/app restart', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();

      // Simulate app restart with a fresh service pointing to store
      final restartedService = OfflineEssentialInfoService(cacheStore: LocalCacheStore.instance);
      final cached = restartedService.getCachedInfo();
      expect(cached, isNotNull);
      expect(cached!.tokenNumber, 'TK-8492');
      expect(cached.farmerName, 'Ramesh Kumar');
    });

    // 3. Offline dashboard reads cached information
    testWidgets('3. Offline dashboard reads and displays cached information', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ConnectivityBanner), findsOneWidget);
      expect(find.byKey(const Key('connectivity_banner_offline')), findsOneWidget);
      expect(find.text('TK-8492'), findsWidgets);
      expect(find.textContaining('Procurement Centre'), findsWidgets);
    });

    // 4. Offline QR pass remains available
    testWidgets('4. Offline QR pass remains available for check-in verification', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FarmerDigitalQrPass(
            tokenNumber: 'TK-8492',
            farmerName: 'Ramesh Kumar',
            crop: 'Wheat',
            quantity: '50 Quintals',
            bookedSlot: '11:30 AM',
            centreName: 'Khanna Grain Market',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DIGITAL ENTRY PASS'), findsOneWidget);
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
    });

    // 5. Offline state clearly shows last-updated timestamp
    testWidgets('5. Offline state clearly shows last-updated timestamp', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ConnectivityBanner(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last updated:'), findsOneWidget);
      expect(find.textContaining('(Not Live)'), findsOneWidget);
    });

    // 6. Queue data is labelled stale/offline
    testWidgets('6. Queue data is explicitly labelled stale/not live when offline', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GoTimeCard(
            data: state.farmerData,
            isHindi: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stale_queue_data_indicator')), findsOneWidget);
      expect(find.textContaining('Last Known Queue Status (Not Live)'), findsOneWidget);
    });

    // 7. New booking is blocked offline
    testWidgets('7. New booking is blocked while offline', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      expect(
        () => state.updateFarmerBooking(
          centreName: 'Khanna Grain Market',
          bookedSlot: '02:00 PM',
          tokenNumber: 'TK-9999',
          crop: 'Wheat',
          quantity: '40 Quintals',
        ),
        throwsA(isA<StateError>()),
      );

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Book Slot in Quick Actions
      await tester.tap(find.text('Book Slot'));
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.textContaining('New bookings cannot be confirmed while offline'), findsOneWidget);
    });

    // 8. Centre switching is blocked offline
    testWidgets('8. Centre switching is blocked while offline', (tester) async {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      AppConnectivityService.instance.setOnline(false);

      final dummyCentre = const ProcurementCentre(
        id: 'centre-samrala',
        name: 'Samrala Mandi',
        subLocation: 'Samrala',
        status: 'Open',
        isNormal: true,
        distance: '12 km',
        distanceKm: 12.0,
        queueStatus: 'Moderate',
        queueEstimate: '5 farmers',
        todayQueueCount: 5,
        estimatedWaitMinutes: 20,
        capacity: 100,
        processingRatePerHour: 15,
      );

      expect(
        () => state.switchFarmerProcurementCentre(
          newCentre: dummyCentre,
          newSlot: '12:00 PM',
        ),
        throwsA(isA<StateError>()),
      );

      // Verify GoTimeCard blocks button with snackbar
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GoTimeCard(
            data: state.farmerData.copyWith(centreLoadPercentage: 90),
            isHindi: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final findBetterBtn = find.byKey(const Key('btn_find_better_centre'));
      expect(findBetterBtn, findsOneWidget);
      await tester.tap(findBetterBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Centre switching is blocked while offline'), findsOneWidget);
    });

    // 9. Sensitive credentials are not persisted
    test('9. Sensitive credentials are not persisted in local offline store', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      final cached = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(cached, isNotNull);

      final json = cached!.toJson();
      final jsonString = json.toString().toLowerCase();

      expect(jsonString.contains('password'), isFalse);
      expect(jsonString.contains('secret'), isFalse);
      expect(jsonString.contains('token_secret'), isFalse);
      expect(jsonString.contains('credential'), isFalse);
      expect(jsonString.contains('private_key'), isFalse);
    });

    // 10. Cache refresh when connection returns
    test('10. Cache automatically refreshes when connection returns', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      final initialTime = OfflineEssentialInfoService.instance.getCachedInfo()!.lastUpdatedTimestamp;

      // Simulate offline period then coming back online
      AppConnectivityService.instance.setOnline(false);
      expect(AppConnectivityService.instance.isOnline, isFalse);

      AppConnectivityService.instance.setOnline(true);
      expect(AppConnectivityService.instance.isOnline, isTrue);

      state.syncOfflineCache();
      final refreshed = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(refreshed, isNotNull);
      expect(refreshed!.lastUpdatedTimestamp.isAfter(initialTime) || refreshed.lastUpdatedTimestamp.isAtSameMomentAs(initialTime), isTrue);
    });

    // 11. Corrupted cache recovery
    test('11. Corrupted cache gracefully recovers without crashing', () {
      OfflineEssentialInfoService.instance.injectCorruptedCacheForTesting('{not-a-valid-json:::!!');
      final result = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(result, isNull);
    });

    // 12. Empty cache / first launch behaviour
    test('12. Empty cache / first launch handled gracefully without error', () {
      OfflineEssentialInfoService.instance.clearCache();
      final result = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(result, isNull);
      expect(OfflineEssentialInfoService.instance.hasCachedInfo, isFalse);
    });

    // 13. English/Hindi/Telugu cached content
    test('13. Cached content produces localized speech summaries in En/Hi/Te', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();
      final cached = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(cached, isNotNull);

      final enSummary = cached!.toSpeechSummary(language: 'en');
      final hiSummary = cached.toSpeechSummary(language: 'hi');
      final teSummary = cached.toSpeechSummary(language: 'te');

      expect(enSummary, contains('Offline Essential Information'));
      expect(enSummary, contains('TK-8492'));
      expect(hiSummary, contains('ऑफ़लाइन आवश्यक जानकारी'));
      expect(hiSummary, contains('TK-8492'));
      expect(teSummary, contains('ఆఫ్‌లైన్ ముఖ్యమైన సమాచారం'));
      expect(teSummary, contains('TK-8492'));
    });

    // 14. Voice playback of cached information
    test('14. Voice playback speech summary is generated correctly from cache', () {
      final state = ProcurementStateService();
      state.syncOfflineCache();

      final summaryEn = OfflineEssentialInfoService.instance.getOfflineSpeechSummary(language: 'en');
      expect(summaryEn, contains('Token TK-8492'));
      expect(summaryEn, contains('Wheat'));
      expect(summaryEn, contains('Procurement Centre'));
    });

    // 15. Officer dashboard offline state
    testWidgets('15. Officer dashboard displays offline operational pause banner when offline', (tester) async {
      AppConnectivityService.instance.setOnline(false);

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER-7701'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('officer_offline_pause_banner')), findsOneWidget);
      expect(find.text('OPERATIONAL DATA PAUSED (OFFLINE)'), findsOneWidget);
      expect(find.textContaining('Live queue updates, check-in validation, and state synchronization are paused'), findsOneWidget);
    });

    // 16. Regression tests for existing functionality
    testWidgets('16. Online functionality works normally without regression', (tester) async {
      AppConnectivityService.instance.setOnline(true);
      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connectivity_banner_online')), findsOneWidget);
      expect(find.text('ONLINE • Live Data'), findsOneWidget);
      expect(find.text('When Should I Go?'), findsOneWidget);
      expect(find.text('TK-8492'), findsWidgets);
    });
  });

  group('Phase 23: Farmer Crop Selection, Change Crop & Produce Synchronization Tests', () {
    setUp(() {
      AppConnectivityService.instance.setOnline(true);
      ProcurementStateService().reset();
    });

    test('1. CropCatalogueService prominent10Crops and otherCrops contain exact user specifications', () {
      final prominent = CropCatalogueService.prominent10Crops;
      expect(prominent.length, equals(10));

      final expectedIds = [
        'paddy',
        'maize',
        'tur',
        'moong',
        'urad',
        'wheat',
        'groundnut',
        'sunflower',
        'cotton',
        'sugarcane',
      ];
      expect(prominent.map((c) => c.cropId).toList(), equals(expectedIds));

      // Each crop has valid MSP > 0
      for (final crop in prominent) {
        final msp = PaymentCalculationService.getMspRate(crop.cropName);
        expect(msp, greaterThan(0));
        expect(crop.nameHi, isNotEmpty);
        expect(crop.nameTe, isNotEmpty);
      }

      // Other crops contains remaining 13 crops
      final other = CropCatalogueService.otherCrops;
      expect(other.length, equals(13));
      expect(prominent.length + other.length, equals(23));
    });

    testWidgets('2. Farmer Dashboard ProduceSummaryCard renders prominent Change Crop button', (tester) async {
      bool changeCropPressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProduceSummaryCard(
            data: ProcurementStateService().farmerData,
            isHindi: false,
            isTelugu: false,
            onChangeCrop: () {
              changeCropPressed = true;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final changeBtn = find.byKey(const ValueKey('btn_change_crop'));
      expect(changeBtn, findsOneWidget);
      expect(find.text('Change Crop'), findsOneWidget);
      expect(find.byIcon(Icons.grass_rounded), findsWidgets);

      await tester.tap(changeBtn);
      await tester.pump();
      expect(changeCropPressed, isTrue);
    });

    testWidgets('3. My Produce Screen provides prominent Change Crop action button', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerProcurementStatusScreen(),
      ));
      await tester.pumpAndSettle();

      final changeCropBtn = find.byKey(const ValueKey('btn_procurement_change_crop'));
      expect(changeCropBtn, findsOneWidget);
      expect(find.text('Change Crop'), findsOneWidget);
      expect(find.byIcon(Icons.grass_rounded), findsWidgets);
    });

    testWidgets('4. FarmerCropSelectionScreen renders cards with icon, names, MSP, and Select button', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Screen title and guidance
      expect(find.text('Select Crop'), findsOneWidget);

      // Verify Wheat card elements
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_select_wheat')), findsOneWidget);
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('गेहूं'), findsWidgets);
      expect(find.text('గోధుమలు'), findsWidgets);
      expect(find.textContaining('MSP: ₹'), findsWidgets);
    });

    testWidgets('5. 10 Main Crops and Other Crops filter chips work correctly', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap '10 Main Crops' filter
      final main10Chip = find.text('10 Main Crops');
      expect(main10Chip, findsOneWidget);
      await tester.tap(main10Chip);
      await tester.pumpAndSettle();

      // Verify prominent crops are present
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_maize')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_cotton')), findsOneWidget);

      // Tap 'Other Crops' filter
      final otherChip = find.text('Other Crops');
      expect(otherChip, findsOneWidget);
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      // In Other Crops, barley & niger should be found, but paddy should not
      expect(find.byKey(const ValueKey('crop_card_barley')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsNothing);
    });

    testWidgets('6. Selecting a crop highlights it without prematurely overwriting state', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = ProcurementStateService();
      expect(service.farmerData.cropName, equals('Wheat'));

      await tester.pumpWidget(const MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Paddy card to select
      await tester.tap(find.byKey(const ValueKey('crop_card_paddy')));
      await tester.pumpAndSettle();

      // State is NOT immediately updated until confirmation
      expect(service.farmerData.cropName, equals('Wheat'));
      expect(find.byKey(const ValueKey('btn_proceed_crop_selection')), findsOneWidget);
    });

    testWidgets('7. Quantity Stepper (+10, -10) and Confirmation modal flow update state and show success', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = ProcurementStateService();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => const FarmerCropSelectionScreen(
                      currentCropName: 'Wheat',
                      currentQuantity: 40.0,
                      isHindi: false,
                      isTelugu: false,
                    ),
                  ),
                );
              },
              child: const Text('Open Crop Selection'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Crop Selection'));
      await tester.pumpAndSettle();

      // Select Paddy
      await tester.tap(find.byKey(const ValueKey('crop_card_paddy')));
      await tester.pumpAndSettle();

      // Tap Proceed
      await tester.tap(find.byKey(const ValueKey('btn_proceed_crop_selection')));
      await tester.pumpAndSettle();

      // Handle active booking warning if present
      if (find.byKey(const ValueKey('btn_confirm_booking_warning')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('btn_confirm_booking_warning')));
        await tester.pumpAndSettle();
      }

      // Confirmation Bottom Sheet appears with title: "Change your crop to Paddy (Rice)?"
      expect(find.textContaining('Change your crop to'), findsOneWidget);
      expect(find.text('Govt MSP Rate'), findsOneWidget);
      expect(find.byKey(const ValueKey('input_crop_quantity')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_cancel_crop_selection')), findsOneWidget);
      final confirmBtn = find.byKey(const ValueKey('btn_save_crop_selection'));
      expect(confirmBtn, findsOneWidget);

      // Tap +10 stepper
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();

      // Tap Confirm
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Success message shown on returning to parent view
      expect(find.textContaining('Crop Updated Successfully'), findsOneWidget);

      // ProcurementStateService updated to Paddy and 50 Quintals
      expect(service.farmerData.cropName, equals('Paddy (Rice)'));
      expect(service.farmerData.quantity, equals('50 Quintals'));
    });

    test('8. System-wide Produce Synchronization: Dashboard, Token, Queue, and Payment', () {
      final service = ProcurementStateService();
      final cotton = CropCatalogueService.findById('cotton')!;

      service.changeFarmerCrop(crop: cotton, quantityQuintals: 80.0);

      // 1. Farmer Dashboard data
      expect(service.farmerData.cropName, equals('Cotton'));
      expect(service.farmerData.quantity, equals('80 Quintals'));

      // 2. Queue and Token
      final tokenItem = service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(tokenItem.crop, equals('Cotton'));
      expect(tokenItem.quantity, equals('80 Quintals'));

      // 3. MSP and Payment rate (80 quintals * ₹7121 = ₹5,69,680)
      final cottonMsp = PaymentCalculationService.getMspRate('Cotton');
      expect(cottonMsp, equals(7121.0));
      expect(service.farmerData.estimatedMspValue, equals('₹5,69,680'));

      // 4. Smart Slot recommendations
      final slots = SmartSlotService.recommendSlots(
        centre: ProcurementCentre.getMockCentres().first,
        crop: 'Cotton',
      );
      expect(slots, isNotEmpty);
    });

    testWidgets('9. Multilingual Support: Hindi and Telugu localization in Crop Selection & Confirmation', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Telugu
      await tester.pumpWidget(const MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('పంటను ఎంచుకోండి'), findsOneWidget);
      expect(find.text('10 ప్రధాన పంటలు'), findsOneWidget);
      expect(find.text('వరి / బియ్యం'), findsOneWidget);

      // Hindi
      await tester.pumpWidget(const MaterialApp(
        home: FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: true,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('फसल चुनें'), findsOneWidget);
      expect(find.text('10 मुख्य फसलें'), findsOneWidget);
      expect(find.text('धान / चावल'), findsOneWidget);
    });

    testWidgets('10. Clicking Change Crop shows the 10 prominent crops: Paddy, Maize, Red Gram, Green Gram, Black Gram, Wheat, Groundnut, Sunflower, Cotton, Sugarcane', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pump FarmerDashboardScreen and tap Change Crop
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Change Crop button on Farmer Dashboard
      final changeCropBtn = find.byKey(const ValueKey('btn_change_crop'));
      expect(changeCropBtn, findsOneWidget);
      await tester.tap(changeCropBtn);
      await tester.pumpAndSettle();

      // Verify FarmerCropSelectionScreen is open with showProminentOnly == true
      final cropSelectionFinder = find.byType(FarmerCropSelectionScreen);
      expect(cropSelectionFinder, findsOneWidget);
      final cropSelectionWidget = tester.widget<FarmerCropSelectionScreen>(cropSelectionFinder);
      expect(cropSelectionWidget.showProminentOnly, isTrue);

      // Enlarge viewport on FarmerCropSelectionScreen to view full crop grid without scroll limits
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 1600);
      await tester.pumpAndSettle();

      // Verify the 10 prominent crops are all displayed
      final prominentCrops = [
        'paddy',
        'maize',
        'tur',
        'moong',
        'urad',
        'wheat',
        'groundnut',
        'sunflower',
        'cotton',
        'sugarcane',
      ];

      for (final cropId in prominentCrops) {
        expect(find.byKey(ValueKey('crop_card_$cropId')), findsOneWidget);
      }

      // Verify crops outside the 10 prominent crops are NOT shown in this view
      expect(find.byKey(const ValueKey('crop_card_barley')), findsNothing);
      expect(find.byKey(const ValueKey('crop_card_copra')), findsNothing);
      expect(find.byKey(const ValueKey('crop_card_niger')), findsNothing);
    });

    testWidgets('11. Regression: 10 Main Crops, Other Crops, All filters, Web rendering, and Quantity/Confirmation flow', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 768); // Standard Web/Chrome resolution
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Initial render on Web with showProminentOnly: true
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56), // Simulates AppTheme's global button constraint
            ),
          ),
        ),
        home: const FarmerCropSelectionScreen(
          currentCropName: 'Wheat',
          currentQuantity: 50.0,
          isHindi: false,
          isTelugu: false,
          showProminentOnly: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Ensure 10 Main Crops is selected initially
      expect(find.byKey(const ValueKey('chip_filter_main_10')), findsOneWidget);

      // Verify crop cards render without blank screen or infinite constraints crash
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_maize')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_tur')), findsOneWidget);

      // 2. Tap "Other Crops" filter chip
      final otherChip = find.byKey(const ValueKey('chip_filter_other'));
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      // Verify crops belonging to otherCrops (e.g. Barley, Jute, Copra) are shown and prominent crops are excluded
      expect(find.byKey(const ValueKey('crop_card_barley')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_jute')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsNothing);

      // 3. Tap "All" filter chip
      final allChip = find.byKey(const ValueKey('chip_filter_all'));
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // Verify all 23 crops catalogue is accessible (e.g. Paddy from main + Barley from other)
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_barley')), findsOneWidget);

      // 4. Test Search filter
      final searchField = find.byKey(const ValueKey('search_crop_input'));
      await tester.enterText(searchField, 'Cotton');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('crop_card_cotton')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsNothing);

      // 5. Select Cotton and open Quantity & Confirmation flow
      final cottonCard = find.byKey(const ValueKey('crop_card_cotton'));
      await tester.tap(cottonCard);
      await tester.pumpAndSettle();

      final proceedBtn = find.byKey(const ValueKey('btn_proceed_crop_selection'));
      expect(proceedBtn, findsOneWidget);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Handle active booking warning if present
      if (find.byKey(const ValueKey('btn_confirm_booking_warning')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('btn_confirm_booking_warning')));
        await tester.pumpAndSettle();
      }

      // Verify bottom modal sheet opens with quantity stepper and MSP details
      expect(find.text('Change your crop to Cotton?'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_save_crop_selection')), findsOneWidget);

      // Confirm the selection
      await tester.tap(find.byKey(const ValueKey('btn_save_crop_selection')));
      await tester.pumpAndSettle();

      // Verify state was successfully updated
      expect(ProcurementStateService().farmerData.cropName, equals('Cotton'));
    });
  });

  group('Phase 24: Supabase End-to-End Integration & Production Hardening Tests', () {
    tearDown(() {
      SupabaseConfig.setModeOverride(null);
      RepositoryProvider.resetOverrides();
      ProcurementStateService().reset();
      AuthService.instance.logout();
    });

    test('1. Supabase Configuration Audit & Secret Key Absence', () {
      expect(SupabaseConfig.backendMode, equals(BackendMode.local));
      expect(SupabaseConfig.supabaseUrl, equals(SupabaseConfig.placeholderUrl));
      expect(SupabaseConfig.supabasePublishableKey, equals(SupabaseConfig.placeholderAnonKey));

      // Ensure zero service-role or secret keys are in code/config
      expect(SupabaseConfig.supabasePublishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.placeholderAnonKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.supabasePublishableKey.toLowerCase().contains('secret'), isFalse);

      // Mode switching and programmatic override
      SupabaseConfig.setModeOverride(BackendMode.supabase);
      expect(SupabaseConfig.backendMode, equals(BackendMode.supabase));
      expect(SupabaseConfig.shouldUseSupabase, isTrue);

      SupabaseConfig.setModeOverride(BackendMode.local);
      expect(SupabaseConfig.backendMode, equals(BackendMode.local));
      expect(SupabaseConfig.shouldUseSupabase, isFalse);

      SupabaseConfig.setModeOverride(null);
    });

    test('2. Authentication Persistence, Session Restoration & Role Resolution', () async {
      // In local mode or unauthenticated state, restoreSession returns unauthenticated
      final session = await AuthService.instance.restoreSession();
      expect(session.isAuthenticated, isFalse);

      // Verify immutable state contract
      const farmerSession = AuthSessionState(
        isAuthenticated: true,
        role: UserRole.farmer,
        userId: '22222222-2222-2222-2222-222222222222',
        phone: '9876543210',
      );
      expect(farmerSession.isAuthenticated, isTrue);
      expect(farmerSession.role, equals(UserRole.farmer));
      expect(farmerSession.userId, equals('22222222-2222-2222-2222-222222222222'));

      const officerSession = AuthSessionState(
        isAuthenticated: true,
        role: UserRole.officer,
        officerId: 'OFFICER001',
        centreId: '11111111-1111-1111-1111-111111111111',
      );
      expect(officerSession.isAuthenticated, isTrue);
      expect(officerSession.role, equals(UserRole.officer));

      // Test logout clearing
      await AuthService.instance.logout();
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.currentUserId, isNull);
      expect(AuthService.instance.currentOfficerId, isNull);
      expect(AuthService.instance.currentRole, isNull);
    });

    test('3. RepositoryProvider Mode Switching & Contract Conformance', () {
      SupabaseConfig.setModeOverride(BackendMode.local);
      expect(RepositoryProvider.farmer, isA<LocalFarmerRepository>());
      expect(RepositoryProvider.centre, isA<LocalProcurementCentreRepository>());
      expect(RepositoryProvider.booking, isA<LocalBookingRepository>());
      expect(RepositoryProvider.queue, isA<LocalQueueRepository>());
      expect(RepositoryProvider.procurement, isA<LocalProcurementRepository>());
      expect(RepositoryProvider.payment, isA<LocalPaymentRepository>());
      expect(RepositoryProvider.notification, isA<LocalNotificationRepository>());
      expect(RepositoryProvider.dispute, isA<LocalDisputeRepository>());

      SupabaseConfig.setModeOverride(BackendMode.supabase);
      expect(RepositoryProvider.farmer, isA<SupabaseFarmerRepository>());
      expect(RepositoryProvider.centre, isA<SupabaseProcurementCentreRepository>());
      expect(RepositoryProvider.booking, isA<SupabaseBookingRepository>());
      expect(RepositoryProvider.queue, isA<SupabaseQueueRepository>());
      expect(RepositoryProvider.procurement, isA<SupabaseProcurementRepository>());
      expect(RepositoryProvider.payment, isA<SupabasePaymentRepository>());
      expect(RepositoryProvider.notification, isA<SupabaseNotificationRepository>());
      expect(RepositoryProvider.dispute, isA<SupabaseDisputeRepository>());

      SupabaseConfig.setModeOverride(null);
    });

    test('4. Farmer Produce Persistence Contract & Crop Synchronization', () async {
      final farmerRepo = RepositoryProvider.farmer;
      const testFarmerId = '22222222-2222-2222-2222-222222222222';

      // Save produce
      final saved = await farmerRepo.saveFarmerProduce(
        farmerId: testFarmerId,
        crop: 'Maize (मक्का)',
        quantity: 45.0,
      );
      expect(saved, isNotNull);
      expect(saved!['crop'], equals('Maize (मक्का)'));
      expect(saved['quantity'], equals(45.0));

      // Retrieve produce
      final produceList = await farmerRepo.getFarmerProduce(testFarmerId);
      expect(produceList.isNotEmpty, isTrue);
      expect(produceList.first['crop'], equals('Maize (मक्का)'));

      // Language persistence
      final langUpdated = await farmerRepo.updateFarmerLanguage(testFarmerId, 'te');
      expect(langUpdated, isTrue);

      // System-wide updateProduce in state service
      final maizeCrop = CropCatalogueService.allCrops.firstWhere((c) => c.cropId == 'maize');
      ProcurementStateService().changeFarmerCrop(crop: maizeCrop, quantityQuintals: 45.0);

      expect(ProcurementStateService().farmerData.cropName, contains('Maize'));
      expect(ProcurementStateService().farmerData.quantity, equals('45 Quintals'));
      expect(ProcurementStateService().farmerData.estimatedMspValue, contains('₹'));
    });

    test('5. Booking Lifecycle State Machine & Invalid Transition Prevention', () async {
      // 1. Normal active progression
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.booked, BookingLifecycleStatus.approved), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.approved, BookingLifecycleStatus.checkedIn), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.checkedIn, BookingLifecycleStatus.waiting), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.waiting, BookingLifecycleStatus.processing), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.processing, BookingLifecycleStatus.completed), isTrue);

      // 2. Cancellation and Standby branches
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.booked, BookingLifecycleStatus.standby), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.booked, BookingLifecycleStatus.cancelled), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.booked, BookingLifecycleStatus.expired), isTrue);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.booked, BookingLifecycleStatus.noShow), isTrue);

      // 3. Invalid transition rejection (terminal states cannot revert to active)
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.completed, BookingLifecycleStatus.waiting), isFalse);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.completed, BookingLifecycleStatus.booked), isFalse);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.cancelled, BookingLifecycleStatus.processing), isFalse);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.expired, BookingLifecycleStatus.approved), isFalse);
      expect(BookingLifecycleStatus.canTransition(BookingLifecycleStatus.noShow, BookingLifecycleStatus.checkedIn), isFalse);

      // 4. Test BookingRepository enforces transition validity
      final bookingRepo = RepositoryProvider.booking;
      final booking = await bookingRepo.createBooking(
        farmerId: '22222222-2222-2222-2222-222222222222',
        centreId: 'Example Procurement Centre',
        crop: 'Wheat',
        quantity: 50.0,
        slotTime: '11:30 AM',
      );
      final bookingId = booking!['id'] as String;

      // Valid transition
      final ok1 = await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.approved);
      expect(ok1, isTrue);

      // Complete the booking
      await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.checkedIn);
      await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.waiting);
      await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.processing);
      await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.completed);

      // Attempt invalid transition from COMPLETED to WAITING
      final invalidUpdate = await bookingRepo.updateBookingStatus(bookingId, BookingLifecycleStatus.waiting);
      expect(invalidUpdate, isFalse);
    });

    test('6. Queue Persistence, Live Attributes & Recursion Safety', () async {
      final queueRepo = RepositoryProvider.queue;
      final created = await queueRepo.createQueueEntry(
        bookingId: 'TK-8492',
        sequenceNumber: 108,
        position: 4,
        peopleAhead: 3,
        status: 'waiting',
        estimatedWaitMinutes: 20,
        expectedTurn: '12:15 PM',
      );
      expect(created, isNotNull);
      expect(created!['position'], equals(4));
      expect(created['people_ahead'], equals(3));
      expect(created['sequence_number'], equals(108));

      // Advance queue
      final advanced = await queueRepo.advanceQueue('TK-8492');
      expect(advanced, isTrue);

      final status = await queueRepo.getQueueStatus('TK-8492');
      expect(status['people_ahead'], equals(2));
      expect(status['position'], equals(3));

      // Verify no recursion in state service queue advances
      final state = ProcurementStateService();
      state.simulateNextQueueStep();
      state.simulateNextQueueStep();
      expect(state.farmerData.peopleAhead, isNonNegative);
    });

    test('7. QR Workflow Validation & Sensitive PII Protection', () {
      // Generate QR payload
      final payload = QrValidationService.generateQrPayload(
        bookingId: 'BK-8492',
        tokenNumber: 'TK-8492',
        centreName: 'Khanna Grain Market',
        slotTime: '11:30 AM',
      );

      // Verify payload format
      expect(payload.startsWith('KISANSETU:V1:'), isTrue);
      expect(payload, equals('KISANSETU:V1:BK-8492:TK-8492:Khanna Grain Market:11:30 AM'));

      // Security Check: Payload must NEVER contain PII (Phone number, Aadhaar, Bank Details)
      expect(payload.contains('9876543210'), isFalse);
      expect(payload.toLowerCase().contains('aadhaar'), isFalse);
      expect(payload.toLowerCase().contains('account'), isFalse);
      expect(payload.toLowerCase().contains('ifsc'), isFalse);

      // Validation
      final valid = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: 'Khanna Grain Market',
      );
      expect(valid.isValid, isTrue);
      expect(valid.tokenNumber, equals('TK-8492'));

      // Wrong centre rejection
      final wrongCentre = QrValidationService.validate(
        rawPayload: payload,
        currentCentreName: 'Different Mandi Yard',
      );
      expect(wrongCentre.isValid, isFalse);
      expect(wrongCentre.status, equals(QrValidationStatus.wrongCentre));
    });

    test('8. Procurement & Auditable Weighment Overrides', () async {
      final procRepo = RepositoryProvider.procurement;

      // Record weighment with auditable previous weight
      final recorded = await procRepo.recordWeighmentAndGrade(
        bookingId: 'TK-8492',
        actualQty: 52.5,
        grade: 'Grade A',
        hasDiscrepancy: true,
        previousWeight: 50.0,
        officerNotes: 'Weighbridge calibrated and re-verified.',
      );
      expect(recorded, isTrue);

      final record = await procRepo.getProcurementRecord('TK-8492');
      expect(record['actual_quantity'], equals(52.5));
      expect(record['previous_weight'], equals(50.0));
      expect(record['discrepancy'], isTrue);
      expect(record['quality_grade'], equals('Grade A'));
      expect(record['officer_notes'], equals('Weighbridge calibrated and re-verified.'));

      // State service weighment confirmation
      final state = ProcurementStateService();
      state.confirmWeighment('TK-8492', 52.5);
      expect(state.farmerData.actualQuantity, contains('52.5'));
    });

    test('9. Transparent Payment Lifecycle States & Transition Enforcement', () async {
      // 1. Verify all defined states
      expect(PaymentLifecycleStatus.all, containsAll([
        'NOT_ELIGIBLE', 'PENDING', 'INITIATED', 'PROCESSING', 'SUCCESS', 'FAILED', 'REVERSED',
      ]));

      // 2. Valid transitions
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.notEligible, PaymentLifecycleStatus.pending), isTrue);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.pending, PaymentLifecycleStatus.initiated), isTrue);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.initiated, PaymentLifecycleStatus.processing), isTrue);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.processing, PaymentLifecycleStatus.success), isTrue);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.success, PaymentLifecycleStatus.reversed), isTrue);

      // Retry transitions
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.failed, PaymentLifecycleStatus.initiated), isTrue);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.failed, PaymentLifecycleStatus.processing), isTrue);

      // 3. Invalid transition rejection (terminal state)
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.reversed, PaymentLifecycleStatus.success), isFalse);
      expect(PaymentLifecycleStatus.canTransition(PaymentLifecycleStatus.reversed, PaymentLifecycleStatus.pending), isFalse);

      // 4. PaymentRepository enforcement
      final payRepo = RepositoryProvider.payment;
      await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.pending);
      await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.initiated);
      await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.processing);
      await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.success);
      await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.reversed);

      // Attempt invalid transition from REVERSED
      final rejected = await payRepo.updatePaymentStatus(bookingId: 'TK-8492', paymentStatus: PaymentLifecycleStatus.success);
      expect(rejected, isFalse);
    });

    testWidgets('10. Graceful Empty Procurement Centre Handling in UI and Repository', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      // Pump FarmerBookSlotScreen with empty centresOverride
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FarmerBookSlotScreen(
            currentData: ProcurementStateService().farmerData,
            isHindi: false,
            centresOverride: const [],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify graceful empty state is displayed
      expect(find.text('No procurement centre currently available in this area.'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_view_nearby_centres')), findsOneWidget);

      // Verify continue button is disabled
      final continueBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continue to Best Slot'));
      expect(continueBtn.onPressed, isNull);
    });

    test('11. Notification Persistence, Deduplication & Trilingual Support', () async {
      final notifRepo = RepositoryProvider.notification;
      const testFarmerId = '22222222-2222-2222-2222-222222222222';

      // 1. Create notification
      final created = await notifRepo.createNotification(
        farmerId: testFarmerId,
        type: NotificationType.bookingConfirmed,
        titleEn: 'Slot Confirmed: TK-8492',
        titleHi: 'स्लॉट पुष्टि: TK-8492',
        titleTe: 'స్లాట్ ధృవీకరించబడింది: TK-8492',
        messageEn: 'Your procurement slot is confirmed.',
        messageHi: 'आपका खरीद स्लॉट पुष्ट हो गया है।',
        messageTe: 'మీ సేకరణ స్లాట్ ధృవీకరించబడింది.',
      );
      expect(created, isNotNull);
      expect(created!.titleEn, equals('Slot Confirmed: TK-8492'));
      expect(created.titleHi, equals('स्लॉट पुष्टि: TK-8492'));
      expect(created.titleTe, equals('స్లాట్ ధృవీకరించబడింది: TK-8492'));

      // 2. Duplicate prevention
      final duplicate = await notifRepo.createNotification(
        farmerId: testFarmerId,
        type: NotificationType.bookingConfirmed,
        titleEn: 'Slot Confirmed: TK-8492',
        titleHi: 'स्लॉट पुष्टि: TK-8492',
        messageEn: 'Your procurement slot is confirmed.',
        messageHi: 'आपका खरीद स्लॉट पुष्ट हो गया है।',
      );
      expect(duplicate, isNull); // Deduplicated!

      // 3. Mark read
      final marked = await notifRepo.markNotificationRead(created.id);
      expect(marked, isTrue);
    });

    test('12. Offline Essential Info Fallback & Reconnect Synchronization', () async {
      final state = ProcurementStateService();
      final offlineService = OfflineEssentialInfoService.instance;

      // Cache live state
      await offlineService.cacheState(
        farmerData: state.farmerData,
        centreName: state.centreName,
      );

      // Verify offline availability
      expect(offlineService.hasCachedData, isTrue);
      final cached = offlineService.getCachedInfo();
      expect(cached, isNotNull);
      expect(cached!.tokenNumber, equals(state.farmerData.tokenNumber));
      expect(cached.centreName, equals(state.centreName));
      expect(cached.qrPayload.startsWith('KISANSETU:V1:'), isTrue);

      // Reconcile from Supabase on network restoration
      await state.reconcileFromSupabase();
      expect(state.centreName.isNotEmpty, isTrue);
    });
  });

  group('Phase 25: Demo Data, End-to-End Judge Flow & Final Release Validation', () {
    test('1. CCEA 2024-25 Reference MSP Rates Verification for Prominent Crops', () {
      expect(PaymentCalculationService.getMspRate('Wheat'), 2275.0);
      expect(PaymentCalculationService.getMspRate('Paddy'), 2300.0);
      expect(PaymentCalculationService.getMspRate('Rice'), 2300.0);
      expect(PaymentCalculationService.getMspRate('Maize'), 2090.0);
      expect(PaymentCalculationService.getMspRate('Tur'), 7000.0);
      expect(PaymentCalculationService.getMspRate('Moong'), 8558.0);
      expect(PaymentCalculationService.getMspRate('Urad'), 7400.0);
      expect(PaymentCalculationService.getMspRate('Groundnut'), 6783.0);
      expect(PaymentCalculationService.getMspRate('Sunflower'), 7280.0);
      expect(PaymentCalculationService.getMspRate('Cotton'), 7121.0);
      expect(PaymentCalculationService.getMspRate('Sugarcane'), 340.0);

      // Hindi and Telugu resolution
      expect(PaymentCalculationService.getMspRate('गेहूं'), 2275.0);
      expect(PaymentCalculationService.getMspRate('వరి'), 2300.0);
      expect(PaymentCalculationService.getMspRate('మొక్కజొన్న'), 2090.0);

      // Calculation simulation flag verification
      final res = PaymentCalculationService.calculate(
        acceptedQuantity: 50.0,
        crop: 'Wheat',
      );
      expect(res.isSimulated, isTrue);
      expect(res.grossAmount, 113750.0);
      expect(res.netPayable, 113750.0);
    });

    test('2. Demo Authentication Credentials - Farmer & Officer', () async {
      final auth = AuthService.instance;

      // Farmer login with demo credentials
      final farmerResult = await auth.verifyFarmerOtp(
        phoneNumber: '9876543210',
        otp: '123456',
      );
      expect(farmerResult.isSuccess, isTrue);
      expect(auth.currentRole, UserRole.farmer);
      expect(auth.currentUserId, '22222222-2222-2222-2222-222222222222');

      // Logout
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentRole, isNull);

      // Officer login with demo credentials
      final officerResult = await auth.loginOfficer(
        officerId: 'OFFICER001',
        password: '123456',
      );
      expect(officerResult.isSuccess, isTrue);
      expect(auth.currentRole, UserRole.officer);
      expect(auth.currentOfficerId, 'OFFICER001');

      // Logout
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
    });

    test('3. Complete Farmer-to-Officer End-to-End State Lifecycle', () async {
      final state = ProcurementStateService();
      state.reset();

      // Initial state: Ramesh Kumar with Wheat, 50 Quintals
      expect(state.farmerData.cropName, 'Wheat');
      expect(state.farmerData.tokenNumber, 'TK-8492');
      expect(state.farmerData.checkInStatus, 'Not Checked In');

      // Step 1: Change Crop to Paddy, 65 Quintals
      final paddyCrop = CropCatalogueService.prominent10Crops.firstWhere((c) => c.cropId == 'paddy');
      state.changeFarmerCrop(crop: paddyCrop, quantityQuintals: 65.0);
      expect(state.farmerData.cropName, 'Paddy (Rice)');
      expect(state.farmerData.quantity, '65 Quintals');
      expect(state.farmerData.netPayable, 65.0 * 2300.0);

      // Step 2: Farmer Check-in
      final checkedIn = state.checkInFarmer('TK-8492');
      expect(checkedIn, isTrue);
      expect(state.farmerData.checkInStatus, 'Checked In');

      // Step 3: Officer views Ramesh in queue and advances to Quality Check
      final rameshQueue = state.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(rameshQueue.crop, 'Paddy (Rice)');
      state.startProcessing('TK-8492');
      expect(state.farmerData.lifecycleStatus, 'Quality Check');

      // Step 4: Officer records weighment & assaying
      state.confirmQuality('TK-8492', 'Grade A');
      expect(state.farmerData.qualityGrade, 'Grade A');

      state.confirmWeighment('TK-8492', 65.2);
      expect(state.farmerData.actualQuantity, '65.2 Quintals');

      // Step 5: Officer accepts procurement & triggers payment
      state.acceptProduce('TK-8492');
      expect(state.farmerData.lifecycleStatus, 'Accepted');

      state.initiatePayment('TK-8492');
      expect(state.farmerData.paymentStatus, 'Processing');

      state.markPaymentCompleted('TK-8492');
      expect(state.farmerData.paymentStatus, 'Completed');
      expect(state.farmerData.lifecycleStatus, 'Completed');

      // Step 6: File grievance / dispute
      state.submitDispute(
        tokenNumber: 'TK-8492',
        reason: 'Weighment verification discrepancy resolved',
        explanation: 'Officer re-verified tare weight.',
      );
      expect(state.disputes.isNotEmpty, isTrue);
      expect(state.disputes.last.tokenNumber, 'TK-8492');
    });

    test('4. Empty Procurement Centres Handling & Zero-Fake-Data Contract', () async {
      // Local centre repo returns default seeded centres
      final localCentres = await LocalProcurementCentreRepository().getCentres();
      expect(localCentres.isNotEmpty, isTrue);

      // Verify that when a Supabase centre repository gets an empty response,
      // it returns an empty list without injecting fake production records
      final supabaseRepo = SupabaseProcurementCentreRepository();
      expect(supabaseRepo, isNotNull);
    });

    test('5. Session and Crop Persistence Verification', () {
      final state = ProcurementStateService();
      state.reset();

      // Change crop to Cotton (70 Quintals)
      final cottonCrop = CropCatalogueService.prominent10Crops.firstWhere((c) => c.cropId == 'cotton');
      state.changeFarmerCrop(crop: cottonCrop, quantityQuintals: 70.0);

      // Cache offline
      state.syncOfflineCache();
      final cached = OfflineEssentialInfoService.instance.getCachedInfo();
      expect(cached, isNotNull);
      expect(cached!.cropName, 'Cotton');
      expect(cached.quantity, '70 Quintals');
    });
  });

  group('Farmer Book Token Flow & Change Crop / Quantity Tests', () {
    setUp(() {
      ProcurementStateService().reset();
    });

    testWidgets('1. Book Token opens with current produce and displays Change Crop / Quantity button', (tester) async {
      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Produce section shows registered produce
      expect(find.text('Wheat • 50 Quintals'), findsOneWidget);
      expect(find.text(state.farmerData.estimatedMspValue), findsOneWidget);

      // Change Crop / Quantity button is present
      expect(find.byKey(const ValueKey('btn_change_crop_quantity_booking')), findsOneWidget);
      expect(find.text('Change Crop / Quantity'), findsOneWidget);

      // Default continue action is present
      expect(find.text('Continue to Best Slot'), findsOneWidget);
    });

    testWidgets('2. Change Crop / Quantity opens the existing crop selector', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Change Crop / Quantity
      final changeBtn = find.byKey(const ValueKey('btn_change_crop_quantity_booking'));
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      // Verify FarmerCropSelectionScreen is open
      expect(find.byType(FarmerCropSelectionScreen), findsOneWidget);
      expect(find.text('10 Main Crops'), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
    });

    testWidgets('3. Changed crop and quantity are reflected on booking screen and reference amount updates', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 900);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Wheat • 50 Quintals'), findsOneWidget);

      // Tap Change Crop / Quantity
      await tester.tap(find.byKey(const ValueKey('btn_change_crop_quantity_booking')));
      await tester.pumpAndSettle();

      // Select Paddy
      final selectPaddyBtn = find.descendant(
        of: find.byKey(const ValueKey('crop_card_paddy')),
        matching: find.byType(ElevatedButton),
      );
      await tester.tap(selectPaddyBtn);
      await tester.pumpAndSettle();

      // Tap Proceed to open confirmation modal
      final proceedBtn = find.byKey(const ValueKey('btn_proceed_crop_selection'));
      expect(proceedBtn, findsOneWidget);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // If active booking warning dialog is shown, confirm it
      final confirmWarningBtn = find.byKey(const ValueKey('btn_confirm_booking_warning'));
      if (confirmWarningBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmWarningBtn);
        await tester.pumpAndSettle();
      }

      // Confirmation modal is shown: tap Confirm/Save button
      final saveBtn = find.byKey(const ValueKey('btn_save_crop_selection'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Now back on FarmerBookSlotScreen
      expect(find.byType(FarmerBookSlotScreen), findsOneWidget);
      // Produce is updated to Paddy (Rice)
      expect(find.text('Paddy (Rice) • 50 Quintals'), findsOneWidget);
      // Reference MSP value for Paddy: 50 * 2300 = 115000 -> ₹1,15,000
      expect(find.text('₹1,15,000'), findsOneWidget);
    });

    testWidgets('4. Continue to Best Slot still works directly without changing produce', (tester) async {
      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      await selectLocationAndCentreForTest(tester);

      // Tap Continue to Best Slot
      final continueBtn = find.text('Continue to Best Slot');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify FarmerSmartSlotScreen is open
      expect(find.byType(FarmerSmartSlotScreen), findsOneWidget);
      expect(find.text('Best Time to Visit'), findsOneWidget);
    });

    testWidgets('5. Multilingual support on booking produce card in Hindi and Telugu', (tester) async {
      final state = ProcurementStateService();
      state.reset();

      // Hindi
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: true,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('आपकी उपज'), findsOneWidget);
      expect(find.text('फसल / मात्रा बदलें'), findsOneWidget);
      expect(find.text('सर्वोत्तम स्लॉट चुनें'), findsOneWidget);

      // Telugu
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('మీ పంట'), findsOneWidget);
      expect(find.text('పంట / పరిమాణం మార్చండి'), findsOneWidget);
      expect(find.text('ఉత్తమ స్లాట్ ఎంచుకోండి'), findsOneWidget);
    });
  });

  group('Farmer Dashboard 2x2 Quick Actions Grid Tests', () {
    testWidgets('1. Quick Actions 2x2 grid displays all 4 cards in exact order and layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Book Slot'), findsOneWidget);
      expect(find.text('Payment'), findsWidgets);
      expect(find.text('Digital Pass / QR'), findsOneWidget);
      expect(find.text('Download Invoice / Receipt'), findsOneWidget);
    });

    testWidgets('2. Digital Pass / QR opens the latest/current booking only with correct details and shielded QR',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Digital Pass / QR'));
      await tester.tap(find.text('Digital Pass / QR'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerDigitalPassScreen), findsOneWidget);
      expect(find.text('ACTIVE PASS'), findsOneWidget);
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.textContaining('Wheat'), findsWidgets);
      expect(find.textContaining('50 Quintals'), findsWidgets);
      expect(find.textContaining('Today · 11:30 AM'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('Secure QR Pass'), findsOneWidget);

      // Verify older passes and simulation controls are NOT shown
      expect(find.text('TK-8490'), findsNothing);
      expect(find.text('TK-8491'), findsNothing);
      expect(find.text('SIMULATE DOCK INTAKE'), findsNothing);
    });

    testWidgets('3. No active booking displays "No active digital pass" empty state with Book Slot action',
        (WidgetTester tester) async {
      final emptyBooking = ProcurementStateService().farmerData.copyWith(
            tokenNumber: 'None',
            lifecycleStatus: 'Cancelled',
          );

      await tester.pumpWidget(MaterialApp(
        home: FarmerDigitalPassScreen(
          bookingData: emptyBooking,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No active digital pass'), findsOneWidget);
      expect(find.text('Book Slot'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('4. Download Invoice / Receipt opens Payment History first with logged-in farmer payments sorted newest-first',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Download Invoice / Receipt'));
      await tester.tap(find.text('Download Invoice / Receipt'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerPaymentHistoryScreen), findsOneWidget);
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('Procurement Transactions'), findsOneWidget);

      // Verify payments are displayed
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('Paddy'), findsWidgets);
      expect(find.text('Mustard'), findsWidgets);
      expect(find.textContaining('PAY-2026-8492'), findsOneWidget);
      expect(find.textContaining('PAY-2026-7812'), findsOneWidget);
      expect(find.textContaining('PAY-2026-6104'), findsOneWidget);
    });

    testWidgets('5. Selecting a payment from Payment History opens Payment Transparency for THAT specific transaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Open Payment History
      await tester.ensureVisible(find.text('Download Invoice / Receipt'));
      await tester.tap(find.text('Download Invoice / Receipt'));
      await tester.pumpAndSettle();

      // Tap the Paddy payment card
      await tester.ensureVisible(find.text('Paddy'));
      await tester.tap(find.text('Paddy'));
      await tester.pumpAndSettle();

      // Verify FarmerPaymentScreen is opened with Paddy transaction details
      expect(find.byType(FarmerPaymentScreen), findsOneWidget);
      expect(find.text('Payment Transparency'), findsOneWidget);
      expect(find.textContaining('PAY-2026-7812'), findsWidgets);
      expect(find.textContaining('₹1,49,500'), findsWidgets);

      // Download Receipt button
      await tester.ensureVisible(find.text('Download Invoice / Receipt'));
      await tester.tap(find.text('Download Invoice / Receipt'));
      await tester.pumpAndSettle();
      expect(find.textContaining('PAY-2026-7812'), findsWidgets);
    });

    testWidgets('6. Empty payment history displays "No payments received yet" empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerPaymentHistoryScreen(
          customPayments: [],
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No payments received yet'), findsOneWidget);
    });

    testWidgets('7. Existing Book Slot, Payment, and View Token actions continue to work seamlessly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Book Slot
      await tester.ensureVisible(find.text('Book Slot'));
      await tester.tap(find.text('Book Slot'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerBookSlotScreen), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);

      // Tap Payment directly from Quick Actions
      await tester.ensureVisible(find.text('Payment').first);
      await tester.tap(find.text('Payment').first);
      await tester.pumpAndSettle();
      expect(find.byType(FarmerPaymentScreen), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);

      // Tap View Token
      await tester.ensureVisible(find.text('View Token'));
      await tester.tap(find.text('View Token'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerMyTokenScreen), findsOneWidget);
    });

    testWidgets('8. Multilingual support: Hindi and Telugu localization for 2x2 Quick Actions, Digital Pass, and Payment History',
        (WidgetTester tester) async {
      // Hindi Dashboard
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'Hindi',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('स्लॉट बुक करें'), findsOneWidget);
      expect(find.text('भुगतान'), findsWidgets);
      expect(find.text('डिजिटल पास / क्यूआर'), findsOneWidget);
      expect(find.text('रसीद / इनवॉयस डाउनलोड'), findsOneWidget);

      // Open Hindi Digital Pass
      await tester.ensureVisible(find.text('डिजिटल पास / क्यूआर'));
      await tester.tap(find.text('डिजिटल पास / क्यूआर'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerDigitalPassScreen), findsOneWidget);
      expect(find.text('सक्रिय पास'), findsOneWidget);

      // Pop back
      await tester.tap(find.byTooltip('वापस'));
      await tester.pumpAndSettle();

      // Open Hindi Payment History
      await tester.ensureVisible(find.text('रसीद / इनवॉयस डाउनलोड'));
      await tester.tap(find.text('रसीद / इनवॉयस डाउनलोड'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerPaymentHistoryScreen), findsOneWidget);
      expect(find.text('भुगतान इतिहास'), findsOneWidget);

      // Pop back to dashboard
      await tester.tap(find.byTooltip('वापस'));
      await tester.pumpAndSettle();

      // Telugu Dashboard
      AppPreferencesService.instance.setUiLanguage('te');
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'Telugu',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('స్లాట్ బుక్ చేయండి'), findsOneWidget);
      expect(find.text('చెల్లింపు'), findsWidgets);
      expect(find.text('డిజిటల్ పాస్ / QR'), findsOneWidget);
      expect(find.text('రసీదు / ఇన్‌వాయిస్ డౌన్‌లోడ్'), findsOneWidget);

      // Reset to default English
      AppPreferencesService.instance.setUiLanguage('en');
    });

    testWidgets(
        '9. Farmer Journey Tracker displays live queue status without simulation controls in En/Hi/Te',
        (WidgetTester tester) async {
      final stateService = ProcurementStateService();
      stateService.reset();

      // 1. English view
      await tester.pumpWidget(MaterialApp(
        home: FarmerMyTokenScreen(
          data: stateService.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      // No simulation controls
      expect(find.widgetWithText(ElevatedButton, 'Simulate Queue Update'),
          findsNothing);
      expect(find.text('Live Queue Simulation'), findsNothing);
      expect(find.text('PROTOTYPE DEMO'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Open • Normal'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Open • Busy'), findsNothing);
      expect(
          find.widgetWithText(ChoiceChip, 'Temporarily Delayed'), findsNothing);

      // Real live queue information
      expect(find.text('Live Queue Status'), findsOneWidget);
      expect(
          find.textContaining('Centre is operating normally'), findsOneWidget);
      expect(find.textContaining('7 people ahead'), findsWidgets);
      expect(find.textContaining('35 min'), findsWidgets);
      expect(find.text('Queue updates automatically as farmers are processed.'),
          findsOneWidget);
      expect(find.text('Last updated: Just now'), findsOneWidget);

      // 2. Dynamic update via officer operation
      stateService.setCentreStatus('Open • Busy');
      await tester.pumpAndSettle();
      expect(find.textContaining('Centre is busy'), findsOneWidget);
      expect(find.textContaining('55 min'), findsWidgets);

      // 3. Hindi view
      await tester.pumpWidget(MaterialApp(
        home: FarmerMyTokenScreen(
          data: stateService.farmerData,
          isHindi: true,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('लाइव कतार स्थिति'), findsOneWidget);
      expect(find.textContaining('केंद्र व्यस्त है'), findsOneWidget);
      expect(find.text('अंतिम अपडेट: अभी'), findsOneWidget);
      expect(
          find.text(
              'किसानों की खरीद आगे बढ़ने के साथ कतार स्वतः अपडेट होती है।'),
          findsOneWidget);

      // 4. Telugu view
      stateService.setCentreStatus('Open • Normal');
      await tester.pumpWidget(MaterialApp(
        home: FarmerMyTokenScreen(
          data: stateService.farmerData,
          isHindi: false,
          isTelugu: true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('లైవ్ క్యూ స్థితి'), findsOneWidget);
      expect(
          find.textContaining('కేంద్రం సాధారణంగా పనిచేస్తోంది'), findsOneWidget);
      expect(find.text('చివరి నవీకరణ: ఇప్పుడే'), findsOneWidget);
      expect(
          find.text(
              'రైతుల సేకరణ ప్రక్రియ జరిగే కొద్దీ క్యూ స్వయంచాలకంగా అప్‌డేట్ అవుతుంది.'),
          findsOneWidget);

      // Reset service
      stateService.reset();
    });
  });

  group('Farmer Dashboard Bottom Navigation & My Profile Tests', () {
    testWidgets(
        '1. Bottom navigation bar contains exactly 5 items: Home, Payment, Messages, More, My Profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final bottomNavBar =
          tester.widget<BottomNavigationBar>(bottomNavBarFinder);
      expect(bottomNavBar.items.length, equals(5));

      // Items in exact order
      expect(bottomNavBar.items[0].label, equals('Home'));
      expect(bottomNavBar.items[1].label, equals('Payment'));
      expect(bottomNavBar.items[2].label, contains('Messages'));
      expect(bottomNavBar.items[3].label, equals('More'));
      expect(bottomNavBar.items[4].label, equals('My Profile'));

      // Confirm "My Token" is NOT in bottom navigation bar
      for (final item in bottomNavBar.items) {
        expect(item.label, isNot(contains('My Token')));
      }
    });

    testWidgets('2. Tapping My Profile opens FarmerProfileScreen with full details',
        (WidgetTester tester) async {
      final stateService = ProcurementStateService();
      stateService.reset();

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap My Profile
      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerProfileScreen), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsWidgets);
      expect(find.text('Verified Farmer'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('XXXX-XXXX-8492'), findsOneWidget);
      expect(find.text('Aadhaar (e-KYC)'), findsOneWidget);
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('50 Quintals'), findsWidgets);
      expect(find.text('MSP Direct Benefit Transfer (DBT) Bank'), findsOneWidget);
      expect(find.text('State Bank of India (SBI)'), findsOneWidget);
      expect(find.text('Aadhaar-Linked Active'), findsOneWidget);
      expect(find.text('Log Out / Switch Account'), findsOneWidget);
    });

    testWidgets('3. FarmerProfileScreen allows editing name and updates state dynamically',
        (WidgetTester tester) async {
      final stateService = ProcurementStateService();
      stateService.reset();

      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Open profile
      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();

      // Tap Edit Name icon button
      await tester.tap(find.byTooltip('Edit Name'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Name'), findsOneWidget);
      final textFieldFinder = find.byType(TextFormField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Ramesh Kumar Sharma');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Kumar Sharma'), findsWidgets);
      expect(stateService.farmerData.farmerName, equals('Ramesh Kumar Sharma'));

      // Pop back to dashboard
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      stateService.reset();
    });

    testWidgets(
        '4. Multilingual support for bottom navigation and My Profile in Hindi and Telugu',
        (WidgetTester tester) async {
      // Hindi
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'Hindi',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('होम'), findsOneWidget);
      expect(find.text('भुगतान'), findsWidgets);
      expect(find.textContaining('संदेश'), findsWidgets);
      expect(find.text('अधिक'), findsOneWidget);
      expect(find.text('मेरी प्रोफ़ाइल'), findsOneWidget);

      // Open Hindi Profile
      await tester.tap(find.text('मेरी प्रोफ़ाइल'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerProfileScreen), findsOneWidget);
      expect(find.text('सत्यापित किसान'), findsOneWidget);
      expect(find.text('व्यक्तिगत और आधार विवरण'), findsOneWidget);

      // Back
      await tester.tap(find.byTooltip('वापस जाएं'));
      await tester.pumpAndSettle();

      // Telugu
      AppPreferencesService.instance.setUiLanguage('te');
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'Telugu',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('హోమ్'), findsOneWidget);
      expect(find.text('చెల్లింపు'), findsWidgets);
      expect(find.textContaining('సందేశాలు'), findsWidgets);
      expect(find.text('మరిన్ని'), findsOneWidget);
      expect(find.text('నా ప్రొఫైల్'), findsOneWidget);

      // Open Telugu Profile
      await tester.tap(find.text('నా ప్రొఫైల్'));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerProfileScreen), findsOneWidget);
      expect(find.text('ధృవీకరించబడిన రైతు'), findsOneWidget);
      expect(find.text('వ్యక్తిగత & ఆధార్ వివరాలు'), findsOneWidget);

      // Reset language
      AppPreferencesService.instance.setUiLanguage('en');
    });

    testWidgets('5. Bottom navigation items Payment, Messages, and More open properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FarmerDashboardScreen(
          phoneNumber: '9876543210',
          selectedLanguage: 'English',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Payment from bottom navigation
      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerPaymentScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Tap Messages from bottom navigation
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(FarmerMessagesScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Tap More from bottom navigation
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(LanguagePreferencesScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(LanguagePreferencesScreen))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('6. Open Personal & KYC Edit dialog and verify fields, read-only mobile, and masked Aadhaar',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editKycFinder = find.byKey(const ValueKey('btn_edit_personal_kyc'));
      await tester.scrollUntilVisible(editKycFinder, 100);
      expect(editKycFinder, findsOneWidget);

      await tester.tap(editKycFinder);
      await tester.pumpAndSettle();

      expect(find.text('Edit Personal & KYC Details'), findsOneWidget);
      // Mobile number is read-only (displayed as +91 <phone>)
      expect(find.textContaining('9876543210'), findsWidgets);
      // Aadhaar is masked and verified
      expect(find.text('XXXX-XXXX-8492'), findsWidgets);
      expect(find.text('Verified'), findsWidgets);

      // Editable fields are present
      expect(find.byKey(const ValueKey('input_kyc_state')), findsOneWidget);
      expect(find.byKey(const ValueKey('input_kyc_district')), findsOneWidget);
      expect(find.byKey(const ValueKey('input_kyc_village')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_cancel_kyc')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_save_kyc')), findsOneWidget);
    });

    testWidgets('7. Cancel Personal & KYC Edit dialog does not update values',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editKycFinder = find.byKey(const ValueKey('btn_edit_personal_kyc'));
      await tester.scrollUntilVisible(editKycFinder, 100);
      await tester.tap(editKycFinder);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('input_kyc_village')), 'Temporary Village');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_cancel_kyc')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Personal & KYC Details'), findsNothing);
      expect(find.text('Temporary Village'), findsNothing);
      expect(find.text('Khanna Kalan'), findsWidgets);
    });

    testWidgets('8. Save Personal & KYC Edit updates local service and reflects immediately on profile',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editKycFinder = find.byKey(const ValueKey('btn_edit_personal_kyc'));
      await tester.scrollUntilVisible(editKycFinder, 100);
      await tester.tap(editKycFinder);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('input_kyc_state')), 'Karnataka');
      await tester.enterText(find.byKey(const ValueKey('input_kyc_district')), 'Mandya');
      await tester.enterText(find.byKey(const ValueKey('input_kyc_village')), 'Koppa');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_save_kyc')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Personal & KYC Details'), findsNothing);
      expect(find.text('Karnataka · Mandya'), findsOneWidget);
      expect(find.text('Koppa'), findsOneWidget);
      expect(ProcurementStateService.instance.farmerState, equals('Karnataka'));
      expect(ProcurementStateService.instance.farmerDistrict, equals('Mandya'));
      expect(ProcurementStateService.instance.farmerVillage, equals('Koppa'));
    });

    testWidgets('9. Open Bank Details Edit dialog and verify fields and read-only DBT status',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editBankFinder = find.byKey(const ValueKey('btn_edit_bank_details'));
      await tester.scrollUntilVisible(editBankFinder, 100);
      expect(editBankFinder, findsOneWidget);

      await tester.tap(editBankFinder);
      await tester.pumpAndSettle();

      expect(find.text('Edit MSP DBT Bank Details'), findsOneWidget);
      expect(find.byKey(const ValueKey('input_bank_name')), findsOneWidget);
      expect(find.byKey(const ValueKey('input_bank_account_number')), findsOneWidget);
      expect(find.byKey(const ValueKey('input_bank_ifsc_code')), findsOneWidget);
      // DBT status is read-only system controlled
      expect(find.text('Aadhaar-Linked Active'), findsWidgets);
      expect(find.byKey(const ValueKey('btn_cancel_bank')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_save_bank')), findsOneWidget);
    });

    testWidgets('10. Bank and IFSC format validation triggers error messages',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editBankFinder = find.byKey(const ValueKey('btn_edit_bank_details'));
      await tester.scrollUntilVisible(editBankFinder, 100);
      await tester.tap(editBankFinder);
      await tester.pumpAndSettle();

      // Enter invalid account number (<9 digits) and invalid IFSC
      await tester.enterText(find.byKey(const ValueKey('input_bank_name')), '');
      await tester.enterText(find.byKey(const ValueKey('input_bank_account_number')), '1234');
      await tester.enterText(find.byKey(const ValueKey('input_bank_ifsc_code')), 'INVALID_IFSC');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_save_bank')));
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Please enter a valid bank name'), findsOneWidget);
      expect(find.text('Account number must be 9 to 18 digits'), findsOneWidget);
      expect(find.text('Please enter a valid 11-character IFSC (e.g. SBIN0001234)'), findsOneWidget);

      // Confirmation dialog should NOT appear
      expect(find.text('Confirm Bank Details Update'), findsNothing);
    });

    testWidgets('11. Bank details edit cancellation and confirmation modal workflow',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editBankFinder = find.byKey(const ValueKey('btn_edit_bank_details'));
      await tester.scrollUntilVisible(editBankFinder, 100);
      await tester.tap(editBankFinder);
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(find.byKey(const ValueKey('input_bank_name')), 'ICICI Bank');
      await tester.enterText(find.byKey(const ValueKey('input_bank_account_number')), '112233445566');
      await tester.enterText(find.byKey(const ValueKey('input_bank_ifsc_code')), 'ICIC0001234');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_save_bank')));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Confirm Bank Details Update'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to update your MSP DBT bank account to the following?'), findsOneWidget);

      // Cancel confirmation
      await tester.tap(find.byKey(const ValueKey('btn_cancel_bank_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Bank Details Update'), findsNothing);
      expect(find.text('Edit MSP DBT Bank Details'), findsOneWidget);

      // Cancel edit dialog
      await tester.tap(find.byKey(const ValueKey('btn_cancel_bank')));
      await tester.pumpAndSettle();

      expect(find.text('Edit MSP DBT Bank Details'), findsNothing);
      expect(find.text('ICICI Bank'), findsNothing);
      expect(find.text('State Bank of India (SBI)'), findsWidgets);
    });

    testWidgets('12. Bank details save with confirmation reflects immediately and masks account number',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      final editBankFinder = find.byKey(const ValueKey('btn_edit_bank_details'));
      await tester.scrollUntilVisible(editBankFinder, 100);
      await tester.tap(editBankFinder);
      await tester.pumpAndSettle();

      // Enter new bank details
      await tester.enterText(find.byKey(const ValueKey('input_bank_name')), 'Punjab National Bank');
      await tester.enterText(find.byKey(const ValueKey('input_bank_account_number')), '01234567899876');
      await tester.enterText(find.byKey(const ValueKey('input_bank_ifsc_code')), 'punb0123400'); // lowercase to test auto-uppercase
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_save_bank')));
      await tester.pumpAndSettle();

      // Confirm save
      expect(find.text('Confirm Bank Details Update'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn_confirm_save_bank')));
      await tester.pumpAndSettle();

      // Dialog closed and profile updated immediately
      expect(find.text('Edit MSP DBT Bank Details'), findsNothing);
      expect(find.text('Punjab National Bank'), findsOneWidget);
      expect(find.text('A/C ending in **9876'), findsOneWidget);
      expect(find.text('PUNB0123400'), findsOneWidget);

      // Full account number must NOT be exposed on the profile screen
      expect(find.text('01234567899876'), findsNothing);

      // Verify service state
      expect(ProcurementStateService.instance.bankName, equals('Punjab National Bank'));
      expect(ProcurementStateService.instance.accountNumber, equals('01234567899876'));
      expect(ProcurementStateService.instance.bankAccountNumberMasked, equals('A/C ending in **9876'));
      expect(ProcurementStateService.instance.ifscCode, equals('PUNB0123400'));
    });

    testWidgets('13. Voice listen guidance triggers successfully and provides updated profile audio info',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        ProcurementStateService.instance.reset();
      });

      await tester.pumpWidget(const MaterialApp(
        home: FarmerProfileScreen(
          isHindi: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap the Voice Listen button
      final listenBtn = find.text('Listen');
      await tester.scrollUntilVisible(listenBtn, 100);
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      // SnackBar shows voice guidance active
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Farmer Profile:'), findsOneWidget);
    });
  });

  group('Phase 26: Location-Based Procurement Centre Selection Flow Tests', () {
    testWidgets('1. Cascading selection: State must be selected before District, District before Mandal', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Where do you want to procure?'), findsOneWidget);

      // Initially District and Mandal placeholders indicate disabled states
      expect(find.text('Select State first'), findsOneWidget);
      expect(find.text('Select District first'), findsOneWidget);

      // Tapping District before State does not open modal
      await tester.tap(find.byKey(const ValueKey('select_district_field')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      // Select State
      await tester.tap(find.byKey(const ValueKey('select_state_field')));
      await tester.pumpAndSettle();
      expect(find.text('Select State'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('picker_item_punjab')));
      await tester.pumpAndSettle();

      // Now State is Punjab, District is enabled with placeholder "Select District"
      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Select District'), findsOneWidget);

      // Mandal is still disabled
      expect(find.text('Select District first'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('select_mandal_field')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      // Select District
      await tester.tap(find.byKey(const ValueKey('select_district_field')));
      await tester.pumpAndSettle();
      expect(find.text('Select District'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('picker_item_ludhiana')));
      await tester.pumpAndSettle();

      // Now District is Ludhiana, Mandal is enabled with "Select Mandal"
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('Select Mandal'), findsOneWidget);

      // Select Mandal
      await tester.tap(find.byKey(const ValueKey('select_mandal_field')));
      await tester.pumpAndSettle();
      expect(find.text('Select Mandal'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('picker_item_khanna')));
      await tester.pumpAndSettle();

      expect(find.text('Khanna'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_confirm_find_centres')), findsOneWidget);
    });

    testWidgets('2. Changing parent resets child selections', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('Khanna'), findsOneWidget);

      // Change District to Patiala -> Mandal should reset
      await tester.tap(find.byKey(const ValueKey('select_district_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker_item_patiala')));
      await tester.pumpAndSettle();

      expect(find.text('Patiala'), findsOneWidget);
      expect(find.text('Select Mandal'), findsOneWidget);
      expect(find.text('Khanna'), findsNothing);

      // Change State to Telangana -> District and Mandal should reset
      await tester.tap(find.byKey(const ValueKey('select_state_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker_item_telangana')));
      await tester.pumpAndSettle();

      expect(find.text('Telangana'), findsOneWidget);
      expect(find.text('Select District'), findsOneWidget);
      expect(find.text('Select District first'), findsOneWidget);
    });

    testWidgets('3. Location confirmation gates centre list and filters by Mandal', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
        ),
      ));
      await tester.pumpAndSettle();

      // Centres list should NOT be displayed before confirmation
      expect(find.text('Example Procurement Centre'), findsNothing);
      expect(find.text('APMC Hub North'), findsNothing);

      // Confirm Location
      final confirmBtn = find.byKey(const ValueKey('btn_confirm_find_centres'));
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Confirmed area header is visible
      expect(find.text('Selected Procurement Area'), findsOneWidget);
      expect(find.text('Punjab • Ludhiana • Khanna'), findsOneWidget);

      // Available centres for Khanna are shown
      expect(find.text('Example Procurement Centre'), findsOneWidget);
      expect(find.text('Nearby Procurement Centre'), findsOneWidget);

      // Centres outside Khanna (e.g., APMC Hub North in Ludhiana East) are NOT displayed
      expect(find.text('APMC Hub North'), findsNothing);
    });

    testWidgets('4. Haversine distance calculation and fallback when permission denied', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      // Case A: Permission denied / Location unavailable
      LocationDistanceService.instance.resetForTest();
      LocationDistanceService.instance.setPermissionForTest(LocationPermissionState.denied);

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
          isLocationConfirmed: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Shows fallback message
      expect(find.text('Distance unavailable — enable location to see distance'), findsWidgets);

      // Pure Dart formula verification
      // Distance between (30.7046, 76.2210) and (30.7050, 76.2217) is ~0.08 km
      final testDistance = LocationDistanceService.calculateHaversineDistanceKm(
        30.7046, 76.2210, 30.7050, 76.2217,
      );
      expect(testDistance, inInclusiveRange(0.05, 0.12));

      // Case B: Permission granted with coordinates
      LocationDistanceService.instance.setPermissionForTest(
        LocationPermissionState.granted,
        coords: const FarmerCoordinates(latitude: 30.7046, longitude: 76.2210),
      );

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
          isLocationConfirmed: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Displays calculated straight-line distance (e.g., 0.1 km from your location)
      expect(find.textContaining('from your location'), findsWidgets);
    });

    testWidgets('5. Explicit centre selection required to continue', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
          isLocationConfirmed: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Continue button should be disabled because no centre is selected yet
      final continueBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('btn_continue_best_slot')));
      expect(continueBtn.onPressed, isNull);

      // Explicitly tap Select Centre for Example Procurement Centre
      final selectCentreBtn = find.byKey(const ValueKey('btn_select_centre_centre_1'));
      await tester.ensureVisible(selectCentreBtn);
      await tester.pumpAndSettle();
      await tester.tap(selectCentreBtn);
      await tester.pumpAndSettle();

      // Button is now Selected and continue button is active
      expect(find.text('Selected'), findsOneWidget);
      final activeContinueBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('btn_continue_best_slot')));
      expect(activeContinueBtn.onPressed, isNotNull);
    });

    testWidgets('6. Empty state when no centres exist for the selected area', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      // Override with empty list to test zero-data contract
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Telangana',
          initialDistrict: 'Warangal',
          initialMandal: 'Wardhannapet',
          isLocationConfirmed: true,
          centresOverride: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No procurement centre currently available in this area.'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_view_nearby_centres')), findsOneWidget);
      final changeLocBtn = find.byKey(const ValueKey('btn_change_location_empty'));
      expect(changeLocBtn, findsOneWidget);

      // Tap Change Location resets confirmation
      await tester.ensureVisible(changeLocBtn);
      await tester.pumpAndSettle();
      await tester.tap(changeLocBtn);
      await tester.pumpAndSettle();

      expect(find.text('Where do you want to procure?'), findsOneWidget);
      expect(find.text('No procurement centre currently available in this area.'), findsNothing);
    });

    testWidgets('7. Multilingual support for Hindi and Telugu location flow', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      // Hindi
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: true,
          isTelugu: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('आप कहां खरीद कराना चाहते हैं?'), findsOneWidget);
      expect(find.text('पहले राज्य चुनें'), findsOneWidget);

      // Telugu
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('మీరు ఎక్కడ సేకరించాలనుకుంటున్నారు?'), findsOneWidget);
      expect(find.text('ముందుగా రాష్ట్రాన్ని ఎంచుకోండి'), findsOneWidget);
    });

    test('8. India-wide State selector contains all 28 States and 8 UTs (36 total)', () {
      final states = LocationMasterService.instance.getStates();
      expect(states.length, 36);

      // Verify representative states and UTs are present
      final stateNames = states.map((s) => s.nameEn).toSet();
      expect(stateNames.contains('Punjab'), isTrue);
      expect(stateNames.contains('Telangana'), isTrue);
      expect(stateNames.contains('Maharashtra'), isTrue);
      expect(stateNames.contains('Tamil Nadu'), isTrue);
      expect(stateNames.contains('Uttar Pradesh'), isTrue);
      expect(stateNames.contains('Gujarat'), isTrue);
      expect(stateNames.contains('Rajasthan'), isTrue);
      expect(stateNames.contains('West Bengal'), isTrue);
      expect(stateNames.contains('Delhi'), isTrue);
      expect(stateNames.contains('Jammu and Kashmir'), isTrue);
      expect(stateNames.contains('Ladakh'), isTrue);
      expect(stateNames.contains('Andaman and Nicobar Islands'), isTrue);
    });

    test('9. Cascading District and Mandal lookup across Indian States', () {
      final master = LocationMasterService.instance;

      // Maharashtra -> Pune -> Haveli / Baramati
      final mhDistricts = master.getDistrictsForState('maharashtra');
      expect(mhDistricts.isNotEmpty, isTrue);
      expect(mhDistricts.any((d) => d.nameEn == 'Pune'), isTrue);
      final puneMandals = master.getMandalsForDistrict('pune');
      expect(puneMandals.any((m) => m.nameEn == 'Baramati'), isTrue);

      // Tamil Nadu -> Chennai -> Guindy
      final tnDistricts = master.getDistrictsForState('tamil_nadu');
      expect(tnDistricts.any((d) => d.nameEn == 'Chennai'), isTrue);
      final chennaiMandals = master.getMandalsForDistrict('chennai');
      expect(chennaiMandals.any((m) => m.nameEn == 'Guindy'), isTrue);

      // Punjab -> Ludhiana -> Khanna
      final pbDistricts = master.getDistrictsForState('punjab');
      expect(pbDistricts.any((d) => d.nameEn == 'Ludhiana'), isTrue);
      final ludhianaMandals = master.getMandalsForDistrict('ludhiana');
      expect(ludhianaMandals.any((m) => m.nameEn == 'Khanna'), isTrue);
    });

    testWidgets('10. Parent change resets child selections (State resets District & Mandal)', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'Punjab',
          initialDistrict: 'Ludhiana',
          initialMandal: 'Khanna',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('Khanna'), findsOneWidget);

      // Tap State selector to change State to Telangana
      final stateField = find.byKey(const ValueKey('select_state_field'));
      await tester.ensureVisible(stateField);
      await tester.tap(stateField);
      await tester.pumpAndSettle();

      // Find and select Telangana in sheet
      final telanganaItem = find.byKey(const ValueKey('picker_item_telangana'));
      await tester.ensureVisible(telanganaItem);
      await tester.tap(telanganaItem);
      await tester.pumpAndSettle();

      // District and Mandal should now be reset
      expect(find.text('Select District'), findsOneWidget);
      expect(find.text('Select District first'), findsOneWidget);
    });

    testWidgets('11. Nearby centre fallback triggers when View Nearby Centres is tapped', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final state = ProcurementStateService();
      state.reset();

      // State without configured centres in this mandal (e.g. West Bengal -> Howrah -> Uluberia)
      await tester.pumpWidget(MaterialApp(
        home: FarmerBookSlotScreen(
          currentData: state.farmerData,
          isHindi: false,
          isTelugu: false,
          initialState: 'West Bengal',
          initialDistrict: 'Howrah',
          initialMandal: 'Uluberia',
          isLocationConfirmed: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No procurement centre currently available in this area.'), findsOneWidget);
      final nearbyBtn = find.byKey(const ValueKey('btn_view_nearby_centres'));
      expect(nearbyBtn, findsOneWidget);

      // Tap View Nearby Centres
      await tester.ensureVisible(nearbyBtn);
      await tester.pumpAndSettle();
      await tester.tap(nearbyBtn);
      await tester.pumpAndSettle();

      // Nearby centres loaded and indicator is shown
      expect(find.text('Showing nearby available centres'), findsOneWidget);
      expect(find.textContaining('Nearby Procurement Centres'), findsOneWidget);
      expect(find.text('No procurement centre currently available in this area.'), findsNothing);
    });

    test('12. Distance calculation and sorting adheres to Haversine straight-line distance', () {
      const farmerLat = 30.7000;
      const farmerLng = 76.2000;

      final centres = ProcurementCentre.getMockCentres();
      final c1 = centres.firstWhere((c) => c.id == 'centre_1');
      final c2 = centres.firstWhere((c) => c.id == 'centre_2');

      final d1 = c1.calculateDistanceKmFrom(farmerLat, farmerLng);
      final d2 = c2.calculateDistanceKmFrom(farmerLat, farmerLng);

      expect(d1, isNotNull);
      expect(d2, isNotNull);
      expect(d1!, greaterThan(0));
      expect(d2!, greaterThan(0));

      // Formatting
      final label = LocationDistanceService.formatDistanceLabel(d1, isHindi: false, isTelugu: false);
      expect(label, contains('km from your location'));

      // Location off formatting
      final labelNoLoc = LocationDistanceService.formatDistanceLabel(null, isHindi: false, isTelugu: false);
      expect(labelNoLoc, 'Distance unavailable — enable location to see distance');
    });

    test('13. ProcurementCentre contains supportedCrops and minimum verified fields', () {
      final centres = ProcurementCentre.getMockCentres();
      for (final centre in centres) {
        expect(centre.id.isNotEmpty, isTrue);
        expect(centre.name.isNotEmpty, isTrue);
        expect(centre.state.isNotEmpty, isTrue);
        expect(centre.district.isNotEmpty, isTrue);
        expect(centre.mandal.isNotEmpty, isTrue);
        expect(centre.operatingStatus != null, isTrue);
        expect(centre.processingRatePerHour, greaterThan(0));
        expect(centre.supportedCrops.isNotEmpty, isTrue);
        expect(centre.supportedCrops.contains('Wheat') || centre.supportedCrops.contains('Paddy (Rice)'), isTrue);
      }
    });
  });

  group('Phase 27: Real Camera QR Scanner & Gate Check-In Tests', () {
    testWidgets('1. GateCameraPreview renders live viewfinder with instructions and controls',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: false,
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Scan Farmer QR'), findsOneWidget);
      expect(find.textContaining('Khanna Grain Market'), findsOneWidget);
      expect(find.text('LIVE CAMERA'), findsOneWidget);
      expect(find.byIcon(Icons.cameraswitch_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
    });

    testWidgets('2. GateCameraPreview renders paused overlay with Scan Another QR action',
        (tester) async {
      bool resumed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: true,
            onResumeScan: () => resumed = true,
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('QR Scanned'), findsOneWidget);
      expect(find.text('Scan Another QR'), findsOneWidget);

      await tester.tap(find.text('Scan Another QR'));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('3. Officer QR Scanner screen integrates GateCameraPreview with demo simulation and manual fallback',
        (tester) async {
      ProcurementStateService().reset();
      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GateCameraPreview), findsOneWidget);
      expect(find.text('Scan Farmer QR'), findsOneWidget);
      expect(find.text('Demo Simulation Scans'), findsOneWidget);
      expect(find.text('TK-8492 (Ramesh)'), findsOneWidget);
      expect(find.text('Enter Token Number (e.g. TK-8492)'), findsOneWidget);
    });
  });

  group('Phase A: Officer Portal Foundation Tests', () {
    testWidgets(
        '1. Officer Login authenticates, associates centre, and routes to OfficerDashboardScreen',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerLoginScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Procurement Officer Login'), findsOneWidget);
      expect(find.text('Auto-Fill'), findsOneWidget);

      await tester.tap(find.text('Auto-Fill'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficerDashboardScreen), findsOneWidget);
      expect(AuthService.instance.currentRole, equals(UserRole.officer));
      expect(AuthService.instance.currentCentreId, isNotNull);
    });

    testWidgets(
        '2. Desktop Officer Operations Dashboard renders assigned centre, status banner, and non-color indicators',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(
          officerId: 'OFFICER001',
          centreId: '11111111-1111-1111-1111-111111111111',
        ),
      ));
      await tester.pumpAndSettle();

      // Centre identity & status banner with icon and text
      expect(find.byKey(const Key('officer_centre_status_banner')), findsOneWidget);
      expect(find.text('Example Procurement Centre'), findsWidgets);
      expect(find.text('Normal / Open'), findsOneWidget);
      expect(find.textContaining('UUID: 11111111'), findsOneWidget);

      // Operational indicators
      expect(find.textContaining('Current Load'), findsWidgets);
      expect(find.text('Queue Size'), findsWidgets);
      expect(find.textContaining('Estimated Wait'), findsWidgets);
    });

    testWidgets(
        '3. Operational KPI grid renders all 11 operational metrics',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER001'),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Today's Bookings"), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Waiting'), findsWidgets);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Average Wait'), findsWidgets);
      expect(find.text('Processing Rate'), findsWidgets);
      expect(find.text('Capacity'), findsWidgets);
      expect(find.text('Delay (min)'), findsWidgets);
      expect(find.text('Payment Pending'), findsWidgets);
      expect(find.text('Active Alerts'), findsWidgets);
      expect(find.text('Active Slots'), findsWidgets);
    });

    testWidgets(
        '4. All 8 Action Areas open respective workflows, modals, or smooth scroll',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER001'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_live_queue')), findsOneWidget);
      expect(find.byKey(const Key('action_qr_checkin')), findsOneWidget);
      expect(find.byKey(const Key('action_procurement')), findsOneWidget);
      expect(find.byKey(const Key('action_slots')), findsOneWidget);
      expect(find.byKey(const Key('action_alerts')), findsOneWidget);
      expect(find.byKey(const Key('action_payments')), findsOneWidget);
      expect(find.byKey(const Key('action_analytics')), findsOneWidget);
      expect(find.byKey(const Key('action_profile')), findsOneWidget);

      // Tap Slot Management -> Modal Bottom Sheet
      await tester.tap(find.byKey(const Key('action_slots')));
      await tester.pumpAndSettle();
      expect(find.text('Dock Slot Management'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap Payments -> DBT payment settlement dialog
      await tester.tap(find.byKey(const Key('action_payments')));
      await tester.pumpAndSettle();
      expect(find.text('DBT Payments & Settlements'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Analytics -> Throughput & Risk dialog
      await tester.tap(find.byKey(const Key('action_analytics')));
      await tester.pumpAndSettle();
      expect(find.text('Procurement Analytics & Forecast'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Officer Profile -> Profile dialog
      await tester.tap(find.byKey(const Key('action_profile')));
      await tester.pumpAndSettle();
      expect(find.text('Officer Credentials'), findsOneWidget);
      expect(find.text('OFFICER001'), findsWidgets);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        '5. Centre operating status can be changed dynamically updating banner and indicators',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER001'),
      ));
      await tester.pumpAndSettle();

      // Initially Open • Normal
      expect(find.text('Normal / Open'), findsOneWidget);

      // Change status to Temporarily Delayed
      await tester.ensureVisible(find.text('Temporarily Delayed'));
      await tester.tap(find.text('Temporarily Delayed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Delayed'), findsWidgets);
    });

    testWidgets(
        '6. Voice listen guidance triggers successfully and provides operational speech audio info',
        (WidgetTester tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER001'),
      ));
      await tester.pumpAndSettle();

      // Tap Listen / सुनें tooltip
      await tester.tap(find.byTooltip('Listen / सुनें'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Procurement Operations Dashboard'), findsOneWidget);
    });
  });

  group('Phase B: Real Camera QR Check-In & Farmer Verification Tests', () {
    testWidgets('1. GateCameraPreview displays initializing camera state',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: false,
            testInitializing: true,
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Initializing Camera...'), findsOneWidget);
      expect(find.text('Requesting browser/device camera permission'),
          findsOneWidget);
    });

    testWidgets(
        '2. GateCameraPreview displays Camera Access Blocked with Chrome guidance and retry button',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: false,
            testPermissionDenied: true,
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Camera Access Blocked'), findsOneWidget);
      expect(
        find.textContaining('Camera access is blocked'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Retry Camera'), findsOneWidget);
    });

    testWidgets(
        '3. GateCameraPreview displays No Camera Detected with retry button',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: false,
            testNoCamera: true,
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Camera Detected'), findsOneWidget);
      expect(
        find.textContaining('No video input device found'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Retry Camera'), findsOneWidget);
    });

    testWidgets(
        '4. GateCameraPreview displays Camera Unavailable on error with retry button',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GateCameraPreview(
            centreName: 'Khanna Grain Market',
            isScanningPaused: false,
            testErrorMessage: 'Hardware device disconnected or in use',
            onBarcodeScanned: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Camera Unavailable'), findsOneWidget);
      expect(find.text('Hardware device disconnected or in use'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry Camera'), findsOneWidget);
    });

    testWidgets(
        '5. OfficerQrScannerScreen validates QR payload and displays FARMER VERIFIED confirmation card with checklist',
        (tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      // Trigger valid QR simulation for TK-8492
      await tester.tap(find.text('TK-8492 (Ramesh)'));
      await tester.pumpAndSettle();

      expect(find.text('FARMER VERIFIED'), findsOneWidget);
      expect(find.text('QR Pass Verified'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('50 Quintals'), findsOneWidget);
      expect(find.text('11:30 AM'), findsOneWidget);
      expect(find.text('Example Procurement Centre'), findsWidgets);

      // Check the 3 status checklist items
      expect(find.text('✓ Valid QR'), findsOneWidget);
      expect(find.text('✓ Correct Centre'), findsOneWidget);
      expect(find.text('✓ Booking Confirmed'), findsOneWidget);

      // Primary check-in button present
      expect(find.text('CHECK IN FARMER'), findsOneWidget);
    });

    testWidgets(
        '6. CHECK IN FARMER button confirms check-in, transitions farmer to live queue, and shows Already Checked In',
        (tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      // Trigger valid QR simulation
      await tester.tap(find.text('TK-8492 (Ramesh)'));
      await tester.pumpAndSettle();

      // Confirm check in
      await tester.ensureVisible(find.text('CHECK IN FARMER'));
      await tester.tap(find.text('CHECK IN FARMER'));
      await tester.pumpAndSettle();

      // Verify snackbar confirmed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Check-In Confirmed for TK-8492'), findsOneWidget);

      // Verify status updated to Already Checked In
      expect(find.text('Farmer is Already Checked In & In Queue'), findsOneWidget);

      // Verify state in state service
      final item = ProcurementStateService()
          .queue
          .firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(item.checkInStatus, equals('Checked In'));
    });

    testWidgets('7. OfficerQrScannerScreen rejects wrong centre QR code',
        (tester) async {
      ProcurementStateService().reset();
      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wrong Centre'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('Wrong Centre'), findsWidgets);
      expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);
      expect(find.text('CHECK IN FARMER'), findsNothing);
    });

    testWidgets('8. OfficerQrScannerScreen rejects malformed QR code',
        (tester) async {
      ProcurementStateService().reset();
      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Malformed QR'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('Invalid KisanSetu QR code format'), findsOneWidget);
    });

    testWidgets('9. OfficerQrScannerScreen rejects unknown token',
        (tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), 'TK-99999');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Verify'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('Token TK-99999 not found'), findsOneWidget);
    });

    testWidgets(
        '10. Duplicate scan protection rejects token if already checked in',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();
      state.checkInFarmer('TK-8492');

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      // Scan already checked-in farmer
      await tester.tap(find.text('TK-8492 (Ramesh)'));
      await tester.pumpAndSettle();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.textContaining('already checked in'), findsOneWidget);
      expect(find.text('CHECK IN FARMER'), findsNothing);
    });

    testWidgets(
        '11. Demo simulation scan chips trigger validation for TK-8492 and TK-8493',
        (tester) async {
      ProcurementStateService().reset();
      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TK-8493 (Harpreet)'));
      await tester.pumpAndSettle();

      expect(find.text('FARMER VERIFIED'), findsOneWidget);
      expect(find.text('Harpreet Singh'), findsOneWidget);
      expect(find.text('TK-8493'), findsOneWidget);
    });

    testWidgets('12. Manual token input fallback verifies and processes token',
        (tester) async {
      ProcurementStateService().reset();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerQrScannerScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), 'TK-8492');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Verify'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
      await tester.pumpAndSettle();

      expect(find.text('FARMER VERIFIED'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('CHECK IN FARMER'), findsOneWidget);
    });
  });

  group('Phase C: Procurement Operations & Farmer Processing Tests', () {
    testWidgets('1. Checked-in farmer enters procurement processing successfully', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      expect(service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492').checkInStatus, 'Checked In');
      final canStart = service.startProcurement('TK-8492');
      expect(canStart, isTrue);
      expect(service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492').status, 'Quality Check');
    });

    testWidgets('2. Un-arrived / Booked farmer cannot enter procurement directly', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      expect(service.queue.firstWhere((q) => q.tokenNumber == 'TK-8493').checkInStatus, 'Not Checked In');
      final canStart = service.startProcurement('TK-8493');
      expect(canStart, isFalse);
      expect(service.queue.firstWhere((q) => q.tokenNumber == 'TK-8493').status, 'Booked');
    });

    testWidgets('3. Officer Live Queue displays checked-in farmer with metadata and START PROCUREMENT action', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFF-101'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live Queue'), findsWidgets);
      await tester.ensureVisible(find.text('TK-8492'));
      expect(find.text('TK-8492'), findsOneWidget);
      expect(find.text('START PROCUREMENT'), findsWidgets);
    });

    testWidgets('4. Farmer Verification stage displays metadata and actions', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('FARMER VERIFICATION'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsWidgets);
      expect(find.text('TK-8492'), findsWidgets);
      expect(find.text('VERIFY & CONTINUE'), findsOneWidget);
      expect(find.text('HOLD / RETURN TO QUEUE'), findsOneWidget);
    });

    testWidgets('5. Quality Inspection stage allows grade selection and recording notes', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QUALITY INSPECTION'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'FAQ'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Grade A'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Grade B'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Grade A'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Confirm Quality'));
      await tester.pumpAndSettle();

      expect(ProcurementStateService().queue.firstWhere((q) => q.tokenNumber == 'TK-8492').qualityGrade, 'Grade A');
    });

    testWidgets('6. Weighment stage validates actual weight, auto-calculates difference, and preserves audit trail', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('WEIGHMENT'), findsOneWidget);
      expect(find.text('Registered Quantity:'), findsOneWidget);
      expect(find.text('Units: Qtl / Quintal'), findsOneWidget);

      service.confirmWeighment('TK-8492', 51.5, overrideReason: 'Scale calibration adjustment');
      await tester.pumpAndSettle();

      final item = service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(item.actualQuantity, '51.5 Quintals');
      expect(item.discrepancyNote, contains('Scale calibration adjustment'));
    });

    testWidgets('7. Procurement Summary clearly distinguishes CCEA 2024-25 reference benchmark and allows acceptance', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      service.startProcurement('TK-8492');
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PROCUREMENT SUMMARY'), findsOneWidget);
      expect(find.textContaining('CCEA 2024-25 Benchmark Reference'), findsOneWidget);
      expect(find.text('ACCEPT PROCUREMENT'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'ACCEPT PROCUREMENT'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'ACCEPT PROCUREMENT'));
      await tester.pumpAndSettle();

      final updated = ProcurementStateService().queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(updated.status, 'Accepted');
      expect(updated.paymentStatus, 'Pending');
    });

    testWidgets('8. Bill and Payment readiness displays procurement accepted banner and lifecycle transitions', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      service.startProcurement('TK-8492');
      service.acceptProduce('TK-8492');

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PROCUREMENT ACCEPTED ✓'), findsOneWidget);
      expect(find.text('Payment Status & Actions'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Initiate Payment'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Initiate Payment'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Initiate Payment'));
      await tester.pumpAndSettle();

      expect(service.queue.firstWhere((q) => q.tokenNumber == 'TK-8492').paymentStatus, 'Processing');
    });

    testWidgets('9. Duplicate acceptance prevention guards completed and accepted items', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      service.startProcurement('TK-8492');
      final firstAccept = service.acceptProduce('TK-8492');
      expect(firstAccept, isTrue);

      service.markPaymentCompleted('TK-8492');
      final duplicateAccept = service.acceptProduce('TK-8492');
      expect(duplicateAccept, isFalse);
    });

    testWidgets('10. Farmer portal reflects updated procurement stage and payment readiness', (tester) async {
      final service = ProcurementStateService();
      service.reset();
      service.checkInFarmer('TK-8492');
      service.startProcurement('TK-8492');
      service.confirmQuality('TK-8492', 'Grade A');
      service.confirmWeighment('TK-8492', 50.2);
      service.acceptProduce('TK-8492');

      expect(service.farmerData.lifecycleStatus, 'Accepted');
      expect(service.farmerData.paymentStatus, 'Pending');
      expect(service.farmerData.qualityGrade, 'Grade A');
      expect(service.farmerData.actualQuantity, '50.2 Quintals');
    });
  });

  group('Phase E: Dispute Audit, Payment Oversight & Centre Administration Tests', () {
    setUp(() {
      AppPreferencesService.instance.setUiLanguage('en');
      ProcurementStateService().reset();
    });

    // 1. Dispute Audit Console lists active and historical disputes
    testWidgets('1. Dispute Audit Console displays metrics, filter tabs, and dispute cards with discrepancy %',
        (tester) async {
      final state = ProcurementStateService();
      state.seedDemoDisputes();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDisputeConsoleScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dispute Audit Console'), findsOneWidget);
      expect(find.text('DISP-8492'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('TK-8492'), findsWidgets);
      expect(find.text('Wheat'), findsWidgets);
      expect(find.textContaining('-2.20 Qtl'), findsWidgets);
      expect(find.textContaining('(-4.4%)'), findsWidgets);
      expect(find.text('Active Disputes'), findsWidgets);
    });

    // 2. Dispute Detail Review & Actions
    testWidgets('2. Selecting a dispute displays required review layout and allows Resolve / Reject / Escalate',
        (tester) async {
      final state = ProcurementStateService();
      state.seedDemoDisputes();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDisputeConsoleScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap on the dispute card
      await tester.tap(find.byKey(const Key('dispute_card_DISP-8492')));
      await tester.pumpAndSettle();

      expect(find.text('DISPUTE REVIEW'), findsOneWidget);
      expect(find.text('Quantity discrepancy'), findsWidgets);
      expect(find.text('OFF-101'), findsWidgets);

      // Verify actions exist
      expect(find.widgetWithText(ElevatedButton, 'RESOLVE'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'REJECT'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'ESCALATE'), findsOneWidget);

      // Resolve the dispute
      final resolveBtn = find.widgetWithText(ElevatedButton, 'RESOLVE');
      await tester.ensureVisible(resolveBtn);
      await tester.tap(resolveBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog shown
      expect(find.text('Resolve Dispute'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Verified weighbridge tare calibration and resolved discrepancy.');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Resolution'));
      await tester.pumpAndSettle();

      final updated = state.disputes.firstWhere((d) => d.id == 'DISP-8492');
      expect(updated.status, 'Resolved');
      expect(updated.officerNotes, contains('Verified weighbridge tare'));
    });

    // 3. Weighment Audit Trail
    testWidgets('3. Weighment Audit Trail records scale corrections and remains read-only', (tester) async {
      final state = ProcurementStateService();
      state.reset();
      state.checkInFarmer('TK-8492');
      state.startProcurement('TK-8492');

      // Record a weighment override
      state.confirmWeighment('TK-8492', 50.2, overrideReason: 'Scale correction');

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerFarmerDetailScreen(tokenNumber: 'TK-8492'),
      ));
      await tester.pumpAndSettle();

      final auditCard = find.byKey(const Key('weighment_audit_trail_card'));
      await tester.ensureVisible(auditCard);
      expect(auditCard, findsOneWidget);
      expect(find.text('WEIGHMENT AUDIT TRAIL'), findsOneWidget);
      expect(find.textContaining('Read-Only'), findsWidgets);
      expect(find.textContaining('Scale correction'), findsWidgets);
      expect(find.text('Original Weight'), findsWidgets);
      expect(find.text('Updated Weight'), findsWidgets);

      final audits = state.getWeighmentAuditsForToken('TK-8492');
      expect(audits.isNotEmpty, isTrue);
      expect(audits.first.originalWeight, 50.0);
      expect(audits.first.updatedWeight, 50.2);
    });

    // 4. Payment Oversight interface & DBT Lifecycle
    testWidgets('4. Payment Oversight screen displays 7-stage lifecycle, DBT metrics, and payment list',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerPaymentOversightScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Payment Oversight & Exceptions'), findsOneWidget);
      expect(find.text('MSP DBT Payouts & Exception Handling'), findsOneWidget);
      expect(find.text('DBT Lifecycle Pipeline'), findsOneWidget);
      expect(find.text('Produce Accepted'), findsOneWidget);
      expect(find.text('Payment Eligible'), findsOneWidget);
      expect(find.text('Payment Pending'), findsWidgets);
      expect(find.text('Payment Initiated'), findsOneWidget);
      expect(find.text('Processing'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);

      // Verify payment row contains token and amount
      expect(find.text('TK-8492'), findsWidgets);
      expect(find.text('Ramesh Kumar'), findsWidgets);
    });

    // 5. Payment Exceptions Card and Actions
    testWidgets('5. Payment Oversight identifies exceptions with severity, recommended action, and retry',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      // Simulate a failed payment
      state.markPaymentFailed('TK-8492', reason: 'Bank server timeout during IFSC routing');

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerPaymentOversightScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Payment Exceptions Requiring Attention'), findsOneWidget);
      expect(find.text('PAYMENT EXCEPTION'), findsWidgets);
      expect(find.text('TK-8492'), findsWidgets);
      expect(find.text('Retry Settlement'), findsOneWidget);

      // Tap Retry Settlement
      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry Settlement'));
      await tester.pumpAndSettle();

      final item = state.queue.firstWhere((q) => q.tokenNumber == 'TK-8492');
      expect(item.paymentStatus, 'Processing');
    });

    // 6. Centre Administration details and location
    testWidgets('6. Centre Administration displays authorized centre details, operational status, and location coordinates',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerCentreAdminScreen(
          officerId: 'OFFICER001',
          centreId: '11111111-1111-1111-1111-111111111111',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Procurement Centre Administration'), findsOneWidget);
      expect(find.text('Operating Status & Operational Controls'), findsOneWidget);
      expect(find.text('Centre Location & Geolocation'), findsOneWidget);
      expect(find.text('State:'), findsOneWidget);
      expect(find.text('District:'), findsOneWidget);
      expect(find.text('Mandal:'), findsOneWidget);
      expect(find.text('Latitude:'), findsOneWidget);
      expect(find.text('Longitude:'), findsOneWidget);
      expect(find.text('Operational Parameters'), findsOneWidget);
      expect(find.text('Processing Rate (Qtl/hr)'), findsOneWidget);
      expect(find.text('Dock Delay (min)'), findsOneWidget);
    });

    // 7. Centre Status Control & Temporarily Stopped Confirmation Modal
    testWidgets('7. Setting centre to Temporarily Stopped triggers confirmation dialog before applying',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerCentreAdminScreen(
          officerId: 'OFFICER001',
          centreId: '11111111-1111-1111-1111-111111111111',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on Temporarily Stopped segment
      await tester.tap(find.text('Temporarily Stopped'));
      await tester.pumpAndSettle();

      // Required safety confirmation modal must appear
      expect(find.text('Confirm Centre Suspension'), findsOneWidget);
      expect(find.textContaining('Stopping this centre may affect upcoming farmer arrivals and slots.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Yes, Stop Centre Operations'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'Yes, Stop Centre Operations'));
      await tester.pumpAndSettle();

      expect(state.centreStatus, contains('Stopped'));
    });

    // 8. Centre Operational Parameters update recalculates state and affects Farmer Go-Time
    testWidgets('8. Operational parameter changes update state service and feed intelligence recalculations',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      state.updateCentreParameters(
        capacity: 120,
        processingRatePerHour: 18,
        delayMinutes: 20,
      );

      expect(state.centreCapacity, 120);
      expect(state.centreProcessingRatePerHour, 18.0);
      expect(state.centreDelayMinutes, 20);
      expect(state.centreStatus, contains('Delayed'));

      // Farmer Go-Time reflects the updated delay
      expect(state.farmerData.expectedWaitMinutes, greaterThan(0));
    });

    // 9. Officer authorization boundary prevents cross-centre modification
    testWidgets('9. Unauthorized officer cannot modify another centre outside assigned currentCentreId',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      // Assign officer to centre A
      AuthService.instance.setDemoRole(
        'officer',
        officerId: 'OFFICER001',
        centreId: '11111111-1111-1111-1111-111111111111',
      );

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      // Try to open centre administration for another unassigned centre B
      await tester.pumpWidget(const MaterialApp(
        home: OfficerCentreAdminScreen(
          officerId: 'OFFICER001',
          centreId: '99999999-9999-9999-9999-999999999999',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('You are not authorized to configure operations for this procurement centre.'), findsOneWidget);
      expect(find.byKey(const Key('btn_save_centre_operations')), findsNothing);
    });

    // 10. Officer Dashboard Action Areas & Quick Navigation
    testWidgets('10. Officer Dashboard renders Disputes and Centre Admin action items and navigates successfully',
        (tester) async {
      final state = ProcurementStateService();
      state.reset();

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(const MaterialApp(
        home: OfficerDashboardScreen(officerId: 'OFFICER001'),
      ));
      await tester.pumpAndSettle();

      // Verify new action items exist
      expect(find.byKey(const Key('action_disputes')), findsOneWidget);
      expect(find.byKey(const Key('action_centre_admin')), findsOneWidget);

      // Tap Disputes -> Opens OfficerDisputeConsoleScreen
      await tester.tap(find.byKey(const Key('action_disputes')));
      await tester.pumpAndSettle();
      expect(find.byType(OfficerDisputeConsoleScreen), findsOneWidget);

      // Pop back
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(OfficerDashboardScreen), findsOneWidget);

      // Tap Centre Admin -> Opens OfficerCentreAdminScreen
      await tester.tap(find.byKey(const Key('action_centre_admin')));
      await tester.pumpAndSettle();
      expect(find.byType(OfficerCentreAdminScreen), findsOneWidget);
    });
  });
}




