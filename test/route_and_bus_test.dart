import 'package:flutter_test/flutter_test.dart';
import 'package:conductor_app/models/bus_model.dart';
import 'package:conductor_app/models/route_model.dart';
import 'package:conductor_app/services/bus_database_service.dart';
import 'package:conductor_app/services/trip_service.dart';

void main() {
  group('RouteModel & TripService Tests', () {
    test('Default routes are populated with stops and numbers', () {
      final routes = RouteModel.getDefaultRoutes();
      expect(routes.length, greaterThanOrEqualTo(4));
      expect(routes.any((r) => r.routeNumber == '111'), isTrue);
      expect(routes.any((r) => r.routeNumber == '112'), isTrue);
      expect(routes.any((r) => r.routeNumber == '22B'), isTrue);
      expect(routes.any((r) => r.routeNumber == '5C'), isTrue);

      final route111 = routes.firstWhere((r) => r.routeNumber == '111');
      expect(route111.stops.length, greaterThanOrEqualTo(5));
      expect(route111.startPoint, 'Gandhipuram Central');
      expect(route111.endPoint, 'Thudiyalur');
    });

    test('Adding special route dynamically prepends to available routes', () {
      final specialRoute = RouteModel(
        routeNumber: 'SPL-DIWALI',
        routeName: 'Festival Superfast Express',
        startPoint: 'Gandhipuram Central',
        endPoint: 'Marudhamalai Temple',
        isSpecial: true,
        validityPeriod: 'Today (12 Hours)',
        stops: [
          RouteStop(title: 'Gandhipuram Central', time: '14:00', isCompleted: true),
          RouteStop(title: 'Marudhamalai Temple', time: '15:00', isCompleted: false),
        ],
      );

      TripService.addSpecialRoute(specialRoute);
      expect(TripService.availableRoutes.value.first.routeNumber, 'SPL-DIWALI');
      expect(TripService.selectedRouteModel.value.routeNumber, 'SPL-DIWALI');
      expect(TripService.selectedRouteModel.value.isSpecial, isTrue);
    });
  });

  group('BusDatabaseService QR Validation Tests', () {
    test('Valid standard bus QR code succeeds', () {
      final result = BusDatabaseService.validateQrCode('QURBAY:BUS:1102:TN38N2841:ACTIVE');
      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.busNumber, 'BUS-1102');
      expect(result.bus!.registrationNumber, 'TN 38 N 2841');
      expect(result.bus!.model, contains('Ashok Leyland'));
      expect(result.bus!.capacity, contains('48 Seats'));
    });

    test('Valid bus registration number in QR succeeds', () {
      final result = BusDatabaseService.validateQrCode('TN 38 AS 9012');
      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.busNumber, 'BUS-1120');
      expect(result.bus!.model, contains('Tata'));
    });

    test('Expired bus QR code returns failure with expired error type', () {
      final result = BusDatabaseService.validateQrCode('QURBAY:BUS:EXP01:EXPIRED');
      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.expired);
      expect(result.errorMessage, contains('expired'));
    });

    test('Under maintenance bus QR code returns maintenance error type', () {
      final result = BusDatabaseService.validateQrCode('QURBAY:BUS:MNT02:MAINTENANCE');
      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.underMaintenance);
      expect(result.errorMessage, contains('Maintenance'));
    });

    test('Unregistered QR code returns notFound error type', () {
      final result = BusDatabaseService.validateQrCode('RANDOM_INVALID_QR_STRING_9999');
      expect(result.isValid, isFalse);
      expect(result.errorType, BusValidationErrorType.notFound);
    });
  });

  group('BusDatabaseService Manual Lookup Tests', () {
    test('Lookup by bus number string succeeds', () {
      final result = BusDatabaseService.lookupBusManually('BUS-2204');
      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.registrationNumber, 'TN 38 AF 4829');
    });

    test('Lookup by route number fallback succeeds', () {
      final result = BusDatabaseService.lookupBusManually('5C');
      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.busNumber, 'BUS-5011');
    });

    test('Dynamic custom bus generation for novel route code', () {
      final result = BusDatabaseService.lookupBusManually('SPL-99');
      expect(result.isValid, isTrue);
      expect(result.bus, isNotNull);
      expect(result.bus!.status, BusStatus.active);
    });
  });

  group('TripService Bus Linking Tests', () {
    test('Linking bus activates state and unlinking resets state', () {
      final bus = BusDatabaseService.getAvailableFleet().first;
      final route = RouteModel.getDefaultRoutes().first;

      TripService.linkBusWithDetails(bus, route);
      expect(TripService.isBusLinked.value, isTrue);
      expect(TripService.currentBusNumber.value, bus.busNumber);
      expect(TripService.currentRegistration.value, bus.registrationNumber);
      expect(TripService.currentBusModel.value, bus.model);
      expect(TripService.currentCapacity.value, bus.capacity);
      expect(TripService.lastSyncTime.value, isNotNull);

      TripService.unlinkBus();
      expect(TripService.isBusLinked.value, isFalse);
      expect(TripService.currentBusNumber.value, isNull);
      expect(TripService.currentRegistration.value, isNull);
    });
  });
}
