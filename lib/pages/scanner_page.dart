import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scanAreaSize = 250.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Feed ──
          MobileScanner(
            controller: controller,
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
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera Access Required',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.errorCode == MobileScannerErrorCode.permissionDenied
                              ? 'Please enable camera permission in your system settings to scan tickets.'
                              : 'An error occurred while starting the camera: ${error.errorDetails?.message ?? error.errorCode.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onDetect: (BarcodeCapture capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcodeValue = barcodes.first.rawValue;
                if (barcodeValue != null && barcodeValue.isNotEmpty) {
                  setState(() {
                    _isScanned = true;
                  });
                  // Trigger light haptic tap
                  HapticFeedback.lightImpact();
                  // Return value to preceding screen
                  Navigator.of(context).pop(barcodeValue);
                }
              }
            },
          ),

          // ── Semi-transparent background with transparent scanning window ──
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
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
                        color: Colors.red, // color matches srcOut blend
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Outer Border Frame & Animated Scan Line ──
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: Stack(
                children: [
                  // Corner Borders
                  CustomPaint(
                    size: const Size(scanAreaSize, scanAreaSize),
                    painter: ScannerFramePainter(),
                  ),
                  
                  // Scanning Laser Line
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + _animation.value * (scanAreaSize - 40),
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B63F6).withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF3B63F6),
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

          // ── Instructions & Title ──
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Scan Ticket QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align QR code within the frame',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Action Controls ──
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Torch Toggle
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final bool isTorchOn = state.torchState == TorchState.on;
                    return GestureDetector(
                      onTap: () => controller.toggleTorch(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTorchOn ? const Color(0xFF3B63F6) : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: isTorchOn ? const Color(0xFF3B63F6) : Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 40),
                // Camera Facing Toggle
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final bool isFront = state.cameraDirection == CameraFacing.front;
                    return GestureDetector(
                      onTap: () => controller.switchCamera(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isFront ? Icons.camera_front : Icons.camera_rear,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B63F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    const double radius = 30.0;
    const double lineLength = 30.0;

    // Top-Left Corner
    canvas.drawArc(
      Rect.fromLTWH(0, 0, radius * 2, radius * 2),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
