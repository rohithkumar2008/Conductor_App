import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;
import '../pages/home_page.dart';
import '../pages/live_tracking_page.dart';
import '../pages/passenger_count_page.dart';
import '../pages/settings_page.dart';

/// Smooth directional slide and cross-fade route transition
class LivelyPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final double slideDirection; // > 0 slides from right to left, < 0 slides from left to right

  LivelyPageRoute({
    required this.builder,
    this.slideDirection = 1.0,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedSlide = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideAnimation = Tween<Offset>(
              begin: Offset(slideDirection * 0.25, 0.0),
              end: Offset.zero,
            ).animate(curvedSlide);

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

class LivelyBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const LivelyBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int targetIndex) {
    if (targetIndex == currentIndex) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    final double direction = targetIndex > currentIndex ? 1.0 : -1.0;

    Widget targetPage;
    switch (targetIndex) {
      case 0:
        targetPage = const HomePage();
        break;
      case 1:
        targetPage = const LiveTrackingPage();
        break;
      case 2:
        targetPage = const PassengerCountPage();
        break;
      case 3:
        targetPage = const SettingsPage();
        break;
      default:
        targetPage = const HomePage();
    }

    Navigator.of(context).pushReplacement(
      LivelyPageRoute(
        builder: (context) => targetPage,
        slideDirection: direction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LivelyNavItem(
                index: 0,
                currentIndex: currentIndex,
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                onTap: () => _onItemTapped(context, 0),
              ),
              _LivelyNavItem(
                index: 1,
                currentIndex: currentIndex,
                activeIcon: Icons.directions_bus_rounded,
                inactiveIcon: Icons.directions_bus_outlined,
                onTap: () => _onItemTapped(context, 1),
              ),
              _LivelyNavItem(
                index: 2,
                currentIndex: currentIndex,
                activeIcon: Icons.assignment_rounded,
                inactiveIcon: Icons.assignment_outlined,
                onTap: () => _onItemTapped(context, 2),
              ),
              _LivelyNavItem(
                index: 3,
                currentIndex: currentIndex,
                activeIcon: Icons.settings_rounded,
                inactiveIcon: Icons.settings_outlined,
                onTap: () => _onItemTapped(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivelyNavItem extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback onTap;

  const _LivelyNavItem({
    required this.index,
    required this.currentIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  @override
  State<_LivelyNavItem> createState() => _LivelyNavItemState();
}

class _LivelyNavItemState extends State<_LivelyNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _tapAnimController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapAnimController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _tapAnimController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _tapAnimController.reverse();
  }

  void _handleTapCancel() {
    _tapAnimController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.index == widget.currentIndex;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFF3B63F6).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 280),
                curve: Curves.elasticOut,
                tween: Tween<double>(begin: 0.85, end: isActive ? 1.15 : 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      isActive ? widget.activeIcon : widget.inactiveIcon,
                      size: 28,
                      color: isActive ? const Color(0xFF3B63F6) : Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 3),
              // Lively active glowing indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 3.5,
                width: isActive ? 16 : 0,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF3B63F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B63F6).withValues(alpha: 0.45),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
