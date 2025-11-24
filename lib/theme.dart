import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0E0E10),
  primaryColor: Colors.lightBlueAccent,
  colorScheme: const ColorScheme.dark(
    primary: Colors.lightBlueAccent,
    secondary: Colors.blueAccent,
    surface: Color(0xFF121212),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1D),
    elevation: 0,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    iconTheme: IconThemeData(color: Colors.white),
  ),
cardTheme: CardThemeData(
  color: const Color(0xFF1C1C1F),
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlueAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1F1F22),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey.shade500),
  ),
);
