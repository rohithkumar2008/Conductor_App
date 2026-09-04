import 'dart:async';
import 'dart:convert';
import '../models/bus_model.dart';
import 'translation_service.dart';

class BusDatabaseService {
  static final List<BusModel> _fleetDatabase = [
    BusModel(
      busNumber: 'BUS-1102',
      registrationNumber: 'TN 38 N 2841',
      busName: 'Qurbay City Express',
      model: 'Ashok Leyland Viking BS-VI 222"',
      capacity: '48 Seats + 15 Standing (63 Total)',
      depot: 'Gandhipuram Central Depot — Bay 4',
      qrCodePayload: 'QURBAY:BUS:1102:TN38N2841:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 180)),
      associatedRouteNumber: '111',
    ),
    BusModel(
      busNumber: 'BUS-1120',
      registrationNumber: 'TN 38 AS 9012',
      busName: 'Qurbay Metro Link',
      model: 'Tata Marcopolo Ultra 44-Seater BS-VI',
      capacity: '44 Seats + 12 Standing (56 Total)',
      depot: 'Gandhipuram North Depot — Bay 2',
      qrCodePayload: 'QURBAY:BUS:1120:TN38AS9012:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 120)),
      associatedRouteNumber: '112',
      activeConductorId: 'C-4412', // Currently linked to another conductor
    ),
    BusModel(
      busNumber: 'BUS-2204',
      registrationNumber: 'TN 38 AF 4829',
      busName: 'Qurbay IT Corridor Shuttle',
      model: 'Ashok Leyland Falcon 210 HP',
      capacity: '45 Seats + 15 Standing (60 Total)',
      depot: 'Railway Junction Depot — Bay 7',
      qrCodePayload: 'QURBAY:BUS:2204:TN38AF4829:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 90)),
      associatedRouteNumber: '22B',
    ),
    BusModel(
      busNumber: 'BUS-5011',
      registrationNumber: 'TN 38 BG 1029',
      busName: 'Qurbay Industrial Link',
      model: 'Eicher Skyline Pro 3009L',
      capacity: '40 Seats + 10 Standing (50 Total)',
      depot: 'Singanallur Depot — Bay 3',
      qrCodePayload: 'QURBAY:BUS:5011:TN38BG1029:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 200)),
      associatedRouteNumber: '5C',
    ),
    BusModel(
      busNumber: 'BUS-SPL-99',
      registrationNumber: 'TN 38 SPL 9901',
      busName: 'Special Event Superfast',
      model: 'Volvo B8R City Transit Coach (AC)',
      capacity: '52 Seats + 20 Standing (72 Total)',
      depot: 'Central Regional Fleet Depot',
      qrCodePayload: 'QURBAY:BUS:SPL99:TN38SPL9901:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 365)),
      associatedRouteNumber: 'SPL',
    ),
    // Test Expired QR Code
    BusModel(
      busNumber: 'BUS-EXP-01',
      registrationNumber: 'TN 38 EX 0001',
      busName: 'Decommissioned Transit Coach',
      model: 'Legacy Tata 1613 CityBus',
      capacity: '42 Seats + 10 Standing',
      depot: 'South Maintenance Yard',
      qrCodePayload: 'QURBAY:BUS:EXP01:EXPIRED',
      status: BusStatus.expired,
      validUntil: DateTime.now().subtract(const Duration(days: 15)),
      associatedRouteNumber: 'EXP',
    ),
    // Test Maintenance Bus
    BusModel(
      busNumber: 'BUS-MNT-02',
      registrationNumber: 'TN 38 MN 0002',
      busName: 'Fleet Service Unit',
      model: 'Ashok Leyland BS-IV (Under Repair)',
      capacity: '40 Seats',
      depot: 'Depot Repair Workshop',
      qrCodePayload: 'QURBAY:BUS:MNT02:MAINTENANCE',
      status: BusStatus.maintenance,
      validUntil: DateTime.now().add(const Duration(days: 10)),
      associatedRouteNumber: 'MNT',
    ),
  ];

  static bool simulateNetworkError = false;

  static List<BusModel> getAvailableFleet() {
    return _fleetDatabase.where((bus) => bus.status == BusStatus.active).toList();
  }

  static List<BusModel> getBusesForRoute(String routeNumber) {
    return _fleetDatabase
        .where((bus) => bus.associatedRouteNumber == routeNumber && bus.status == BusStatus.active)
        .toList();
  }

  static BusModel? getAssignedBusForRoute(String routeNumber) {
    try {
      return _fleetDatabase.firstWhere(
        (bus) => bus.associatedRouteNumber == routeNumber && bus.status == BusStatus.active,
      );
    } catch (_) {
      return _fleetDatabase.isNotEmpty ? _fleetDatabase.first : null;
    }
  }

  /// Asynchronous validation simulating server roundtrip, latency, and route verification
  static Future<BusValidationResult> validateQrCodeAsync(
    String rawPayload, {
    String? targetRouteNumber,
    String? currentConductorId,
  }) async {
    // Simulate backend network latency (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    if (simulateNetworkError) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_network_msg'),
        errorDetails: 'Could not connect to Fleet Central Server. Check your internet connection or use cached sync.',
        errorType: BusValidationErrorType.networkError,
      );
    }

    return validateQrCode(
      rawPayload,
      targetRouteNumber: targetRouteNumber,
      currentConductorId: currentConductorId,
    );
  }

  static BusValidationResult validateQrCode(
    String rawPayload, {
    String? targetRouteNumber,
    String? currentConductorId,
  }) {
    final cleanPayload = rawPayload.trim();
    if (cleanPayload.isEmpty) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_invalid_format_msg'),
        errorDetails: 'Empty QR code detected. Please scan a valid bus QR code sticker.',
        errorType: BusValidationErrorType.invalidFormat,
      );
    }

    // Check if payload is JSON
    if (cleanPayload.startsWith('{') && cleanPayload.endsWith('}')) {
      try {
        final decoded = jsonDecode(cleanPayload);
        if (decoded is Map) {
          final busId = decoded['bus_id'] ?? decoded['bus_number'] ?? decoded['busNumber'];
          if (busId != null) {
            return lookupBusManually(
              busId.toString(),
              targetRouteNumber: targetRouteNumber,
              currentConductorId: currentConductorId,
            );
          }
        }
      } catch (_) {
        // Fall through
      }
    }

    // Direct lookup by standard payload format or bus identifiers
    final normalized = cleanPayload.toUpperCase().replaceAll(' ', '').replaceAll('-', '');

    BusModel? matchedBus;
    for (final bus in _fleetDatabase) {
      final busNormalizedNo = bus.busNumber.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      final busNormalizedReg = bus.registrationNumber.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      final busNormalizedQR = bus.qrCodePayload.toUpperCase().replaceAll(' ', '').replaceAll('-', '');

      if (normalized == busNormalizedQR ||
          normalized == busNormalizedNo ||
          normalized == busNormalizedReg ||
          normalized.contains(busNormalizedNo) ||
          normalized.contains(busNormalizedReg) ||
          cleanPayload.contains(bus.busNumber) ||
          cleanPayload.contains(bus.registrationNumber)) {
        matchedBus = bus;
        break;
      }
    }

    if (matchedBus != null) {
      return _evaluateBusStatusAndRoute(
        matchedBus,
        targetRouteNumber: targetRouteNumber,
        currentConductorId: currentConductorId,
      );
    }

    // Check for explicit test error triggers in payload
    if (normalized.contains('EXPIRED') || normalized.contains('EXP')) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_expired_msg'),
        errorDetails: 'The scanned Bus QR code certificate has expired. QR tags must be renewed before departure.',
        errorType: BusValidationErrorType.expired,
      );
    }

    if (normalized.contains('MAINTENANCE') || normalized.contains('REPAIR')) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_maintenance_msg'),
        errorDetails: 'This bus is currently marked as Under Maintenance in the Fleet Database.',
        errorType: BusValidationErrorType.underMaintenance,
      );
    }

    // If payload has a custom route match (e.g. conductor scans a valid special route token)
    if (targetRouteNumber != null && targetRouteNumber.isNotEmpty) {
      final cleanTarget = targetRouteNumber.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      if (normalized.contains(cleanTarget)) {
        final matchedSpecialBus = _fleetDatabase.firstWhere(
          (b) => b.associatedRouteNumber == targetRouteNumber && b.status == BusStatus.active,
          orElse: () => generateSpecialEventBus(
            routeNumber: targetRouteNumber,
            customBusNumber: 'BUS-${targetRouteNumber.replaceAll(RegExp(r'[^A-Z0-9]'), '')}',
          ),
        );
        return _evaluateBusStatusAndRoute(
          matchedSpecialBus,
          targetRouteNumber: targetRouteNumber,
          currentConductorId: currentConductorId,
        );
      }
    }

    // Unrecognized QR code
    return BusValidationResult.failure(
      errorMessage: TranslationService.translate('error_not_found_msg'),
      errorDetails: 'Unrecognized Bus QR code. The scanned QR is not registered in the transit database.',
      errorType: BusValidationErrorType.notFound,
    );
  }

  static Future<BusValidationResult> lookupBusManuallyAsync(
    String query, {
    String? targetRouteNumber,
    String? currentConductorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return lookupBusManually(
      query,
      targetRouteNumber: targetRouteNumber,
      currentConductorId: currentConductorId,
    );
  }

  static BusValidationResult lookupBusManually(
    String query, {
    String? targetRouteNumber,
    String? currentConductorId,
  }) {
    final cleanQuery = query.trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '');
    if (cleanQuery.isEmpty) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_invalid_format_msg'),
        errorDetails: 'Please enter a bus number or registration number.',
        errorType: BusValidationErrorType.invalidFormat,
      );
    }

    for (final bus in _fleetDatabase) {
      final busNo = bus.busNumber.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      final busReg = bus.registrationNumber.toUpperCase().replaceAll(' ', '').replaceAll('-', '');

      if (busNo == cleanQuery ||
          busReg == cleanQuery ||
          busNo.contains(cleanQuery) ||
          busReg.contains(cleanQuery) ||
          cleanQuery.contains(busNo) ||
          cleanQuery.contains(busReg)) {
        return _evaluateBusStatusAndRoute(
          bus,
          targetRouteNumber: targetRouteNumber,
          currentConductorId: currentConductorId,
        );
      }
    }

    // Check if query corresponds to a route number (e.g. "111", "112", "22B", "5C")
    for (final bus in _fleetDatabase) {
      if (bus.associatedRouteNumber != null) {
        final routeClean = bus.associatedRouteNumber!.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
        if (routeClean == cleanQuery) {
          return _evaluateBusStatusAndRoute(
            bus,
            targetRouteNumber: targetRouteNumber,
            currentConductorId: currentConductorId,
          );
        }
      }
    }

    // Dynamic creation for custom special route numbers if entered with valid format
    if (cleanQuery.length >= 3) {
      final customBus = generateSpecialEventBus(
        routeNumber: query.toUpperCase(),
        customBusNumber: 'BUS-${query.toUpperCase()}',
      );
      return _evaluateBusStatusAndRoute(
        customBus,
        targetRouteNumber: targetRouteNumber,
        currentConductorId: currentConductorId,
      );
    }

    return BusValidationResult.failure(
      errorMessage: TranslationService.translate('error_not_found_msg'),
      errorDetails: 'No bus found matching the entered bus or registration number.',
      errorType: BusValidationErrorType.notFound,
    );
  }

  static BusValidationResult _evaluateBusStatusAndRoute(
    BusModel bus, {
    String? targetRouteNumber,
    String? currentConductorId,
  }) {
    // 1. Check expiration
    if (bus.status == BusStatus.expired || DateTime.now().isAfter(bus.validUntil)) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_expired_msg'),
        errorDetails: 'Bus QR Code for ${bus.busNumber} (${bus.registrationNumber}) is expired.',
        errorType: BusValidationErrorType.expired,
        bus: bus,
      );
    }

    // 2. Check maintenance
    if (bus.status == BusStatus.maintenance) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_maintenance_msg'),
        errorDetails: 'Bus ${bus.busNumber} (${bus.registrationNumber}) is currently Under Maintenance.',
        errorType: BusValidationErrorType.underMaintenance,
        bus: bus,
      );
    }

    // 3. Check if already linked to another conductor (only if conductor context is provided)
    if (currentConductorId != null &&
        bus.activeConductorId != null &&
        bus.activeConductorId!.isNotEmpty &&
        bus.activeConductorId != currentConductorId) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_already_linked_msg'),
        errorDetails: 'Bus ${bus.busNumber} (${bus.registrationNumber}) is currently linked to Conductor ${bus.activeConductorId}.',
        errorType: BusValidationErrorType.alreadyLinked,
        bus: bus,
        activeConductorId: bus.activeConductorId,
      );
    }

    // 4. Check route compatibility if target route is provided
    if (targetRouteNumber != null &&
        targetRouteNumber.isNotEmpty &&
        bus.associatedRouteNumber != null &&
        bus.associatedRouteNumber != 'SPL' &&
        bus.associatedRouteNumber != targetRouteNumber) {
      return BusValidationResult.failure(
        errorMessage: TranslationService.translate('error_wrong_route_msg'),
        errorDetails: 'Bus ${bus.busNumber} is assigned to Route ${bus.associatedRouteNumber}, but you selected Route $targetRouteNumber.',
        errorType: BusValidationErrorType.wrongRoute,
        bus: bus,
        assignedRouteNumber: bus.associatedRouteNumber,
      );
    }

    return BusValidationResult.success(bus);
  }

  static BusModel generateSpecialEventBus({
    required String routeNumber,
    String? customBusNumber,
  }) {
    final busNo = customBusNumber ?? 'BUS-${routeNumber.toUpperCase()}-01';
    final regNo = 'TN 38 SP ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final newBus = BusModel(
      busNumber: busNo,
      registrationNumber: regNo,
      busName: 'Special Transit Bus ($routeNumber)',
      model: 'Ashok Leyland Viking BS-VI Super Coach',
      capacity: '48 Seats + 15 Standing (63 Total)',
      depot: 'Central Regional Fleet Depot',
      qrCodePayload: 'QURBAY:BUS:$busNo:$regNo:ACTIVE',
      status: BusStatus.active,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      associatedRouteNumber: routeNumber,
    );

    _fleetDatabase.add(newBus);
    return newBus;
  }
}
