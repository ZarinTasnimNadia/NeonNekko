import 'package:flutter/material.dart';

// --- Base Theme Colors ---
const Color kawaiiPink = Color(0xFFF5A6CD); 
const Color kawaiiLavender = Color(0xFFE4D3EC); 
const Color darkSurface = Color(0xFF1E1E2E); 
const Color darkText = Color(0xFFD9E0EE); 

// --- Theme Map ---
Map<String, ThemeData> getAppThemes() {
  return {
    'Light Mode': _lightTheme,
    'Dark Mode': _darkTheme,
    'Catppuccin': _catppuccinTheme, // The default "Kawaii" style
  };
}

// --- Shared Input Decoration (The "Box" Look) ---
const InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
    borderSide: BorderSide(width: 2.0),
  ),
  labelStyle: TextStyle(fontWeight: FontWeight.w500),
);


// 1. Light Theme
final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blueAccent,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: _inputDecorationTheme.copyWith(
    fillColor: Colors.grey.shade100,
    focusedBorder: _inputDecorationTheme.focusedBorder?.copyWith(
      borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
);


// 2. Dark Theme
final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.tealAccent,
  scaffoldBackgroundColor: darkSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF282A36),
    foregroundColor: darkText,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: _inputDecorationTheme.copyWith(
    fillColor: const Color(0xFF383A59),
    labelStyle: const TextStyle(color: darkText),
    focusedBorder: _inputDecorationTheme.focusedBorder?.copyWith(
      borderSide: const BorderSide(color: Colors.tealAccent, width: 2.0),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.tealAccent,
      foregroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
);


// 3. Catppuccin Theme (The "Kawaii" Pink/Lavender style)
final ThemeData _catppuccinTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kawaiiPink,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: kawaiiPink,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: _inputDecorationTheme.copyWith(
    fillColor: kawaiiLavender, // Soft purple box color
    focusedBorder: _inputDecorationTheme.focusedBorder?.copyWith(
      borderSide: const BorderSide(color: kawaiiPink, width: 2.0),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kawaiiPink,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
);