import 'package:flutter/material.dart';

const teal = Color(0xFF0D8F8A);
const deepTeal = Color(0xFF085E5A);
const gold = Color(0xFFE9B44C);
const paper = Color(0xFFF7F6F2);
const ink = Color(0xFF1F2933);
const muted = Color(0xFF66737A);

class AppMotion {
  static const quick = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const gentle = Duration(milliseconds: 320);
  static const page = Duration(milliseconds: 420);
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final incomingSlide = Tween<Offset>(
      begin: const Offset(.12, 0),
      end: Offset.zero,
    ).animate(curved);
    final incomingScale = Tween<double>(begin: .94, end: 1).animate(curved);

    // Give the page underneath a subtle push-back while the new page arrives.
    // This creates the shared-axis feeling from the visual references without
    // making navigation feel slow or theatrical.
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, page) {
        final pushed = secondaryAnimation.value;
        return Opacity(
          opacity: 1 - (pushed * .12),
          child: Transform.translate(
            offset: Offset(-18 * pushed, 0),
            child: Transform.scale(
              alignment: Alignment.center,
              scale: 1 - (pushed * .025),
              child: FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: incomingSlide,
                  child: ScaleTransition(scale: incomingScale, child: page),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
