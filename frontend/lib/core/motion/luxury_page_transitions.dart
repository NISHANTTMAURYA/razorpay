import 'package:flutter/material.dart';

/// A luxury, spatial Z-axis page route transition (Linear / Apple Card style).
///
/// As the new page rises into view with a smooth spring-like curve (`Curves.fastLinearToSlowEaseIn`),
/// it scales up from `0.94` to `1.0` while slightly fading in, creating a high-end spatial layer feel.
class SpatialPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SpatialPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.fastLinearToSlowEaseIn,
              reverseCurve: Curves.easeInCubic,
            );

            final scaleTween = Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation);
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
            );
            final slideTween = Tween<Offset>(begin: const Offset(0.0, 0.06), end: Offset.zero)
                .animate(curvedAnimation);

            return SlideTransition(
              position: slideTween,
              child: FadeTransition(
                opacity: fadeTween,
                child: ScaleTransition(
                  scale: scaleTween,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// A luxury, horizontal depth & parallax switcher for bottom navigation tabs.
///
/// Rather than an abrupt swap, the outgoing tab scales down slightly and glides away,
/// while the incoming tab emerges from a 0.96 scale with directional parallax.
class BentoParallaxTabTransition extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const BentoParallaxTabTransition({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: child,
      ),
    );
  }
}
