import 'package:flutter/material.dart';
import 'package:neonnekko/theme/app_themes.dart';

class ThemeService with ChangeNotifier {
  String _currentThemeKey = 'Catppuccin'; // Default to the preferred theme

  ThemeData get currentTheme => getAppThemes()[_currentThemeKey] ?? getAppThemes()['Catppuccin']!;
  String get currentThemeKey => _currentThemeKey;
  
  final Map<String, ThemeData> availableThemes = getAppThemes();

  void setTheme(String themeKey) {
    if (availableThemes.containsKey(themeKey)) {
      _currentThemeKey = themeKey;
      notifyListeners();
      // TODO: Save _currentThemeKey to Supabase or SharedPreferences here
    }
  }
}