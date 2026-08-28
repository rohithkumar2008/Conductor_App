import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;
import 'dart:async';
import 'home_page.dart';
import 'settings_page.dart';
import 'passenger_count_page.dart';
import 'scanner_page.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  String _selectedRoute = '111A';
  bool _isAutoTracking = false;
  Timer? _autoTrackingTimer;

  // Routes configuration
  final Map<String, List<Map<String, dynamic>>> _routesData = {
    '111A': [
      {'title': 'Gandipuram', 'time': 'Passed Time 12:21', 'isCompleted': true},
      {'title': 'Ganapathy', 'time': 'Passed Time 12:44', 'isCompleted': true},
      {'title': 'CMS', 'time': 'Passed Time 12:48', 'isCompleted': true},
      {'title': 'Bharithi Nagar', 'time': 'Passed Time 12:50', 'isCompleted': true},
      {'title': 'RamaKrishana Mill', 'time': 'Passed Time 12:55', 'isCompleted': true},
      {'title': 'Prozone Mall', 'time': 'Passed Time 13:05', 'isCompleted': true},
      {'title': 'Saravanampatti', 'time': 'Expected 13:15', 'isCompleted': false},
      {'title': 'KGISL Campus', 'time': 'Expected 13:45', 'isCompleted': false},
      {'title': 'Thudiyalur', 'time': 'Expected 13:40', 'isCompleted': false},
    ],
    '22B': [
      {'title': 'Railway Station', 'time': 'Passed Time 14:02', 'isCompleted': true},
      {'title': 'Sathy Road', 'time': 'Passed Time 14:15', 'isCompleted': true},
      {'title': 'Saravanampatti', 'time': 'Passed Time 14:30', 'isCompleted': true},
      {'title': 'CHIL SEZ', 'time': 'Expected 14:45', 'isCompleted': false},
      {'title': 'Keeranatham', 'time': 'Expected 15:00', 'isCompleted': false},
    ],
    '5C': [
      {'title': 'Singanallur', 'time': 'Passed Time 08:30', 'isCompleted': true},
      {'title': 'Hope College', 'time': 'Passed Time 08:45', 'isCompleted': true},
      {'title': 'Peelamedu', 'time': 'Passed Time 09:00', 'isCompleted': true},
      {'title': 'Gandipuram', 'time': 'Expected 09:15', 'isCompleted': false},
      {'title': 'Railway Station', 'time': 'Expected 09:30', 'isCompleted': false},
    ],
  };

  late List<Map<String, dynamic>> stops;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Load current route key from TripService
    _selectedRoute = TripService.currentRoute.value;
    
    // Load stops taking reversed trip direction into account
    stops = _getRouteStopsForCurrentTrip();

    // Find the first incomplete stop to show it in the center initially
    int initialPage = stops.indexWhere((stop) => !stop['isCompleted']);
    if (initialPage == -1) initialPage = stops.length - 1;
    // We adjust it back by 1 so the current completed stop and the next incomplete stop are visible
    if (initialPage > 0) initialPage -= 1;
    
    _pageController = PageController(
      viewportFraction: 0.5,
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _autoTrackingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getRouteStopsForCurrentTrip() {
    final rawStops = _routesData[_selectedRoute]!;
    final List<Map<String, dynamic>> stopsList = List<Map<String, dynamic>>.from(
      rawStops.map((stop) => Map<String, dynamic>.from(stop))
    );
    
    if (TripService.isReversed.value) {
      final reversedList = stopsList.reversed.toList();
      // Since it's a return trip, first stop is marked passed, others expected
      final now = DateTime.now();
      for (int i = 0; i < reversedList.length; i++) {
        if (i == 0) {
          reversedList[i]['isCompleted'] = true;
          final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          reversedList[i]['time'] = TranslationService.currentLanguage == 'ta'
              ? 'கடந்த நேரம் $timeStr'
              : 'Passed Time $timeStr';
        } else {
          reversedList[i]['isCompleted'] = false;
          final expTime = now.add(Duration(minutes: i * 15));
          final expStr = "${expTime.hour.toString().padLeft(2, '0')}:${expTime.minute.toString().padLeft(2, '0')}";
          reversedList[i]['time'] = TranslationService.currentLanguage == 'ta'
              ? 'எதிர்பார்க்கப்படும் நேரம் $expStr'
              : 'Expected $expStr';
        }
      }
      return reversedList;
    }
    return stopsList;
  }

  String _getRouteSummary(String routeKey) {
    final isRev = TripService.isReversed.value;
    if (routeKey == '111A') {
      if (isRev) {
        return TranslationService.currentLanguage == 'ta' 
            ? 'துடியலூர் --- காடிபுரம்' 
            : 'Thudiyalur --- Gadipuram';
      } else {
        return TranslationService.currentLanguage == 'ta' 
            ? 'காடிபுரம் --- துடியலூர்' 
            : 'Gadipuram --- Thudiyalur';
      }
    } else if (routeKey == '22B') {
      if (isRev) {
        return TranslationService.currentLanguage == 'ta' 
            ? 'கீரநத்தம் --- இரயில் நிலையம்' 
            : 'Keeranatham --- Railway Station';
      } else {
        return TranslationService.currentLanguage == 'ta' 
            ? 'இரயில் நிலையம் --- கீரநத்தம்' 
            : 'Railway Station --- Keeranatham';
      }
    } else {
      if (isRev) {
        return TranslationService.currentLanguage == 'ta' 
            ? 'இரயில் நிலையம் --- சிங்கநல்லூர்' 
            : 'Railway Station --- Singanallur';
      } else {
        return TranslationService.currentLanguage == 'ta' 
            ? 'சிங்கநல்லூர் --- இரயில் நிலையம்' 
            : 'Singanallur --- Railway Station';
      }
    }
  }

  void _loadRouteStops(String routeKey) {
    setState(() {
      _selectedRoute = routeKey;
      stops = List<Map<String, dynamic>>.from(
        _routesData[routeKey]!.map((stop) => Map<String, dynamic>.from(stop))
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerToCurrentStop();
    });
  }

  void _centerToCurrentStop() {
    int initialPage = stops.indexWhere((stop) => !stop['isCompleted']);
    if (initialPage == -1) initialPage = stops.length - 1;
    if (initialPage > 0) initialPage -= 1;
    
    if (mounted && _pageController.hasClients) {
      _pageController.animateToPage(
        initialPage, 
        duration: const Duration(milliseconds: 400), 
        curve: Curves.easeInOut
      );
    }
  }

  void _startAutoTracking() {
    setState(() {
      _isAutoTracking = true;
    });
    _autoTrackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextIndex = stops.indexWhere((stop) => !stop['isCompleted']);
      if (nextIndex != -1) {
        setState(() {
          stops[nextIndex]['isCompleted'] = true;
          final now = DateTime.now();
          final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          stops[nextIndex]['time'] = TranslationService.currentLanguage == 'ta'
              ? 'கடந்த நேரம் $timeStr'
              : 'Passed Time $timeStr';
        });
        
        int page = nextIndex;
        if (page > 0) page -= 1;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            page, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut
          );
        }
        
        // Check if route is completed now
        if (nextIndex == stops.length - 1) {
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
      for (int i = 0; i < stops.length; i++) {
        if (i <= index) {
          if (!stops[i]['isCompleted']) {
            stops[i]['isCompleted'] = true;
            final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
            stops[i]['time'] = TranslationService.currentLanguage == 'ta'
                ? 'கடந்த நேரம் $timeStr'
                : 'Passed Time $timeStr';
          }
        } else {
          stops[i]['isCompleted'] = false;
          final expTime = now.add(Duration(minutes: (i - index) * 15));
          final expStr = "${expTime.hour.toString().padLeft(2, '0')}:${expTime.minute.toString().padLeft(2, '0')}";
          stops[i]['time'] = TranslationService.currentLanguage == 'ta'
              ? 'எதிர்பார்க்கப்படும் நேரம் $expStr'
              : 'Expected $expStr';
        }
      }
    });
    int centerPage = index;
    if (centerPage > 0) centerPage -= 1;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        centerPage, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
    
    // Check if route is completed now
    if (index == stops.length - 1) {
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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('next_trip_title'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  TranslationService.translate('next_trip_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                          Navigator.of(context).pop();
                          TripService.toggleDirection();
                          setState(() {
                            stops = _getRouteStopsForCurrentTrip();
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _centerToCurrentStop();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B63F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          TranslationService.translate('confirm'),
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
  }

  void _confirmRouteChange(String newRoute) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF3B63F6),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('confirm_route_change'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  TranslationService.translate('confirm_route_change_desc')
                      .replaceAll('{route}', newRoute),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                          Navigator.of(context).pop();
                          _stopAutoTracking();
                          _loadRouteStops(newRoute);
                          TripService.currentRoute.value = newRoute;
                          TripService.isReversed.value = false;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B63F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          TranslationService.translate('confirm'),
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
  }

  void _showRouteSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationService.translate('select_route'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ..._routesData.keys.map((routeKey) {
                final isSelected = routeKey == _selectedRoute;
                return ListTile(
                  leading: Icon(
                    Icons.directions_bus, 
                    color: isSelected ? const Color(0xFF3B63F6) : Colors.grey
                  ),
                  title: Text(
                    routeKey,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF3B63F6) : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _getRouteSummary(routeKey),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF3B63F6).withValues(alpha: 0.7) : Colors.grey.shade600,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check, color: Color(0xFF3B63F6))
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmRouteChange(routeKey);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _loadCustomRoute(String customRouteId) {
    final customStops = [
      {'title': '$customRouteId Start', 'time': 'Passed Time 15:30', 'isCompleted': true},
      {'title': 'Event Stop 1', 'time': 'Expected 15:45', 'isCompleted': false},
      {'title': 'Event Stop 2', 'time': 'Expected 16:00', 'isCompleted': false},
      {'title': '$customRouteId End', 'time': 'Expected 16:15', 'isCompleted': false},
    ];
    
    setState(() {
      _routesData[customRouteId] = customStops;
      _selectedRoute = customRouteId;
      stops = List<Map<String, dynamic>>.from(
        customStops.map((stop) => Map<String, dynamic>.from(stop))
      );
    });
    
    TripService.linkBus('TN-38-SPL-999', 'Special Event Bus', customRouteId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerToCurrentStop();
    });
  }

  void _handleBusQRScan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ScannerPage(),
      ),
    );
    
    if (code != null && mounted) {
      final cleanCode = code.trim();
      
      String selectedRoute = '111A';
      String busName = 'Qurbay Express (111A)';
      String busNumber = 'TN-38-AS-9012';
      
      if (cleanCode.contains('22')) {
        selectedRoute = '22B';
        busName = 'Qurbay Transit (22B)';
        busNumber = 'TN-38-AS-4829';
      } else if (cleanCode.contains('5')) {
        selectedRoute = '5C';
        busName = 'Qurbay Link (5C)';
        busNumber = 'TN-38-AS-1029';
      } else if (cleanCode.isNotEmpty) {
        // Fallback or custom code
        selectedRoute = cleanCode.toUpperCase();
        busName = 'Event Special Bus';
        busNumber = 'TN-38-SPL-999';
        
        _loadCustomRoute(selectedRoute);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('bus_linked')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      TripService.linkBus(busNumber, busName, selectedRoute);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('bus_linked')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _loadRouteStops(selectedRoute);
    }
  }

  void _showManualRouteEntryDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationService.translate('special_route_dialog_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: TranslationService.translate('special_route_hint'),
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                          final typedRoute = textController.text.trim();
                          if (typedRoute.isNotEmpty) {
                            Navigator.of(context).pop();
                            _loadCustomRoute(typedRoute.toUpperCase());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B63F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          TranslationService.translate('confirm'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ValueListenableBuilder<String?>(
          valueListenable: TripService.currentBusNumber,
          builder: (context, busNumber, child) {
            if (busNumber == null) {
              return _buildBusLinkingPlaceholder();
            }
            return _buildTrackingContent();
          },
        ),
      ),
    );
  }

  Widget _buildBusLinkingPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.translate('live_map'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.black),
              ),
            ],
          ),
        ),
        
        // Centered Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 100,
                      color: Color(0xFF3B63F6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    TranslationService.translate('scan_to_start'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    TranslationService.translate('scan_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Scan Button
                  TactileButton(
                    onTap: _handleBusQRScan,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B63F6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B63F6).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        TranslationService.translate('scan_bus_qr'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Manual Route Button
                  TactileButton(
                    onTap: () => _showManualRouteEntryDialog(),
                    child: Text(
                      TranslationService.translate('enter_special_route'),
                      style: const TextStyle(
                        color: Color(0xFF3B63F6),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Navigation Bar
        _buildBottomBarDecoration(),
      ],
    );
  }

  Widget _buildBottomBarDecoration() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TactileButton(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: _buildNavItem(Icons.home_outlined, false),
              ),
              TactileButton(
                onTap: () {},
                child: _buildNavItem(Icons.directions_bus_outlined, true),
              ),
              TactileButton(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const PassengerCountPage()),
                  );
                },
                child: _buildNavItem(Icons.assignment_outlined, false),
              ),
              TactileButton(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                child: _buildNavItem(Icons.settings_outlined, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${TranslationService.translate('route_no_label')}: ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TactileButton(
                        onTap: () => _showRouteSelectionSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B63F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedRoute,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRouteSummary(_selectedRoute),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Top scanner button
                  TactileButton(
                    onTap: _handleBusQRScan,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF3B63F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationService.translate('live_map'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
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
                                  color: (_isAutoTracking ? Colors.green : const Color(0xFF3B63F6)).withValues(alpha: 0.3),
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
                    // Display Bus details if available
                    ValueListenableBuilder<String?>(
                      valueListenable: TripService.currentBusName,
                      builder: (context, name, _) {
                        if (name == null) return const SizedBox();
                        return Text(
                          "${TranslationService.translate('bus_name')}: $name",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Route stop cards timeline
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCCCCC).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: PageView.builder(
                          physics: const BouncingScrollPhysics(),
                          controller: _pageController,
                          itemCount: stops.length,
                          itemBuilder: (context, index) {
                            return _buildRouteNode(index);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bottom Navigation Bar (Frosted Glassmorphism) ──
        _buildBottomBarDecoration(),
      ],
    );
  }

  Widget _buildRouteNode(int index) {
    final stop = stops[index];
    final bool isCompleted = stop['isCompleted'];
    final String title = stop['title'];
    final String time = stop['time'];

    // Determine line colors
    final bool nextCompleted = index < stops.length - 1 ? stops[index + 1]['isCompleted'] : false;
    
    final Color leftLineColor = index == 0 
        ? Colors.transparent 
        : (isCompleted ? Colors.greenAccent.shade400 : Colors.grey.shade600);
        
    final Color rightLineColor = index == stops.length - 1 
        ? Colors.transparent 
        : (nextCompleted ? Colors.greenAccent.shade400 : Colors.grey.shade600);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Connecting Lines
        Positioned(
          top: 10, // Center of the 24px circle (12px) - half of line thickness
          left: 0,
          right: 0,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  color: leftLineColor,
                ),
              ),
              Expanded(
                child: Container(
                  height: 3,
                  color: rightLineColor,
                ),
              ),
            ],
          ),
        ),
        // Node Details
        GestureDetector(
          onTap: () => _onStopTapped(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent.shade400 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.greenAccent.shade400 : const Color(0xFF1E3A8A),
                    width: 3,
                  ),
                ),
                child: isCompleted 
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Icon(
      icon,
      size: 32,
      color: isActive ? Colors.black : Colors.black87,
    );
  }
}

// ── Tactile Button (Scale Press Animation & Instant Haptics) ──
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

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 0.04, // Shrinks by 4% on press
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact(); // Immediate response on down
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1.0 - _controller.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
