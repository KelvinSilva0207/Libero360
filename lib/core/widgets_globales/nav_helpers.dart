import 'package:flutter/material.dart';

extension NavHelper on BuildContext {
  void popToDashboard() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }

  void safePop<T>([T? result]) {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop(result);
    }
  }
}
