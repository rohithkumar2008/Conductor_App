import 'bus_model.dart';
import 'route_model.dart';

/// Comprehensive workflow states for bus linking lifecycle
enum LinkingWorkflowStep {
  routeSelected,
  confirmationPending,
  scanningActive,
  validating,
  validationSuccess,
  validationFailed,
  busLinked,
}


/// Direction of the bus route trip
enum TripDirection {
  outbound,
  inbound,
}

extension TripDirectionExtension on TripDirection {
  String get label => this == TripDirection.outbound ? 'Outbound' : 'Inbound';
  String get tamilLabel => this == TripDirection.outbound ? 'வெளிச்செல்லும் பயணம்' : 'உள்வரும் பயணம்';
}

/// Request payload for validating a bus QR code
class BusValidationRequest {
  final String qrPayload;
  final String selectedRouteNumber;
  final TripDirection direction;
  final String conductorId;
  final DateTime timestamp;

  BusValidationRequest({
    required this.qrPayload,
    required this.selectedRouteNumber,
    this.direction = TripDirection.outbound,
    required this.conductorId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'qr_payload': qrPayload,
        'selected_route_number': selectedRouteNumber,
        'direction': direction.name.toUpperCase(),
        'conductor_id': conductorId,
        'device_timestamp': timestamp.toIso8601String(),
      };
}

/// Response model from the bus validation service / backend
class BusValidationResponse {
  final bool isValid;
  final BusModel? bus;
  final RouteModel? route;
  final String? errorMessage;
  final String? errorDetails;
  final BusValidationErrorType? errorType;
  final String? activeConductorId;
  final String? assignedRouteNumber;
  final bool isOfflineCached;

  const BusValidationResponse.success({
    required this.bus,
    this.route,
    this.isOfflineCached = false,
  })  : isValid = true,
        errorMessage = null,
        errorDetails = null,
        errorType = null,
        activeConductorId = null,
        assignedRouteNumber = null;

  const BusValidationResponse.failure({
    required this.errorMessage,
    required this.errorType,
    this.errorDetails,
    this.bus,
    this.activeConductorId,
    this.assignedRouteNumber,
    this.isOfflineCached = false,
  })  : isValid = false,
        route = null;
}
