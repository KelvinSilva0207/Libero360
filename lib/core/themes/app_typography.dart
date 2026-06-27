import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme forFont(String font) {
    return switch (font) {
      'roboto' => GoogleFonts.robotoTextTheme(),
      'inter' => GoogleFonts.interTextTheme(),
      'openSans' => GoogleFonts.openSansTextTheme(),
      'nunito' => GoogleFonts.nunitoTextTheme(),
      _ => ThemeData.light().textTheme,
    };
  }
}
