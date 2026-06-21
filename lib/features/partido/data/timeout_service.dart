import 'package:flutter/services.dart';

class TimeoutService {
  void vibrateShort() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void vibrateLong() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
