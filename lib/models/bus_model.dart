enum BusStatus {
  active,
  expired,
  maintenance,
}

enum BusValidationErrorType {
  invalidFormat,
  notFound,
  expired,
  underMaintenance,
  wrongRoute,
  alreadyLinked,
  networkError,
}

class BusModel {
  final String busNumber;
  final String registrationNumber;
  final String busName;
  final String model;
  final String capacity;
  final String depot;
  final String qrCodePayload;
  final BusStatus status;
  final DateTime validUntil;
  final String? associatedRouteNumber;
  final String? activeConductorId;

  const BusModel({
    required this.busNumber,
    required this.registrationNumber,
    required this.busName,
    required this.model,
    required this.capacity,
    required this.depot,
    required this.qrCodePayload,
    this.status = BusStatus.active,
    required this.validUntil,
    this.associatedRouteNumber,
    this.activeConductorId,
  });

  bool get isExpired => DateTime.now().isAfter(validUntil) || status == BusStatus.expired;
  bool get isValid => status == BusStatus.active && !isExpired;
  bool get isAssignedToOtherConductor => activeConductorId != null && activeConductorId!.isNotEmpty;

  BusModel copyWith({
    String? busNumber,
    String? registrationNumber,
    String? busName,
    String? model,
    String? capacity,
    String? depot,
    String? qrCodePayload,
    BusStatus? status,
    DateTime? validUntil,
    String? associatedRouteNumber,
    String? activeConductorId,
  }) {
    return BusModel(
      busNumber: busNumber ?? this.busNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      busName: busName ?? this.busName,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      depot: depot ?? this.depot,
      qrCodePayload: qrCodePayload ?? this.qrCodePayload,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
      associatedRouteNumber: associatedRouteNumber ?? this.associatedRouteNumber,
      activeConductorId: activeConductorId ?? this.activeConductorId,
    );
  }
}

class BusValidationResult {
  final bool isValid;
  final BusModel? bus;
  final String? errorMessage;
  final String? errorDetails;
  final BusValidationErrorType? errorType;
  final String? activeConductorId;
  final String? assignedRouteNumber;
  final bool isOfflineCached;

  const BusValidationResult.success(this.bus, {this.isOfflineCached = false})
      : isValid = true,
        errorMessage = null,
        errorDetails = null,
        errorType = null,
        activeConductorId = null,
        assignedRouteNumber = null;

  const BusValidationResult.failure({
    required this.errorMessage,
    required this.errorType,
    this.errorDetails,
    this.bus,
    this.activeConductorId,
    this.assignedRouteNumber,
    this.isOfflineCached = false,
  })  : isValid = false;
}
