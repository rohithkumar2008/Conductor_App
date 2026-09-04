import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scanner_page.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';
import '../widgets/lively_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _codeController = TextEditingController(text: '12FET34');
  bool _showManualEntry = false;
  String _selectedVerifyType = 'Live'; // 'Live' or 'Pass'

  // List of recently scanned tickets
  final List<Map<String, String>> _recentlyScanned = [
    {
      'code': '12FET34',
      'passenger': 'Sarah Connor',
      'time': '10 mins ago',
      'route': '111A',
      'status': 'Verified',
      'type': 'Live',
    },
    {
      'code': 'QBY-4890',
      'passenger': 'Bruce Wayne',
      'time': '25 mins ago',
      'route': '111A',
      'status': 'Verified',
      'type': 'Live',
    },
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _getMockPassengerName(String code) {
    final List<String> names = [
      'John Doe', 'Jane Doe', 'Alice Johnson', 'Bob Smith', 
      'David Miller', 'Emma Watson', 'James Bond', 'Peter Parker'
    ];
    final int index = code.hashCode.abs() % names.length;
    return names[index];
  }

  void _verifyTicketCode(String code) {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter or scan a code first'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final bool isValid = cleanCode.length >= 4;

    if (isValid) {
      final String passenger = _getMockPassengerName(cleanCode);
      final String route = _selectedVerifyType == 'Live' ? TripService.currentRoute.value : 'All Routes';
      final String seatOrPass = _selectedVerifyType == 'Live' 
          ? 'Seat ${1 + (cleanCode.hashCode.abs() % 40)}'
          : 'PASS-${1000 + (cleanCode.hashCode.abs() % 9000)}';
      
      setState(() {
        // Prepend new verified ticket to the list
        _recentlyScanned.insert(0, {
          'code': cleanCode,
          'passenger': passenger,
          'time': 'Just now',
          'route': _selectedVerifyType == 'Live' ? TripService.currentRoute.value : 'PASS',
          'status': 'Verified',
          'type': _selectedVerifyType,
        });
      });

      if (_selectedVerifyType == 'Live') {
        _showSuccessDialog(cleanCode, passenger, route, seatOrPass, TranslationService.translate('ticket_verified'), TranslationService.translate('active_paid'), Colors.green);
      } else {
        _showSuccessDialog(cleanCode, passenger, route, seatOrPass, TranslationService.translate('conductor_pass_verified'), TranslationService.translate('active_approved'), Colors.orange);
      }
    } else {
      _showFailureDialog(cleanCode);
    }
  }

  void _showSuccessDialog(
    String code, 
    String passenger, 
    String route, 
    String seatOrPass, 
    String typeTitle,
    String statusText,
    Color accentColor,
  ) {
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
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  typeTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: $code',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildDialogRow(TranslationService.translate('holder_passenger'), passenger),
                if (_selectedVerifyType == 'Live') ...[
                  _buildDialogRow(TranslationService.translate('route_no'), route),
                  _buildDialogRow(TranslationService.translate('seat_no'), seatOrPass),
                ] else ...[
                  _buildDialogRow(TranslationService.translate('pass_id'), seatOrPass),
                  _buildDialogRow(TranslationService.translate('route_access'), route),
                  _buildDialogRow(TranslationService.translate('validity'), TranslationService.currentLanguage == 'ta' ? 'மாதாந்திர பாஸ்' : 'Monthly (Until Oct 31, 2026)'),
                ],
                _buildDialogRow(TranslationService.translate('status'), statusText, valueColor: accentColor),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B63F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      TranslationService.translate('done'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showFailureDialog(String code) {
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
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('invalid_ticket'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: $code',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('invalid_ticket_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      TranslationService.translate('close'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildDialogRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyTypeTab(String type, String label, IconData icon) {
    final bool isSelected = _selectedVerifyType == type;
    final Color activeColor = const Color(0xFF3B63F6);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVerifyType = type;
          _codeController.text = type == 'Live' ? '12FET34' : 'PASS-4890';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Light blue gradient/background at the top area
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              height: 350,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFD3E3F8), // Light blue
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationService.translate('welcome'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
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
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // ── Ticket Verification ──
                          Text(
                            TranslationService.translate('ticket_verification'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Scanner Box (Tactile & Interactive) ──
                          TactileButton(
                            onTap: () async {
                              final code = await Navigator.of(context).push<String>(
                                MaterialPageRoute(
                                  builder: (context) => const ScannerPage(),
                                ),
                              );
                              if (code != null) {
                                setState(() {
                                  if (code.toUpperCase().contains('PASS') || code.startsWith('QBY')) {
                                    _selectedVerifyType = 'Pass';
                                  } else {
                                    _selectedVerifyType = 'Live';
                                  }
                                  _codeController.text = code;
                                });
                                _verifyTicketCode(code);
                              }
                            },
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: const Color(0xFF3B63F6),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.qr_code_scanner,
                                    size: 80,
                                    color: Color(0xFF3B63F6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    TranslationService.translate('tap_to_scan'),
                                    style: const TextStyle(
                                      color: Color(0xFF3B63F6),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    TranslationService.translate('click_here_to_scan'),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // ── OR Divider ──
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade400,
                                  thickness: 1.5,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade400,
                                  thickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Enter Manually Text ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                TranslationService.translate('enter_code_manually'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showManualEntry = !_showManualEntry;
                                  });
                                },
                                child: Text(
                                  _showManualEntry 
                                      ? TranslationService.translate('hide_option') 
                                      : TranslationService.translate('enter_manually'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B63F6), // Blue color
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // ── Animated Collapsible Section ──
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _showManualEntry
                                ? Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      // ── Verification Type Selector ──
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildVerifyTypeTab('Live', TranslationService.translate('live_ticket'), Icons.directions_bus),
                                          const SizedBox(width: 16),
                                          _buildVerifyTypeTab('Pass', TranslationService.translate('pass_ticket'), Icons.card_membership),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // ── Dynamic Input Label ──
                                      Text(
                                        _selectedVerifyType == 'Live' 
                                            ? TranslationService.translate('enter_ticket_code') 
                                            : TranslationService.translate('enter_pass_id'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 220,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _codeController,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.only(bottom: 6),
                                            hintText: _selectedVerifyType == 'Live' ? 'e.g. 12FET34' : 'e.g. PASS-4890',
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // ── Check Button (Tactile) ──
                                      TactileButton(
                                        onTap: () => _verifyTicketCode(_codeController.text),
                                        child: SizedBox(
                                          width: 120,
                                          height: 40,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B63F6),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              TranslationService.translate('check'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 40),

                          // ── Recently ──
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              TranslationService.translate('recently'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentlyScanned.length,
                            itemBuilder: (context, index) {
                              final ticket = _recentlyScanned[index];
                              final isPass = ticket['type'] == 'Pass';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isPass ? Colors.orange.shade50 : Colors.green.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPass ? Icons.card_membership : Icons.check,
                                          color: isPass ? Colors.orange : Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ticket['code'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${ticket['passenger']} • ${ticket['time']}',
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
                                          color: isPass ? Colors.orange.shade50 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          ticket['route'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isPass ? Colors.orange.shade800 : Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 60), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Lively Animated Bottom Navigation Bar ──
            const Align(
              alignment: Alignment.bottomCenter,
              child: LivelyBottomNavBar(currentIndex: 0),
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
