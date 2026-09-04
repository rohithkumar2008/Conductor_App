import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../services/bus_database_service.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';

class BusScannerPage extends StatefulWidget {
  final RouteModel selectedRoute;
  final BusModel? preSelectedBus;

  const BusScannerPage({
    super.key,
    required this.selectedRoute,
    this.preSelectedBus,
  });

  @override
  State<BusScannerPage> createState() => _BusScannerPageState();
}

class _BusScannerPageState extends State<BusScannerPage> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isQrDetected = false;
  DateTime? _lastScanTimestamp;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    // High-performance scanner controller for 30fps+ responsiveness
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 400,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    // Debounce rapid multiple scans
    final now = DateTime.now();
    if (_lastScanTimestamp != null &&
        now.difference(_lastScanTimestamp!).inMilliseconds < 1200) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _lastScanTimestamp = now;
    _handleDetectedPayload(rawValue.trim());
  }

  Future<void> _handleDetectedPayload(String payload) async {
    // 1. Real-time feedback state
    setState(() {
      _isProcessing = true;
      _isQrDetected = true;
    });

    HapticFeedback.heavyImpact();

    // 2. Validate against fleet backend
    final result = await BusDatabaseService.validateQrCodeAsync(
      payload,
      targetRouteNumber: widget.selectedRoute.routeNumber,
      currentConductorId: TripService.conductorId,
    );

    if (!mounted) return;

    setState(() {
      _isQrDetected = false;
    });

    // 3. Evaluate validation outcome
    if (result.isValid && result.bus != null) {
      HapticFeedback.lightImpact();
      _showBusSuccessSheet(result.bus!);
    } else {
      HapticFeedback.vibrate();
      _showErrorSheet(result);
    }
  }

  void _showBusSuccessSheet(BusModel bus) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
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
              // Success Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationService.translate('bus_verified_success'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          TranslationService.translate('bus_verified_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Route Match Confirmation Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(widget.selectedRoute.colorValue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.selectedRoute.routeNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedRoute.routeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.selectedRoute.summary,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bus Specification Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B63F6).withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B63F6).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSpecRow(
                      icon: Icons.tag,
                      label: TranslationService.translate('bus_number_label'),
                      value: bus.busNumber,
                      isHighlight: true,
                    ),
                    const Divider(height: 16),
                    _buildSpecRow(
                      icon: Icons.badge_outlined,
                      label: TranslationService.translate('registration_label'),
                      value: bus.registrationNumber,
                    ),
                    const Divider(height: 16),
                    _buildSpecRow(
                      icon: Icons.directions_bus_outlined,
                      label: TranslationService.translate('model_label'),
                      value: bus.model,
                    ),
                    const Divider(height: 16),
                    _buildSpecRow(
                      icon: Icons.airline_seat_recline_extra_outlined,
                      label: TranslationService.translate('capacity_label'),
                      value: bus.capacity,
                    ),
                    const Divider(height: 16),
                    _buildSpecRow(
                      icon: Icons.location_city_outlined,
                      label: TranslationService.translate('depot_label'),
                      value: bus.depot,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons: Start Duty & Rescan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        setState(() {
                          _isProcessing = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        TranslationService.translate('rescan_bus'),
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Persistently link bus in TripService
                        TripService.linkBusWithDetails(bus, widget.selectedRoute);

                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).pop(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.cloud_done, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    TranslationService.translate('bus_linked'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        TranslationService.translate('start_duty'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF3B63F6),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF3B63F6).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSheet(BusValidationResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        String title = TranslationService.translate('qr_validation_failed');
        IconData icon = Icons.error_outline_rounded;
        Color color = Colors.red;

        switch (result.errorType) {
          case BusValidationErrorType.wrongRoute:
            title = TranslationService.translate('error_wrong_route_title');
            icon = Icons.wrong_location_outlined;
            color = Colors.amber.shade900;
            break;
          case BusValidationErrorType.alreadyLinked:
            title = TranslationService.translate('error_already_linked_title');
            icon = Icons.lock_person_outlined;
            color = Colors.deepOrange;
            break;
          case BusValidationErrorType.expired:
            title = TranslationService.translate('error_expired_title');
            icon = Icons.timer_off_outlined;
            color = Colors.orange.shade800;
            break;
          case BusValidationErrorType.underMaintenance:
            title = TranslationService.translate('error_maintenance_title');
            icon = Icons.build_circle_outlined;
            color = Colors.amber.shade800;
            break;
          case BusValidationErrorType.networkError:
            title = TranslationService.translate('error_network_title');
            icon = Icons.wifi_off_rounded;
            color = Colors.blueGrey;
            break;
          default:
            title = TranslationService.translate('error_not_found_title');
            icon = Icons.qr_code_2_rounded;
            color = Colors.red.shade700;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                result.errorMessage ?? TranslationService.translate('qr_validation_failed'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (result.errorDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result.errorDetails!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Row(
                children: [
                  // Retry Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        setState(() {
                          _isProcessing = false;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(TranslationService.translate('retry_scanning')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Manual Fallback Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showManualEntryModal();
                      },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(TranslationService.translate('try_manual_entry')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF3B63F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showManualEntryModal() {
    final TextEditingController manualInputController = TextEditingController();
    final availableFleet = BusDatabaseService.getAvailableFleet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: Color(0xFF3B63F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationService.translate('manual_entry_title'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              TranslationService.translate('manual_entry_desc'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Input text field
                  TextField(
                    controller: manualInputController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: TranslationService.translate('manual_entry_hint'),
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B63F6)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF3B63F6), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    TranslationService.translate('available_depot_buses'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quick select chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableFleet.map((bus) {
                      return ActionChip(
                        avatar: const Icon(Icons.directions_bus, size: 16, color: Color(0xFF3B63F6)),
                        label: Text('${bus.busNumber} (${bus.registrationNumber})'),
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        backgroundColor: const Color(0xFFF0F4FF),
                        side: BorderSide(color: const Color(0xFF3B63F6).withValues(alpha: 0.2)),
                        onPressed: () {
                          manualInputController.text = bus.busNumber;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            setState(() {
                              _isProcessing = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(TranslationService.translate('cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final query = manualInputController.text.trim();
                            if (query.isEmpty) return;

                            Navigator.of(sheetContext).pop();
                            setState(() {
                              _isProcessing = true;
                            });

                            final result = await BusDatabaseService.lookupBusManuallyAsync(
                              query,
                              targetRouteNumber: widget.selectedRoute.routeNumber,
                              currentConductorId: TripService.conductorId,
                            );

                            if (!mounted) return;

                            if (result.isValid && result.bus != null) {
                              HapticFeedback.lightImpact();
                              _showBusSuccessSheet(result.bus!);
                            } else {
                              _showErrorSheet(result);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF3B63F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(TranslationService.translate('lookup_bus')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  TranslationService.translate('exit_scanner_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            TranslationService.translate('exit_scanner_desc'),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(TranslationService.translate('continue_scanning')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(TranslationService.translate('exit_scanner')),
            ),
          ],
        );
      },
    );
    return shouldExit ?? false;
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlight ? const Color(0xFF3B63F6) : Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? const Color(0xFF3B63F6) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scanAreaSize = MediaQuery.of(context).size.width * 0.68 > 280
        ? 280
        : MediaQuery.of(context).size.width * 0.68;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera Scanner Viewport ──
            MobileScanner(
              controller: _scannerController,
              errorBuilder: (context, error) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            TranslationService.translate('camera_permission_required'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            TranslationService.translate('camera_permission_desc'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showManualEntryModal(),
                            icon: const Icon(Icons.edit_note_rounded),
                            label: Text(TranslationService.translate('enter_bus_manually')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B63F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onDetect: _onDetect,
            ),

            // ── Dark Viewfinder Mask ──
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.65),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: scanAreaSize,
                        height: scanAreaSize,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Targeting Guides & Laser Frame ──
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    // Corner targeting brackets
                    CustomPaint(
                      size: Size(scanAreaSize, scanAreaSize),
                      painter: _BusScannerFramePainter(
                        color: _isQrDetected ? const Color(0xFF10B981) : const Color(0xFF3B63F6),
                      ),
                    ),
                    // Center Targeting Dot
                    Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isQrDetected ? const Color(0xFF10B981) : Colors.white70,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isQrDetected ? const Color(0xFF10B981) : const Color(0xFF3B63F6))
                                  .withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Animated Scanning Laser Line
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + _laserAnimation.value * (scanAreaSize - 40),
                          left: 15,
                          right: 15,
                          child: Container(
                            height: 3.5,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: (_isQrDetected ? const Color(0xFF10B981) : const Color(0xFF3B63F6))
                                      .withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _isQrDetected ? const Color(0xFF10B981) : const Color(0xFF3B63F6),
                                  Colors.white,
                                  _isQrDetected ? const Color(0xFF10B981) : const Color(0xFF3B63F6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Top Header with Selected Route Info ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final shouldExit = await _onWillPop();
                            if (shouldExit && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationService.translate('scan_bus_qr_title'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                TranslationService.translate('scan_bus_qr_desc'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Active Route Selection Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(widget.selectedRoute.colorValue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.selectedRoute.routeNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.selectedRoute.routeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Real-time Detection Feedback Pill ──
            if (_isQrDetected)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.28,
                left: 30,
                right: 30,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            TranslationService.translate('qr_detected_validating'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Bottom Action Controls ──
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Instructions hint pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TranslationService.translate('align_bus_qr'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Camera & Flash & Manual Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Flash Toggle
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _scannerController,
                        builder: (context, state, child) {
                          final bool isTorchOn = state.torchState == TorchState.on;
                          return Semantics(
                            label: isTorchOn
                                ? TranslationService.translate('torch_on')
                                : TranslationService.translate('torch_off'),
                            button: true,
                            child: IconButton.filled(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _scannerController.toggleTorch();
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                side: BorderSide(
                                  color: isTorchOn ? const Color(0xFF3B63F6) : Colors.white24,
                                ),
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: Icon(
                                isTorchOn ? Icons.flash_on : Icons.flash_off,
                                color: isTorchOn ? const Color(0xFF3B63F6) : Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // Manual Fallback Action Button
                      Semantics(
                        label: TranslationService.translate('enter_bus_manually'),
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: () => _showManualEntryModal(),
                          icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                          label: Text(TranslationService.translate('enter_bus_manually')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B63F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Camera Switch
                      Semantics(
                        label: TranslationService.translate('switch_camera'),
                        button: true,
                        child: IconButton.filled(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _scannerController.switchCamera();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.all(14),
                          ),
                          icon: const Icon(
                            Icons.cameraswitch_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusScannerFramePainter extends CustomPainter {
  final Color color;

  _BusScannerFramePainter({this.color = const Color(0xFF3B63F6)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    const double radius = 32.0;
    const double lineLength = 32.0;

    // Top-Left Corner
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(const Offset(0, radius), const Offset(0, radius + lineLength), paint);
    canvas.drawLine(const Offset(radius, 0), const Offset(radius + lineLength, 0), paint);

    // Top-Right Corner
    canvas.drawArc(
      Rect.fromLTWH(width - radius * 2, 0, radius * 2, radius * 2),
      4.71,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(Offset(width, radius), Offset(width, radius + lineLength), paint);
    canvas.drawLine(Offset(width - radius, 0), Offset(width - radius - lineLength, 0), paint);

    // Bottom-Left Corner
    canvas.drawArc(
      Rect.fromLTWH(0, height - radius * 2, radius * 2, radius * 2),
      1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(Offset(0, height - radius), Offset(0, height - radius - lineLength), paint);
    canvas.drawLine(Offset(radius, height), Offset(radius + lineLength, height), paint);

    // Bottom-Right Corner
    canvas.drawArc(
      Rect.fromLTWH(width - radius * 2, height - radius * 2, radius * 2, radius * 2),
      0,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(Offset(width, height - radius), Offset(width, height - radius - lineLength), paint);
    canvas.drawLine(Offset(width - radius, height), Offset(width - radius - lineLength, height), paint);
  }

  @override
  bool shouldRepaint(covariant _BusScannerFramePainter oldDelegate) => oldDelegate.color != color;
}
