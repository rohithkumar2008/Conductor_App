import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;
import 'home_page.dart';
import 'live_tracking_page.dart';
import 'scanner_page.dart';
import 'passenger_count_page.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Text(
                TranslationService.translate('settings'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ),
            
            // ── Settings List Container ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0), // Matching the grey background from image
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        TactileButton(
                          onTap: () => _showLanguageSelectionDialog(context),
                          child: _buildSettingItem(
                            icon: Icons.translate,
                            title: TranslationService.translate('language_option'),
                            trailingText: TranslationService.currentLanguage == 'en'
                                ? TranslationService.translate('english')
                                : TranslationService.translate('tamil'),
                          ),
                        ),
                        _buildDivider(),
                        TactileButton(
                          onTap: () => _showAccountInfoDialog(context),
                          child: _buildSettingItem(
                            icon: Icons.person_outline,
                            title: TranslationService.translate('account_info'),
                          ),
                        ),
                        _buildDivider(),
                        TactileButton(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${TranslationService.translate('history')} feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: _buildSettingItem(
                            icon: Icons.history,
                            title: TranslationService.translate('history'),
                          ),
                        ),
                        _buildDivider(),
                        TactileButton(
                          onTap: () async {
                            final code = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (context) => const ScannerPage(),
                              ),
                            );
                            if (code != null && context.mounted) {
                              _showScannedCodeDialog(context, code);
                            }
                          },
                          child: _buildSettingItem(
                            icon: Icons.qr_code_scanner,
                            title: TranslationService.translate('scanner'),
                          ),
                        ),
                        _buildDivider(),
                        TactileButton(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${TranslationService.translate('location')} feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: _buildSettingItem(
                            icon: Icons.location_on_outlined,
                            title: TranslationService.translate('location'),
                          ),
                        ),
                        _buildDivider(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation Bar (Frosted Glassmorphism) ──
            ClipRRect(
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
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LiveTrackingPage()),
                          );
                        },
                        child: _buildNavItem(Icons.directions_bus_outlined, false),
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
                        onTap: () {},
                        child: _buildNavItem(Icons.settings_outlined, true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Blue color for "English"
              ),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68, right: 24),
      child: Divider(
        color: Colors.grey.shade400,
        thickness: 1,
        height: 1,
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
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
                  TranslationService.translate('language_option'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blueAccent),
                  title: Text(TranslationService.translate('english')),
                  trailing: TranslationService.currentLanguage == 'en'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    TranslationService.setLanguage('en');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blueAccent),
                  title: Text(TranslationService.translate('tamil')),
                  trailing: TranslationService.currentLanguage == 'ta'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    TranslationService.setLanguage('ta');
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(TranslationService.translate('close')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountInfoDialog(BuildContext context) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B63F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3B63F6),
                    size: 40,
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
                _buildDialogRow(TranslationService.translate('conductor_name'), 'Ramesh Kumar'),
                _buildDialogRow(TranslationService.translate('age'), '38'),
                _buildDialogRow(TranslationService.translate('gender'), TranslationService.translate('male')),
                _buildDialogRow(TranslationService.translate('employee_id'), TripService.conductorId),
                _buildDialogRow(TranslationService.translate('assigned_route'), TripService.currentRoute.value),
                _buildDialogRow(TranslationService.translate('license_no'), 'DL-TN38-2015-8490'),
                _buildDialogRow(TranslationService.translate('phone_no'), '+91 98453 10482'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B63F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(TranslationService.translate('close_details')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Icon(
      icon,
      size: 32,
      color: isActive ? Colors.black : Colors.black87,
    );
  }

  void _showScannedCodeDialog(BuildContext context, String code) {
    final cleanCode = code.trim();
    final bool isValid = cleanCode.length >= 4;

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
                    color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    color: isValid ? Colors.green : Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isValid ? 'Ticket Verified' : 'Invalid Ticket',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: $cleanCode',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                if (isValid) ...[
                  _buildDialogRow('Passenger', 'Jane Doe'),
                  _buildDialogRow('Route No', '111A'),
                  _buildDialogRow('Seat No', 'Seat 18'),
                  _buildDialogRow('Status', 'Active / Paid', valueColor: Colors.green),
                ] else ...[
                  const Text(
                    'This ticket code is invalid. Please make sure the code has at least 4 characters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid ? const Color(0xFF3B63F6) : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isValid ? 'Done' : 'Close',
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
