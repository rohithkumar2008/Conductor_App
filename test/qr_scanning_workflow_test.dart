import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conductor_app/models/bus_linking_state.dart';
import 'package:conductor_app/models/bus_model.dart';
import 'package:conductor_app/models/route_model.dart';
import 'package:conductor_app/pages/route_confirmation_page.dart';
import 'package:conductor_app/services/bus_database_service.dart';
import 'package:conductor_app/services/translation_service.dart';
import 'package:conductor_app/services/trip_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QR Scanning & Bus Linking Workflow Unit Tests', () {
    setUp(() {
      TripService.unlinkBus();
      BusDatabaseService.simulateNetworkError = false;
      TranslationService.setLanguage('en');
    });

    test('1. Valid QR Code matching selected route validates successfully', () async {
      final route = RouteModel.getDefaultRoutes().first; // Route 111
      TripService.selectRoute(route);

      expect(TripService.workflowStep.value, LinkingWorkflowStep.confirmationPending);

      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:1102:TN38N2841:ACTIVE',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.busNumber, 'BUS-1102');
      expect(result.bus!.registrationNumber, 'TN 38 N 2841');
      expect(result.errorType, isNull);

      // Perform persistent link
      TripService.linkBusWithDetails(result.bus!, route);
      expect(TripService.isBusLinked.value, isTrue);
      expect(TripService.currentBusNumber.value, 'BUS-1102');
      expect(TripService.workflowStep.value, LinkingWorkflowStep.busLinked);
    });

    test('2. Wrong bus for route triggers BusValidationErrorType.wrongRoute', () async {
      // Conductor selects Route 111, but scans Bus 5011 (assigned to 5C)
      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:5011:TN38BG1029:ACTIVE',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.wrongRoute);
      expect(result.assignedRouteNumber, '5C');
      expect(result.errorMessage, contains('different route'));
    });

    test('3. Bus already linked to another conductor triggers alreadyLinked error', () async {
      // Bus 1120 has activeConductorId = 'C-4412'
      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:1120:TN38AS9012:ACTIVE',
        targetRouteNumber: '112',
        currentConductorId: 'C-8902', // Current conductor is different
      );

      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.alreadyLinked);
      expect(result.activeConductorId, 'C-4412');
      expect(result.errorMessage, contains('active in another conductor session'));
    });

    test('4. Expired QR code triggers BusValidationErrorType.expired', () async {
      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:EXP01:EXPIRED',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.expired);
    });

    test('5. Maintenance bus triggers BusValidationErrorType.underMaintenance', () async {
      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:MNT02:MAINTENANCE',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.underMaintenance);
    });

    test('6. Network timeout simulation triggers BusValidationErrorType.networkError', () async {
      BusDatabaseService.simulateNetworkError = true;

      final result = await BusDatabaseService.validateQrCodeAsync(
        'QURBAY:BUS:1102:TN38N2841:ACTIVE',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.networkError);
      expect(result.errorMessage, contains('Central Server'));
    });

    test('7. Manual entry fallback performs asynchronous lookup correctly', () async {
      final result = await BusDatabaseService.lookupBusManuallyAsync(
        'TN 38 N 2841',
        targetRouteNumber: '111',
        currentConductorId: 'C-8902',
      );

      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.busNumber, 'BUS-1102');
    });

    test('8. Trip direction toggling updates reversal state and summary', () {
      final route = RouteModel.getDefaultRoutes().first;
      TripService.selectRoute(route);

      expect(TripService.isReversed.value, isFalse);
      TripService.toggleDirection();
      expect(TripService.isReversed.value, isTrue);
      TripService.toggleDirection();
      expect(TripService.isReversed.value, isFalse);
    });

    test('9. Tamil localization translations are complete for all workflow strings', () {
      TranslationService.setLanguage('ta');

      expect(TranslationService.translate('proceed_to_scan'), 'ஸ்கேன் செய்ய தொடரவும்');
      expect(TranslationService.translate('link_confirmation_prompt'),
          contains('இந்த சாதனத்தை உங்கள் ஒதுக்கப்பட்ட பேருந்துடன்'));
      expect(TranslationService.translate('start_duty'), contains('பணியைத் தொடங்கு'));
      expect(TranslationService.translate('error_wrong_route_title'),
          'தேர்ந்தெடுக்கப்பட்ட பாதைக்கு தவறான பேருந்து');
    });
  });

  group('RouteConfirmationPage Widget Tests', () {
    setUp(() {
      TranslationService.setLanguage('en');
    });

    testWidgets('Renders route details, stops summary, confirmation box, and Proceed to Scan button',
        (WidgetTester tester) async {
      TranslationService.setLanguage('en');
      final route = RouteModel.getDefaultRoutes().first;
      TripService.selectRoute(route);

      await tester.pumpWidget(
        MaterialApp(
          home: RouteConfirmationPage(initialRoute: route),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Route Number
      expect(find.textContaining('111'), findsWidgets);
      expect(find.text(route.routeName), findsOneWidget);

      // Verify Direction & Route Summary
      expect(find.textContaining('Gandhipuram Central'), findsWidgets);
      expect(find.textContaining('Thudiyalur'), findsWidgets);
      expect(find.textContaining('9 Stops'), findsOneWidget);

      // Verify Explicit Confirmation Message
      expect(
        find.textContaining('Please confirm you are ready to link this device to your assigned bus'),
        findsOneWidget,
      );

      // Verify "Proceed to Scan" button is present and clearly visible
      expect(find.text('Proceed to Scan'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });
  });
}
