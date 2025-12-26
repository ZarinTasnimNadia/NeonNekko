import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const Color kawaiiPink = Color(0xFFF5A6CD); 
const Color kawaiiLavender = Color(0xFFE4D3EC); 
const Color darkSurface = Color(0xFF1E1E2E); 
const Color darkText = Color(0xFFD9E0EE);
const Color sakuraPurple = Color(0xFF9B59B6);

Map<String, ThemeData> getAppThemes() {
  return {
    'Light Mode': _lightTheme,
    'Dark Mode': _darkTheme,
    'Catppuccin': _catppuccinTheme,
  };
}

Map<String, ShadThemeData> getShadThemes() {
  return {
    'Light Mode': ShadThemeData(
      brightness: Brightness.light,
      colorScheme: ShadZincColorScheme.light(
        primary: kawaiiPink,
        background: const Color(0xFFFFF5F8),
        foreground: sakuraPurple,
        card: kawaiiLavender,
      ),
    ),
    'Dark Mode': ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: ShadZincColorScheme.dark(
        primary: kawaiiPink,
        background: darkSurface,
        foreground: darkText,
        card: const Color(0xFF2D1B36),
      ),
    ),
    'Catppuccin': ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: ShadZincColorScheme.dark(
        primary: kawaiiPink,
        background: darkSurface,
        foreground: darkText,
        card: const Color(0xFF2D1B36),
        secondary: kawaiiLavender,
      ),
    ),
  };
}

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kawaiiPink,
  scaffoldBackgroundColor: const Color.fromARGB(255, 248, 194, 229),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 237, 123, 201),
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  colorScheme: ColorScheme.light(
    primary: kawaiiPink,
    secondary: sakuraPurple,
    surface: kawaiiLavender,
  ),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: sakuraPurple,
  scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2D1B36),
    foregroundColor: darkText,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  colorScheme: ColorScheme.dark(
    primary: kawaiiPink,
    secondary: sakuraPurple,
    surface: const Color(0xFF2D1B36),
  ),
);

final ThemeData _catppuccinTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: kawaiiPink,
  scaffoldBackgroundColor: const Color.fromARGB(255, 62, 6, 65),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 90, 1, 81),
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  colorScheme: ColorScheme.dark(
    primary: kawaiiPink,
    secondary: kawaiiLavender,
    surface: const Color(0xFF2D1B36),
  ),
);