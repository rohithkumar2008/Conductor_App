import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _conductorIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _conductorIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final conductorId = _conductorIdController.text.trim();
    final password = _passwordController.text.trim();

    if (conductorId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('fill_all_fields')),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Save values in TripService
    TripService.conductorId = conductorId;
    TripService.currentBusNumber.value = null;
    TripService.currentBusName.value = null;

    // Navigate to dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F5), // Light blue matching the road
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -300, // Extends container downwards to pull the bus down
            child: Image.asset(
              'assets/images/city_bus.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.topRight, // Keeps the sky at the top, pushes the bus down
            ),
          ),

          // ═══════════════════════════════════════════
          // CONTENT
          // ═══════════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/qurbay_logo.jpeg',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Conductor App Title in Blue
                Text(
                  TranslationService.translate('conductor_app'),
                  style: const TextStyle(
                    color: Color(0xFF2962FF), // Blue color matching the mockup
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(), // Pushes the card to the bottom
                // ═══════════════════════════════════════════
                // WHITE LOGIN CARD
                // ═══════════════════════════════════════════
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome Back! ──
                      Center(
                        child: Text(
                          TranslationService.translate('welcome_back'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2962FF), // Blue color
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          TranslationService.translate('login_continue'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Conductor ID ──
                      Text(
                        TranslationService.translate('conductor_id'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _conductorIdController,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: TranslationService.translate('enter_id'),
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.black,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Password ──
                      Text(
                        TranslationService.translate('password'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: TranslationService.translate('enter_password'),
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.black,
                              size: 22,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── forgot password ? ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            TranslationService.translate('forgot_password'),
                            style: const TextStyle(
                              color: Color(0xFF2962FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Login Button (Tactile) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TactileButton(
                          onTap: _handleLogin,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B63F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              TranslationService.translate('login'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
