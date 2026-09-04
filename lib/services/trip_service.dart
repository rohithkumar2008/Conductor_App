import 'package:flutter/material.dart';
import '../models/bus_linking_state.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import 'bus_database_service.dart';

class TripService {
  static final ValueNotifier<String> currentRoute = ValueNotifier<String>('111');
  static final ValueNotifier<String> currentTripId = ValueNotifier<String>('TRIP-101');
  static final ValueNotifier<bool> isReversed = ValueNotifier<bool>(false);

  static final ValueNotifier<String?> currentBusNumber = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentBusName = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentRegistration = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentBusModel = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentCapacity = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentDepot = ValueNotifier<String?>(null);
  static final ValueNotifier<bool> isBusLinked = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier<DateTime?>(null);

  // Workflow tracking
  static final ValueNotifier<LinkingWorkflowStep> workflowStep =
      ValueNotifier<LinkingWorkflowStep>(LinkingWorkflowStep.routeSelected);
  static final ValueNotifier<BusModel?> preSelectedBus = ValueNotifier<BusModel?>(null);

  static final ValueNotifier<List<RouteModel>> availableRoutes =
      ValueNotifier<List<RouteModel>>(RouteModel.getDefaultRoutes());

  static final ValueNotifier<RouteModel> selectedRouteModel =
      ValueNotifier<RouteModel>(RouteModel.getDefaultRoutes().first);

  static String conductorId = 'C-8902';

  static void setTripDetails(String route, String tripId) {
    currentRoute.value = route;
    currentTripId.value = tripId;
    isReversed.value = false;

    // Sync with selectedRouteModel if match found
    for (final r in availableRoutes.value) {
      if (r.routeNumber == route) {
        selectedRouteModel.value = r;
        preSelectedBus.value = BusDatabaseService.getAssignedBusForRoute(r.routeNumber);
        break;
      }
    }
  }

  static void selectRoute(RouteModel route) {
    selectedRouteModel.value = route;
    currentRoute.value = route.routeNumber;
    isReversed.value = false;
    preSelectedBus.value = BusDatabaseService.getAssignedBusForRoute(route.routeNumber);
    workflowStep.value = LinkingWorkflowStep.confirmationPending;
  }

  static void setPreSelectedBus(BusModel? bus) {
    preSelectedBus.value = bus;
  }

  static void addSpecialRoute(RouteModel newRoute) {
    final updatedList = List<RouteModel>.from(availableRoutes.value);
    updatedList.insert(0, newRoute);
    availableRoutes.value = updatedList;
    selectedRouteModel.value = newRoute;
    currentRoute.value = newRoute.routeNumber;
    isReversed.value = false;
    preSelectedBus.value = BusDatabaseService.getAssignedBusForRoute(newRoute.routeNumber);
    workflowStep.value = LinkingWorkflowStep.confirmationPending;
  }

  static void toggleDirection() {
    isReversed.value = !isReversed.value;
  }

  static void linkBusWithDetails(BusModel bus, RouteModel route) {
    currentBusNumber.value = bus.busNumber;
    currentBusName.value = bus.busName;
    currentRegistration.value = bus.registrationNumber;
    currentBusModel.value = bus.model;
    currentCapacity.value = bus.capacity;
    currentDepot.value = bus.depot;

    selectedRouteModel.value = route;
    currentRoute.value = route.routeNumber;
    isBusLinked.value = true;
    lastSyncTime.value = DateTime.now();
    workflowStep.value = LinkingWorkflowStep.busLinked;
  }

  /// Legacy helper method for compatibility
  static void linkBus(String busNum, String busName, String route) {
    currentBusNumber.value = busNum;
    currentBusName.value = busName;
    currentRegistration.value = 'TN 38 AS 9012';
    currentBusModel.value = 'Ashok Leyland Viking BS-VI';
    currentCapacity.value = '48 Seats + 15 Standing';
    currentDepot.value = 'Gandhipuram Central Depot';
    currentRoute.value = route;
    isBusLinked.value = true;
    lastSyncTime.value = DateTime.now();
    workflowStep.value = LinkingWorkflowStep.busLinked;
  }

  static void unlinkBus() {
    currentBusNumber.value = null;
    currentBusName.value = null;
    currentRegistration.value = null;
    currentBusModel.value = null;
    currentCapacity.value = null;
    currentDepot.value = null;
    isBusLinked.value = false;
    lastSyncTime.value = null;
    workflowStep.value = LinkingWorkflowStep.routeSelected;
  }
}
