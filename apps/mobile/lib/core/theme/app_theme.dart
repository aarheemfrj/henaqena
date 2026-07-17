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
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: const Offset(.045, 0), end: Offset.zero).animate(curved), child: ScaleTransition(scale: Tween<double>(begin: .985, end: 1).animate(curved), child: child)));
  }
}
