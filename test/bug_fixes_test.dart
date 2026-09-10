// KisanSetu (SIH26032) - Change Crop & Auth Session Verification Tests
// Validates:
// 1. Bug 1: Crop catalogue availability, multilingual findByName matching,
//    FarmerCropSelectionScreen rendering 23 crops, category chips, search,
//    crop selection & quantity update, and produce persistence.
// 2. Bug 2: AuthService session creation, session restoration, role recovery,
//    and KisanSetuApp startup flow without login flash.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisansetu/main.dart';
import 'package:kisansetu/models/crop_model.dart';
import 'package:kisansetu/screens/farmer_crop_selection_screen.dart';
import 'package:kisansetu/screens/farmer_dashboard_screen.dart';
import 'package:kisansetu/screens/role_selection_screen.dart';
import 'package:kisansetu/services/auth_service.dart';
import 'package:kisansetu/services/crop_catalogue_service.dart';
import 'package:kisansetu/services/procurement_state_service.dart';
import 'package:kisansetu/services/repositories/repository_provider.dart';
import 'package:kisansetu/widgets/farmer/produce_summary_card.dart';

void main() {
  setUp(() {
    ProcurementStateService().reset();
  });

  group('Bug 1: Change Crop Screen & Crop Catalogue Verification', () {
    test('1. CropCatalogueService.findByName resolves bilingual strings and aliases', () {
      // Must resolve seed database value 'Wheat (गेहूं)'
      final wheatBilingual = CropCatalogueService.findByName('Wheat (गेहूं)');
      expect(wheatBilingual, isNotNull);
      expect(wheatBilingual!.id, 'wheat');
      expect(wheatBilingual.cropName, 'Wheat');

      // Standard English
      final wheatEn = CropCatalogueService.findByName('Wheat');
      expect(wheatEn, isNotNull);
      expect(wheatEn!.id, 'wheat');

      // Hindi name
      final wheatHi = CropCatalogueService.findByName('गेहूं');
      expect(wheatHi, isNotNull);
      expect(wheatHi!.id, 'wheat');

      // Telugu name
      final wheatTe = CropCatalogueService.findByName('గోధుమలు');
      expect(wheatTe, isNotNull);
      expect(wheatTe!.id, 'wheat');

      // Paddy / Rice
      final paddy = CropCatalogueService.findByName('Paddy / Rice');
      expect(paddy, isNotNull);
      expect(paddy!.id, 'paddy');

      // Extended crop from 20+ list (Mustard, Cotton, etc.)
      final mustard = CropCatalogueService.findByName('Mustard');
      expect(mustard, isNotNull);
      expect(mustard!.category, CropCategory.oilseeds);

      final cotton = CropCatalogueService.findByName('Cotton');
      expect(cotton, isNotNull);
      expect(cotton!.category, CropCategory.commercial);

      // Total catalogue count
      expect(CropCatalogueService.allCrops.length, 23);
      expect(CropCatalogueService.default10Crops.length, 10);
    });

    testWidgets('2. FarmerCropSelectionScreen immediately displays catalogue with initial crop',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerCropSelectionScreen(
            currentCropName: 'Wheat (गेहूं)',
            currentQuantity: 60.0,
            isHindi: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Select Crop'), findsOneWidget);

      // Search bar and category chips
      expect(find.byKey(const ValueKey('search_crop_input')), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cereals'), findsOneWidget);
      expect(find.text('Pulses'), findsOneWidget);
      expect(find.text('Oilseeds'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);

      // Crop cards appear immediately
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_paddy')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_maize')), findsOneWidget);

      // Test category filtering
      await tester.tap(find.text('Pulses'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_gram')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_tur')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsNothing);

      // Return to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);

      // Test search
      await tester.enterText(
          find.byKey(const ValueKey('search_crop_input')), 'Mustard');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_mustard')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsNothing);

      // Clear search
      await tester.enterText(
          find.byKey(const ValueKey('search_crop_input')), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
    });

    testWidgets('3. Selecting a new crop updates state and associates quantity',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      final state = ProcurementStateService();
      expect(state.farmerData.cropName, 'Wheat');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => const FarmerCropSelectionScreen(
                      currentCropName: 'Wheat',
                      currentQuantity: 50.0,
                      isHindi: false,
                    ),
                  ),
                ),
                child: const Text('Open Selection'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Crop Selection Screen
      await tester.tap(find.text('Open Selection'));
      await tester.pumpAndSettle();

      // Tap on Mustard card
      await tester.tap(find.byKey(const ValueKey('crop_card_mustard')));
      await tester.pumpAndSettle();

      // Tap bottom Proceed button
      await tester.tap(find.byKey(const ValueKey('btn_proceed_crop_selection')));
      await tester.pumpAndSettle();

      // Active booking warning appears for Ramesh Kumar (has active booking TK-8492)
      if (find.byKey(const ValueKey('btn_confirm_booking_warning')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('btn_confirm_booking_warning')));
        await tester.pumpAndSettle();
      }

      // Quantity modal appears
      expect(find.byKey(const ValueKey('input_crop_quantity')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_save_crop_selection')), findsOneWidget);

      // Increase quantity using stepper (+10)
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();

      // Confirm & Save
      await tester.tap(find.byKey(const ValueKey('btn_save_crop_selection')));
      await tester.pumpAndSettle();

      // Verify that state is updated to Mustard and 60 Quintals
      expect(state.farmerData.cropName, 'Mustard');
      expect(state.farmerData.quantity, '60 Quintals');

      // Verify produce persistence via Repository
      final produce = await RepositoryProvider.farmer
          .getFarmerProduce('22222222-2222-2222-2222-222222222222');
      expect(produce.first['crop'], 'Mustard');
      expect(produce.first['quantity'], 60.0);
    });

    testWidgets('4. Default 10 crops match exact user specification and display on desktop view',
        (WidgetTester tester) async {
      final expected10Crops = [
        'Wheat',
        'Paddy (Rice)',
        'Maize (Corn)',
        'Jowar (Sorghum)',
        'Bajra (Pearl Millet)',
        'Ragi (Finger Millet)',
        'Bengal Gram (Chana)',
        'Red Gram (Tur / Arhar)',
        'Mustard',
        'Soybean',
      ];

      expect(CropCatalogueService.default10Crops.length, 10);
      for (int i = 0; i < 10; i++) {
        expect(CropCatalogueService.default10Crops[i].cropName, expected10Crops[i]);
      }

      // Verify that all user-requested crop varieties are available
      final userRequested = [
        'Paddy (Rice)',
        'Wheat',
        'Maize (Corn)',
        'Jowar (Sorghum)',
        'Bajra (Pearl Millet)',
        'Ragi (Finger Millet)',
        'Red Gram (Tur / Arhar)',
        'Green Gram (Moong)',
        'Black Gram (Urad)',
        'Bengal Gram (Chana)',
      ];
      for (final name in userRequested) {
        expect(CropCatalogueService.findByName(name), isNotNull);
      }

      // Test desktop width (1200x700) where screenshot 3 was taken
      await tester.binding.setSurfaceSize(const Size(1200, 700));

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmerCropSelectionScreen(
            currentCropName: 'Wheat',
            currentQuantity: 50.0,
            isHindi: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 10 crops should be present as cards
      for (final crop in CropCatalogueService.default10Crops) {
        expect(find.byKey(ValueKey('crop_card_${crop.id}')), findsOneWidget);
        expect(find.text(crop.cropName), findsWidgets);
      }

      // Bottom Action Bar must be visible and present
      expect(find.byKey(const ValueKey('btn_proceed_crop_selection')), findsOneWidget);
    });

    testWidgets('5. ProduceSummaryCard isolates Change Crop tap from outer onTap',
        (WidgetTester tester) async {
      bool outerTapped = false;
      bool changeCropTapped = false;

      final data = ProcurementStateService().farmerData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProduceSummaryCard(
              data: data,
              isHindi: false,
              onTap: () {
                outerTapped = true;
              },
              onChangeCrop: () {
                changeCropTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Change Crop specifically
      await tester.tap(find.byKey(const ValueKey('btn_change_crop')));
      await tester.pumpAndSettle();

      // Only changeCrop should have fired, NOT outerTapped!
      expect(changeCropTapped, isTrue);
      expect(outerTapped, isFalse);

      // Now tap produce name / quantity
      await tester.tap(find.text('${data.cropName} • ${data.quantity}'));
      await tester.pumpAndSettle();

      // Now outerTapped should have fired
      expect(outerTapped, isTrue);
    });
  });

  group('Bug 2: Auth Session & Refresh Persistence Verification', () {
    test('1. Local mode restoreSession returns unauthenticated cleanly', () async {
      final sessionState = await AuthService.instance.restoreSession();
      expect(sessionState.isAuthenticated, isFalse);
    });

    test('2. Farmer login sets user state correctly in local/demo mode', () async {
      final authResult = await AuthService.instance.verifyFarmerOtp(
        phoneNumber: '9876543210',
        otp: '123456',
      );
      expect(authResult.isSuccess, isTrue);
      expect(AuthService.instance.isAuthenticated, isTrue);
      expect(AuthService.instance.currentRole, UserRole.farmer);
      expect(AuthService.instance.currentUserId, isNotNull);

      // Logout clears session
      await AuthService.instance.logout();
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.currentUserId, isNull);
    });

    test('3. Officer login sets officer state correctly in local/demo mode', () async {
      final authResult = await AuthService.instance.loginOfficer(
        officerId: 'OFFICER001',
        password: '123456',
      );
      expect(authResult.isSuccess, isTrue);
      expect(AuthService.instance.isAuthenticated, isTrue);
      expect(AuthService.instance.currentRole, UserRole.officer);
      expect(AuthService.instance.currentOfficerId, 'OFFICER001');

      // Logout clears session
      await AuthService.instance.logout();
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.currentOfficerId, isNull);
    });

    testWidgets('4. KisanSetuApp startup resolves FarmerDashboardScreen directly when authenticated',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      const authenticatedSession = AuthSessionState(
        isAuthenticated: true,
        role: UserRole.farmer,
        userId: '22222222-2222-2222-2222-222222222222',
        phone: '9876543210',
      );

      await tester.pumpWidget(
        const KisanSetuApp(initialSession: authenticatedSession),
      );
      await tester.pumpAndSettle();

      // Directly renders FarmerDashboard without flashing or displaying RoleSelectionScreen
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
    });

    testWidgets('5. KisanSetuApp startup resolves RoleSelectionScreen when unauthenticated',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const KisanSetuApp(initialSession: AuthSessionState.unauthenticated),
      );
      await tester.pumpAndSettle();

      // Displays RoleSelectionScreen for login
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(FarmerDashboardScreen), findsNothing);
    });
  });
}
