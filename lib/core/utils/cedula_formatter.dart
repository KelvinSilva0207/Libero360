import 'package:flutter/services.dart';
import '../services/log_service.dart';

class CedulaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    int cursorDigitPos = 0;
    final sel = newValue.selection;
    if (sel.isValid && sel.baseOffset > 0) {
      for (int i = 0; i < sel.baseOffset && i < newValue.text.length; i++) {
        if (_isDigit(newValue.text[i])) {
          cursorDigitPos++;
        }
      }
    } else {
      cursorDigitPos = digitsOnly.length;
    }

    final formatted = _formatThousands(digitsOnly);

    int cursorPos = 0;
    int digitsSeen = 0;
    while (cursorPos < formatted.length && digitsSeen < cursorDigitPos) {
      if (_isDigit(formatted[cursorPos])) {
        digitsSeen++;
      }
      cursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  /// Formats raw digits into thousands-separated format (e.g., 30258963 → 30.258.963)
  static String format(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    final result = _formatThousands(digits);
    if (digits.isNotEmpty) {
      LogService.instance.auto('CÉDULA: formatting — $digits → $result');
    }
    return result;
  }

  /// Strips all separators, returning only digits
  static String unformat(String formatted) {
    return formatted.replaceAll('.', '');
  }

  /// Returns true if the string contains at least one digit
  static bool isValid(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    return digits.isNotEmpty;
  }
}

String formatCedula(String raw) {
  return CedulaFormatter.format(raw);
}

String unformatCedula(String formatted) {
  return CedulaFormatter.unformat(formatted);
}

String _formatThousands(String digits) {
  if (digits.isEmpty) return '';
  final len = digits.length;
  if (len <= 3) return digits;
  final buffer = StringBuffer();
  int firstGroup = len % 3;
  if (firstGroup == 0) firstGroup = 3;
  for (int i = 0; i < len; i++) {
    if (i == firstGroup || (i > firstGroup && (i - firstGroup) % 3 == 0)) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
