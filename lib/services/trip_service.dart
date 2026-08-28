import 'package:flutter/material.dart';

class TripService {
  static final ValueNotifier<String> currentRoute = ValueNotifier<String>('111A');
  static final ValueNotifier<String> currentTripId = ValueNotifier<String>('TRIP-101');
  static final ValueNotifier<bool> isReversed = ValueNotifier<bool>(false);
  
  static final ValueNotifier<String?> currentBusNumber = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentBusName = ValueNotifier<String?>(null);
  
  static String conductorId = 'C-8902';

  static void setTripDetails(String route, String tripId) {
    currentRoute.value = route;
    currentTripId.value = tripId;
    isReversed.value = false;
  }

  static void toggleDirection() {
    isReversed.value = !isReversed.value;
  }

  static void linkBus(String busNum, String busName, String route) {
    currentBusNumber.value = busNum;
    currentBusName.value = busName;
    currentRoute.value = route;
    isReversed.value = false;
  }
}
