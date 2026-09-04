import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/route_model.dart';

class LivelyBusMapWidget extends StatefulWidget {
  final List<RouteStop> stops;
  final int activeStopIndex;
  final bool isAutoTracking;
  final Function(int) onStopConfirmed;

  const LivelyBusMapWidget({
    super.key,
    required this.stops,
    required this.activeStopIndex,
    required this.isAutoTracking,
    required this.onStopConfirmed,
  });

  @override
  State<LivelyBusMapWidget> createState() => _LivelyBusMapWidgetState();
}

class _LivelyBusMapWidgetState extends State<LivelyBusMapWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _busMoveController;
  late Animation<double> _busProgressAnimation;

  double _currentBusProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _busMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _updateProgressFromIndex(widget.activeStopIndex, animate: false);
  }

  @override
  void didUpdateWidget(covariant LivelyBusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeStopIndex != widget.activeStopIndex) {
      _updateProgressFromIndex(widget.activeStopIndex, animate: true);
    }
  }

  void _updateProgressFromIndex(int index, {required bool animate}) {
    final total = widget.stops.length > 1 ? widget.stops.length - 1 : 1;
    final target = (index.clamp(0, total)) / total.toDouble();

    if (animate) {
      _busProgressAnimation = Tween<double>(
        begin: _currentBusProgress,
        end: target,
      ).animate(CurvedAnimation(
        parent: _busMoveController,
        curve: Curves.easeInOutCubic,
      ))..addListener(() {
          setState(() {
            _currentBusProgress = _busProgressAnimation.value;
          });
        });
      _busMoveController.forward(from: 0.0);
    } else {
      setState(() {
        _currentBusProgress = target;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _busMoveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStop = widget.activeStopIndex < widget.stops.length
        ? widget.stops[widget.activeStopIndex]
        : widget.stops.last;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // ── Map Canvas with Road Grid, Polylines, & Markers ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _busMoveController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _LivelyMapPainter(
                    stops: widget.stops,
                    activeStopIndex: widget.activeStopIndex,
                    busProgress: _currentBusProgress,
                    pulseValue: _pulseController.value,
                  ),
                );
              },
            ),
          ),

          // ── Top Gradient Overlay for Depth ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Live Speedometer & GPS Status Badge ──
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '34 km/h • GPS LIVE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Compass Indicator ──
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -0.3,
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF3B63F6),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Conductor Quick-Confirmation Card ──
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B63F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF3B63F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TARGET: ${currentStop.title}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentStop.time,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tactile Quick "Tick Arrival" Button
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      widget.onStopConfirmed(widget.activeStopIndex);
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Tick Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivelyMapPainter extends CustomPainter {
  final List<RouteStop> stops;
  final int activeStopIndex;
  final double busProgress;
  final double pulseValue;

  _LivelyMapPainter({
    required this.stops,
    required this.activeStopIndex,
    required this.busProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Map Background Base
    final bgPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. City Blocks & Green Parks
    _drawCityTerrain(canvas, size);

    // 3. Road Network Grid
    _drawRoadGrid(canvas, size);

    // 4. Generate S-Curved Transit Route Path
    final routePoints = _generateRoutePath(size, stops.length);
    if (routePoints.isEmpty) return;

    // 5. Draw Route Background Glow & Glow Track
    final path = Path();
    path.moveTo(routePoints.first.dx, routePoints.first.dy);
    for (int i = 1; i < routePoints.length; i++) {
      final p0 = routePoints[i - 1];
      final p1 = routePoints[i];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }
    path.lineTo(routePoints.last.dx, routePoints.last.dy);

    // Full Route Outline
    final routeOutlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routeOutlinePaint);

    // Remaining Route Polyline (Vibrant Blue)
    final routePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // Completed Route Polyline (Green)
    _drawCompletedPath(canvas, routePoints, busProgress);

    // 6. Draw Stop Pin Nodes on Map
    for (int i = 0; i < routePoints.length; i++) {
      final pt = routePoints[i];
      final isComp = i < activeStopIndex || (i == activeStopIndex && stops[i].isCompleted);
      final isAct = i == activeStopIndex;

      _drawStopPin(canvas, pt, i, isComp, isAct, stops[i].title);
    }

    // 7. Calculate Exact Bus Position & Heading
    final busPos = _getPointAlongCurve(routePoints, busProgress);
    final nextBusPos = _getPointAlongCurve(routePoints, math.min(1.0, busProgress + 0.02));
    final heading = math.atan2(nextBusPos.dy - busPos.dy, nextBusPos.dx - busPos.dx);

    // 8. Draw Animated Pulsing Radar Around Bus
    final pulsePaint = Paint()
      ..color = const Color(0xFF3B63F6).withValues(alpha: (1.0 - pulseValue) * 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(busPos, 14.0 + (pulseValue * 18.0), pulsePaint);

    final pulseRing = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: (1.0 - pulseValue) * 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(busPos, 14.0 + (pulseValue * 18.0), pulseRing);

    // 9. Draw Bus Vehicle Icon
    canvas.save();
    canvas.translate(busPos.dx, busPos.dy);
    canvas.rotate(heading);

    // Bus Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -7, 22, 14),
        const Radius.circular(5),
      ),
      shadowPaint,
    );

    // Bus Body (Gradient Blue)
    final busBodyPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -6, 20, 12),
        const Radius.circular(4),
      ),
      busBodyPaint,
    );

    // Windshield (Front White / Light Blue)
    final windshieldPaint = Paint()..color = const Color(0xFF93C5FD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, -4.5, 4, 9),
        const Radius.circular(2),
      ),
      windshieldPaint,
    );

    // Headlights
    final headlightPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(const Offset(9.5, -4), 1.2, headlightPaint);
    canvas.drawCircle(const Offset(9.5, 4), 1.2, headlightPaint);

    canvas.restore();
  }

  void _drawCityTerrain(Canvas canvas, Size size) {
    final parkPaint = Paint()..color = const Color(0xFFD1FAE5);
    // Green Parks
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.12, 60, 45), const Radius.circular(8)),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.68, size.height * 0.45, 75, 55), const Radius.circular(10)),
      parkPaint,
    );

    // Water Body
    final waterPaint = Paint()..color = const Color(0xFFCFFAFE);
    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.7);
    waterPath.quadraticBezierTo(size.width * 0.3, size.height * 0.65, size.width * 0.4, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);
  }

  void _drawRoadGrid(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Cross city streets
    canvas.drawLine(Offset(0, size.height * 0.28), Offset(size.width, size.height * 0.22), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.52), Offset(size.width, size.height * 0.56), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.72, 0), Offset(size.width * 0.68, size.height), roadPaint);
  }

  List<Offset> _generateRoutePath(Size size, int count) {
    final points = <Offset>[];
    final paddingX = size.width * 0.15;
    final paddingY = size.height * 0.22;
    final usableW = size.width - (paddingX * 2);
    final usableH = size.height - (paddingY * 2);

    for (int i = 0; i < count; i++) {
      final t = count > 1 ? i / (count - 1).toDouble() : 0.5;
      // Winding S-curve through Coimbatore map layout
      final x = paddingX + (usableW * t) + (math.sin(t * math.pi * 2) * (size.width * 0.12));
      final y = paddingY + (usableH * t);
      points.add(Offset(x, y));
    }
    return points;
  }

  void _drawCompletedPath(Canvas canvas, List<Offset> points, double progress) {
    if (points.isEmpty || progress <= 0) return;

    final completedPath = Path();
    completedPath.moveTo(points.first.dx, points.first.dy);

    final total = points.length - 1;
    final currentProgIndex = (progress * total).floor();
    final remainder = (progress * total) - currentProgIndex;

    for (int i = 1; i <= currentProgIndex && i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      completedPath.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      if (i == currentProgIndex && remainder > 0 && i < points.length - 1) {
        final nextP = points[i + 1];
        final interpX = p1.dx + (nextP.dx - p1.dx) * remainder;
        final interpY = p1.dy + (nextP.dy - p1.dy) * remainder;
        completedPath.lineTo(interpX, interpY);
      }
    }

    final greenPathPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(completedPath, greenPathPaint);
  }

  Offset _getPointAlongCurve(List<Offset> points, double progress) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    final total = points.length - 1;
    final index = (progress * total).floor().clamp(0, total - 1);
    final t = (progress * total) - index;

    final p0 = points[index];
    final p1 = points[index + 1];
    return Offset(
      p0.dx + (p1.dx - p0.dx) * t,
      p0.dy + (p1.dy - p0.dy) * t,
    );
  }

  void _drawStopPin(Canvas canvas, Offset pt, int index, bool isCompleted, bool isActive, String label) {
    final Color pinColor = isCompleted
        ? const Color(0xFF10B981)
        : (isActive ? const Color(0xFF3B63F6) : Colors.white);

    // Stop Pin Circle
    final pinPaint = Paint()..color = pinColor;
    final borderPaint = Paint()
      ..color = isCompleted ? const Color(0xFF059669) : const Color(0xFF1E3A8A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pt, 9.0, pinPaint);
    canvas.drawCircle(pt, 9.0, borderPaint);

    if (isCompleted) {
      // Draw Checkmark
      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final checkPath = Path();
      checkPath.moveTo(pt.dx - 3.5, pt.dy);
      checkPath.lineTo(pt.dx - 1.0, pt.dy + 2.5);
      checkPath.lineTo(pt.dx + 3.5, pt.dy - 2.5);
      canvas.drawPath(checkPath, checkPaint);
    } else {
      // Inner Dot
      final dotPaint = Paint()..color = isActive ? Colors.white : const Color(0xFF1E3A8A);
      canvas.drawCircle(pt, 3.0, dotPaint);
    }

    // Mini Stop Label
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 9.0,
        fontWeight: FontWeight.w800,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = Offset(pt.dx - (textPainter.width / 2), pt.dy + 11.0);
    // Label background pill
    final pillRect = Rect.fromLTWH(
      labelOffset.dx - 4,
      labelOffset.dy - 1,
      textPainter.width + 8,
      textPainter.height + 2,
    );
    final pillPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(4)), pillPaint);
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _LivelyMapPainter oldDelegate) {
    return oldDelegate.busProgress != busProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.activeStopIndex != activeStopIndex;
  }
}
