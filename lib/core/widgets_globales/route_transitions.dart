import 'package:flutter/material.dart';

Route<T> slideRightRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

Route<T> fadeScaleRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 250)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}

extension NavigateWithTransition on BuildContext {
  Future<T?> pushSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(slideRightRoute(page));
  }

  Future<T?> pushReplaceSlide<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, dynamic>(slideRightRoute(page));
  }
}
