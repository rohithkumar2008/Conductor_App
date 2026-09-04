import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../widgets/lively_bottom_nav_bar.dart';

class PassengerCountPage extends StatefulWidget {
  const PassengerCountPage({super.key});

  @override
  State<PassengerCountPage> createState() => _PassengerCountPageState();
}

class _PassengerCountPageState extends State<PassengerCountPage> {
  int _currentCount = 24;
  int _dailyTotal = 154;

  final List<Map<String, String>> _history = [
    {
      'title': 'Ganapathy Stop',
      'description': '+5 boarded, -2 exited',
      'total': 'Total: 24',
      'time': '10 mins ago',
      'type': 'Stop',
    },
    {
      'title': 'Scanned Passenger Pass',
      'description': 'Valid PASS-4890',
      'total': 'Total: 21',
      'time': '18 mins ago',
      'type': 'Scan',
    },
    {
      'title': 'Sathy Road Stop',
      'description': '+3 boarded, -0 exited',
      'total': 'Total: 20',
      'time': '25 mins ago',
      'type': 'Stop',
    },
    {
      'title': 'Scanned Live Ticket',
      'description': 'Valid Ticket 12FET34',
      'total': 'Total: 17',
      'time': '32 mins ago',
      'type': 'Scan',
    },
  ];

  void _incrementCount() {
    setState(() {
      _currentCount++;
      _dailyTotal++;
      _history.insert(0, {
        'title': 'Manual Entry',
        'description': '+1 passenger boarded',
        'total': 'Total: $_currentCount',
        'time': 'Just now',
        'type': 'Manual',
      });
    });
  }

  void _decrementCount() {
    if (_currentCount > 0) {
      setState(() {
        _currentCount--;
        _history.insert(0, {
          'title': 'Manual Entry',
          'description': '-1 passenger exited',
          'total': 'Total: $_currentCount',
          'time': 'Just now',
          'type': 'Manual',
        });
      });
    }
  }

  String _translateHistoryTitle(String title) {
    if (TranslationService.currentLanguage == 'ta') {
      if (title == 'Ganapathy Stop') return 'கணபதி நிறுத்தம்';
      if (title == 'Sathy Road Stop') return 'சதி சாலை நிறுத்தம்';
      if (title == 'Manual Entry') return 'கைமுறை உள்ளீடு';
      if (title == 'Scanned Passenger Pass') return 'சரிபார்க்கப்பட்ட பாஸ்';
      if (title == 'Scanned Live Ticket') return 'சரிபார்க்கப்பட்ட டிக்கெட்';
    }
    return title;
  }

  String _translateHistoryDesc(String desc) {
    if (TranslationService.currentLanguage == 'ta') {
      if (desc.contains('boarded') && desc.contains('exited')) {
        final parts = desc.split(', ');
        final boarded = parts[0].replaceAll(' boarded', ' ஏறினர்');
        final exited = parts[1].replaceAll(' exited', ' இறங்கினர்');
        return '$boarded, $exited';
      }
      if (desc == '+1 passenger boarded') return '+1 பயணி ஏறினார்';
      if (desc == '-1 passenger exited') return '-1 பயணி இறங்கினார்';
      if (desc.startsWith('Valid PASS')) return desc.replaceAll('Valid PASS', 'செல்லுபடியாகும் பாஸ்');
      if (desc.startsWith('Valid Ticket')) return desc.replaceAll('Valid Ticket', 'செல்லுபடியாகும் டிக்கெட்');
    }
    return desc;
  }

  String _translateHistoryTime(String time) {
    if (TranslationService.currentLanguage == 'ta') {
      if (time == 'Just now') return 'இப்போது';
      return time.replaceAll('mins ago', 'நிமிடங்களுக்கு முன்பு');
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Text(
                    TranslationService.translate('passenger_count'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ),

                // ── Dashboard Cards ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Current Passengers Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B63F6).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF3B63F6).withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                TranslationService.translate('live_on_board'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B63F6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$_currentCount',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B63F6),
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Decrement Button
                                  TactileButton(
                                    onTap: _decrementCount,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF3B63F6).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Color(0xFF3B63F6),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Increment Button
                                  TactileButton(
                                    onTap: _incrementCount,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B63F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Daily Total Passengers Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.green.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                TranslationService.translate('daily_total'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$_dailyTotal',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active Today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── History Title ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    TranslationService.translate('history_log'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Scrollable History List ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      itemCount: _history.length,
                      padding: const EdgeInsets.only(bottom: 90),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final type = item['type'];

                        IconData icon;
                        Color iconColor;
                        Color bgColor;

                        if (type == 'Stop') {
                          icon = Icons.directions_bus;
                          iconColor = Colors.blue.shade700;
                          bgColor = Colors.blue.shade50;
                        } else if (type == 'Scan') {
                          icon = Icons.qr_code_scanner;
                          iconColor = Colors.green.shade700;
                          bgColor = Colors.green.shade50;
                        } else {
                          icon = Icons.edit_note;
                          iconColor = Colors.orange.shade700;
                          bgColor = Colors.orange.shade50;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _translateHistoryTitle(item['title'] ?? ''),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_translateHistoryDesc(item['description'] ?? '')} • ${_translateHistoryTime(item['time'] ?? '')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    TranslationService.currentLanguage == 'ta' 
                                        ? item['total']!.replaceAll('Total:', 'மொத்தம்:')
                                        : item['total'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // ── Lively Animated Bottom Navigation Bar ──
            const Align(
              alignment: Alignment.bottomCenter,
              child: LivelyBottomNavBar(currentIndex: 2),
            ),
          ],
        ),
      ),
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
