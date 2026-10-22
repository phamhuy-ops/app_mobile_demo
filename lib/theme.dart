import 'package:flutter/material.dart';

const navy = Color(0xff071e32);
const navyMid = Color(0xff0e3554);
const signal = Color(0xffd61f2e);
const gold = Color(0xffc79212);
const mist = Color(0xffeef3f6);
const ink = Color(0xff102433);
const muted = Color(0xff5c7384);
const paper = Color(0xfff7f4ee);

ThemeData buildNaviTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: navy,
    onPrimary: Colors.white,
    secondary: navyMid,
    onSecondary: Colors.white,
    error: signal,
    onError: Colors.white,
    surface: paper,
    onSurface: ink,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: Color(0xffc5d4de)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}
