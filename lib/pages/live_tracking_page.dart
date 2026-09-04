import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/route_model.dart';
import 'route_confirmation_page.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';
import '../widgets/lively_bottom_nav_bar.dart';
import '../widgets/lively_bus_map_widget.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  late RouteModel _activeRoute;
  late List<RouteStop> _stops;
  bool _isAutoTracking = false;
  Timer? _autoTrackingTimer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _activeRoute = TripService.selectedRouteModel.value;
    _stops = _buildCurrentTripStops();

    int initialPage = _stops.indexWhere((s) => !s.isCompleted);
    if (initialPage == -1) initialPage = _stops.length - 1;
    if (initialPage > 0) initialPage -= 1;

    _pageController = PageController(
      viewportFraction: 0.48,
      initialPage: initialPage >= 0 ? initialPage : 0,
    );
  }

  @override
  void dispose() {
    _autoTrackingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<RouteStop> _buildCurrentTripStops() {
    final rawStops = _activeRoute.stops;
    List<RouteStop> list = rawStops.map((s) => s.copyWith()).toList();

    if (TripService.isReversed.value) {
      list = list.reversed.toList();
      final now = DateTime.now();
      for (int i = 0; i < list.length; i++) {
        if (i == 0) {
          list[i].isCompleted = true;
          final timeStr =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          list[i].time = TranslationService.currentLanguage == 'ta'
              ? 'கடந்த நேரம் $timeStr'
              : 'Passed Time $timeStr';
        } else {
          list[i].isCompleted = false;
          final expTime = now.add(Duration(minutes: i * 15));
          final expStr =
              "${expTime.hour.toString().padLeft(2, '0')}:${expTime.minute.toString().padLeft(2, '0')}";
          list[i].time = TranslationService.currentLanguage == 'ta'
              ? 'எதிர்பார்க்கப்படும் நேரம் $expStr'
              : 'Expected $expStr';
        }
      }
    }
    return list;
  }

  void _syncActiveRoute(RouteModel route) {
    setState(() {
      _activeRoute = route;
      _stops = _buildCurrentTripStops();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerToCurrentStop();
    });
  }

  void _centerToCurrentStop() {
    int nextUncompleted = _stops.indexWhere((stop) => !stop.isCompleted);
    int targetPage = nextUncompleted != -1 ? nextUncompleted : _stops.length - 1;

    if (mounted && _pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _startAutoTracking() {
    setState(() {
      _isAutoTracking = true;
    });
    _autoTrackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextIndex = _stops.indexWhere((stop) => !stop.isCompleted);
      if (nextIndex != -1) {
        HapticFeedback.lightImpact();
        setState(() {
          _stops[nextIndex].isCompleted = true;
          final now = DateTime.now();
          final timeStr =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          _stops[nextIndex].time = TranslationService.currentLanguage == 'ta'
              ? 'கடந்த நேரம் $timeStr'
              : 'Passed Time $timeStr';
        });

        // Automatically move to the next upcoming stop one by one
        int targetScrollIndex = nextIndex + 1 < _stops.length ? nextIndex + 1 : nextIndex;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetScrollIndex,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
          );
        }

        if (nextIndex == _stops.length - 1) {
          _stopAutoTracking();
          _showNextTripDialog();
        }
      } else {
        _stopAutoTracking();
        _showNextTripDialog();
      }
    });
  }

  void _stopAutoTracking() {
    setState(() {
      _isAutoTracking = false;
      _autoTrackingTimer?.cancel();
      _autoTrackingTimer = null;
    });
  }

  void _onStopTapped(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      final now = DateTime.now();
      for (int i = 0; i < _stops.length; i++) {
        if (i <= index) {
          if (!_stops[i].isCompleted) {
            _stops[i].isCompleted = true;
            final timeStr =
                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
            _stops[i].time = TranslationService.currentLanguage == 'ta'
                ? 'கடந்த நேரம் $timeStr'
                : 'Passed Time $timeStr';
          }
        } else {
          _stops[i].isCompleted = false;
          final expTime = now.add(Duration(minutes: (i - index) * 15));
          final expStr =
              "${expTime.hour.toString().padLeft(2, '0')}:${expTime.minute.toString().padLeft(2, '0')}";
          _stops[i].time = TranslationService.currentLanguage == 'ta'
              ? 'எதிர்பார்க்கப்படும் நேரம் $expStr'
              : 'Expected $expStr';
        }
      }
    });

    // Automatically advance and scroll forward to the next stop one by one
    int targetScrollIndex = index + 1 < _stops.length ? index + 1 : index;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetScrollIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }

    if (index == _stops.length - 1) {
      _stopAutoTracking();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNextTripDialog();
      });
    }
  }

  void _showNextTripDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('next_trip_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  TranslationService.translate('next_trip_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          TranslationService.translate('cancel'),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          TripService.toggleDirection();
                          setState(() {
                            _stops = _buildCurrentTripStops();
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _centerToCurrentStop();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B63F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(TranslationService.translate('confirm')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToBusScanner(RouteModel route) async {
    TripService.selectRoute(route);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RouteConfirmationPage(initialRoute: route),
      ),
    );

    if (result == true && mounted) {
      _syncActiveRoute(route);
    }
  }

  void _showAddSpecialRouteDialog() {
    final routeNoController = TextEditingController();
    final routeNameController = TextEditingController();
    final startPointController = TextEditingController();
    final endPointController = TextEditingController();
    String selectedValidity = 'Today (12 Hours)';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_road_rounded, color: Color(0xFF3B63F6), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationService.translate('create_special_route_title'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                TranslationService.translate('create_special_route_desc'),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Route Number Field
                    _buildInputField(
                      label: TranslationService.translate('route_number_label'),
                      hint: TranslationService.translate('route_number_hint'),
                      controller: routeNoController,
                      icon: Icons.tag,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 14),

                    // Route Name Field
                    _buildInputField(
                      label: TranslationService.translate('route_name_label'),
                      hint: TranslationService.translate('route_name_hint'),
                      controller: routeNameController,
                      icon: Icons.alt_route,
                    ),
                    const SizedBox(height: 14),

                    // Start Point & End Point
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: TranslationService.translate('start_point_label'),
                            hint: TranslationService.translate('start_point_hint'),
                            controller: startPointController,
                            icon: Icons.trip_origin,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInputField(
                            label: TranslationService.translate('end_point_label'),
                            hint: TranslationService.translate('end_point_hint'),
                            controller: endPointController,
                            icon: Icons.location_on,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Validity Period Selection
                    Text(
                      TranslationService.translate('validity_period_label'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Today (12 Hours)', '24 Hours', '3 Days (Special Event)'].map((v) {
                        final isSel = selectedValidity == v;
                        return ChoiceChip(
                          label: Text(v, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                          selected: isSel,
                          selectedColor: const Color(0xFF3B63F6),
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: BorderSide.none,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedValidity = v;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(TranslationService.translate('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final routeNo = routeNoController.text.trim();
                              final routeName = routeNameController.text.trim();
                              final start = startPointController.text.trim();
                              final end = endPointController.text.trim();

                              if (routeNo.isEmpty || start.isEmpty || end.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(TranslationService.translate('fill_required_fields')),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final newSpecialRoute = RouteModel(
                                routeNumber: routeNo.toUpperCase(),
                                routeName: routeName.isNotEmpty ? routeName : '$routeNo Express ($start — $end)',
                                startPoint: start,
                                endPoint: end,
                                isSpecial: true,
                                validityPeriod: selectedValidity,
                                frequency: 'Special Schedule',
                                colorValue: 0xFFD97706, // Warm Amber for special routes
                                stops: [
                                  RouteStop(title: start, time: 'Passed Time 14:00', isCompleted: true),
                                  RouteStop(title: 'Event Stop 1', time: 'Expected 14:15', isCompleted: false),
                                  RouteStop(title: 'Event Stop 2', time: 'Expected 14:30', isCompleted: false),
                                  RouteStop(title: end, time: 'Expected 14:45', isCompleted: false),
                                ],
                              );

                              TripService.addSpecialRoute(newSpecialRoute);
                              Navigator.of(dialogContext).pop();

                              // Automatically launch bus QR scanner for this new route
                              _navigateToBusScanner(newSpecialRoute);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF3B63F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              TranslationService.translate('create_and_proceed'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF3B63F6)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF3B63F6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showBusInfoBottomSheet() {
    final busNum = TripService.currentBusNumber.value ?? 'BUS-1102';
    final busName = TripService.currentBusName.value ?? 'Qurbay Transit Bus';
    final reg = TripService.currentRegistration.value ?? 'TN 38 AS 9012';
    final model = TripService.currentBusModel.value ?? 'Ashok Leyland Viking BS-VI';
    final capacity = TripService.currentCapacity.value ?? '48 Seats + 15 Standing';
    final depot = TripService.currentDepot.value ?? 'Gandhipuram Central Depot';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text(
                          TranslationService.translate('sync_active'),
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Bus Number', busNum, isBold: true),
                    const Divider(height: 16),
                    _buildModalRow('Registration', reg),
                    const Divider(height: 16),
                    _buildModalRow('Model', model),
                    const Divider(height: 16),
                    _buildModalRow('Capacity', capacity),
                    const Divider(height: 16),
                    _buildModalRow('Depot', depot),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        TripService.unlinkBus();
                        setState(() {});
                      },
                      icon: const Icon(Icons.link_off_rounded, color: Colors.red),
                      label: Text(
                        TranslationService.translate('unlink_bus'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToBusScanner(_activeRoute);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(TranslationService.translate('switch_bus')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF3B63F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF3B63F6) : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: TripService.isBusLinked,
          builder: (context, isLinked, child) {
            if (!isLinked) {
              return _buildRouteSelectionView();
            }
            return _buildActiveTrackingView();
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── ROUTE SELECTION VIEW (Large 2-per-row Circular Grey Buttons) ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildRouteSelectionView() {
    return ValueListenableBuilder<List<RouteModel>>(
      valueListenable: TripService.availableRoutes,
      builder: (context, allRoutes, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: "Live Map" & Conductor Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TranslationService.translate('live_map'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Conductor Profile Button (Interactive with Dialog)
                  TactileButton(
                    onTap: () => _showConductorProfileDialog(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.black87, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Section Subheader: Choose Bus Route, count & guidance subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationService.translate('select_route_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${allRoutes.length} available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TranslationService.translate('select_route_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Circular Grey Route Buttons (Exactly 2 Buttons Per Row) ──
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: allRoutes.length + 1,
                itemBuilder: (context, index) {
                  if (index < allRoutes.length) {
                    return _buildCircularGreyRouteButton(allRoutes[index]);
                  } else {
                    return _buildCircularGreyAddRouteButton();
                  }
                },
              ),
            ),

            // Navigation Bar
            const LivelyBottomNavBar(currentIndex: 1),
          ],
        );
      },
    );
  }

  /// Circular grey route button with refined balanced dimensions (134x134)
  Widget _buildCircularGreyRouteButton(RouteModel route) {
    return TactileButton(
      onTap: () => _navigateToBusScanner(route),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 134,
            maxHeight: 134,
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF1F5F9),
                    Color(0xFFE2E8F0),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.13),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 2,
                    spreadRadius: 1,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      route.routeNumber,
                      style: TextStyle(
                        fontSize: route.routeNumber.length > 3 ? 21 : 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (route.isSpecial)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'SPECIAL',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ROUTE',
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circular grey '+ Add Route' button with balanced proportions (134x134)
  Widget _buildCircularGreyAddRouteButton() {
    return TactileButton(
      onTap: _showAddSpecialRouteDialog,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 134,
            maxHeight: 134,
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF1F5F9),
                    Color(0xFFE2E8F0),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF94A3B8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 2,
                    spreadRadius: 1,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 40,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Add Route',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the Conductor Profile / Account Info Modal
  void _showConductorProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF3B63F6),
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('conductor_details'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildProfileDialogRow(TranslationService.translate('conductor_name'), 'Ramesh Kumar'),
                _buildProfileDialogRow(TranslationService.translate('age'), '38'),
                _buildProfileDialogRow(TranslationService.translate('gender'), TranslationService.translate('male')),
                _buildProfileDialogRow(TranslationService.translate('employee_id'), TripService.conductorId),
                _buildProfileDialogRow(TranslationService.translate('assigned_route'), TripService.currentRoute.value),
                _buildProfileDialogRow(TranslationService.translate('license_no'), 'DL-TN38-2015-8490'),
                _buildProfileDialogRow(TranslationService.translate('phone_no'), '+91 98453 10482'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B63F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      TranslationService.translate('close_details'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── ACTIVE TRACKING VIEW (When Bus is Connected & Synchronized) ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildActiveTrackingView() {
    final busNum = TripService.currentBusNumber.value ?? 'BUS-1102';
    final regNum = TripService.currentRegistration.value ?? 'TN 38 N 2841';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Route and summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${TranslationService.translate('route_no_label')}: ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TactileButton(
                          onTap: () {
                            TripService.unlinkBus();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(_activeRoute.colorValue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _activeRoute.routeNumber,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TripService.isReversed.value
                          ? '${_activeRoute.endPoint} ➔ ${_activeRoute.startPoint}'
                          : '${_activeRoute.startPoint} ➔ ${_activeRoute.endPoint}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Bus connection status badge with pulsing green light
              TactileButton(
                onTap: _showBusInfoBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            busNum,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            TranslationService.translate('live_synced'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Map Container with Stops Timeline ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEAEAEA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationService.translate('live_map'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // Auto-tracking Play/Pause button
                        TactileButton(
                          onTap: () {
                            if (_isAutoTracking) {
                              _stopAutoTracking();
                            } else {
                              _startAutoTracking();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isAutoTracking ? Colors.green : const Color(0xFF3B63F6),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isAutoTracking ? Colors.green : const Color(0xFF3B63F6))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isAutoTracking ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAutoTracking
                                      ? TranslationService.translate('stop_auto')
                                      : TranslationService.translate('start_auto'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Linked Bus: $regNum • ${TripService.conductorId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stops Node Cards Timeline (Fixed Height 96px)
                    Container(
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PageView.builder(
                        physics: const BouncingScrollPhysics(),
                        controller: _pageController,
                        itemCount: _stops.length,
                        itemBuilder: (context, index) {
                          return _buildRouteNode(index);
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Lively Animated Live Map View Canvas
                    Expanded(
                      child: LivelyBusMapWidget(
                        stops: _stops,
                        activeStopIndex: _stops.indexWhere((s) => !s.isCompleted) == -1
                            ? _stops.length - 1
                            : _stops.indexWhere((s) => !s.isCompleted),
                        isAutoTracking: _isAutoTracking,
                        onStopConfirmed: _onStopTapped,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Navigation Bar
        const LivelyBottomNavBar(currentIndex: 1),
      ],
    );
  }

  Widget _buildRouteNode(int index) {
    final stop = _stops[index];
    final bool isCompleted = stop.isCompleted;
    final int firstUncompletedIndex = _stops.indexWhere((s) => !s.isCompleted);
    final bool isActive = (firstUncompletedIndex == index);
    final String title = stop.title;
    final String time = stop.time;

    final Color leftLineColor = index == 0
        ? Colors.transparent
        : (isCompleted ? const Color(0xFF10B981) : Colors.grey.shade400);

    final Color rightLineColor = index == _stops.length - 1
        ? Colors.transparent
        : ((index < _stops.length - 1 && _stops[index + 1].isCompleted)
            ? const Color(0xFF10B981)
            : Colors.grey.shade400);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 11,
          left: 0,
          right: 0,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3.5,
                  color: leftLineColor,
                ),
              ),
              Expanded(
                child: Container(
                  height: 3.5,
                  color: rightLineColor,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _onStopTapped(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isActive ? Colors.white : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (isActive ? const Color(0xFF3B63F6) : const Color(0xFF1E3A8A)),
                    width: isActive ? 3.5 : 2.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B63F6).withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Center(
                        child: Container(
                          width: isActive ? 10 : 8,
                          height: isActive ? 10 : 8,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF3B63F6) : const Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                  color: isActive ? const Color(0xFF0F172A) : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                time,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.grey.shade700
                      : (isActive ? const Color(0xFF3B63F6) : Colors.black54),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tactile Button (Apple Design: Instant response on pointer-down, spring physics & haptics) ──
class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TactileButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
