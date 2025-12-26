import 'package:flutter/material.dart';
import 'package:neonnekko/theme/app_themes.dart'; 
import 'package:shadcn_ui/shadcn_ui.dart';

class ThemeService with ChangeNotifier {
  String _currentThemeKey = 'light Mode';

  ThemeData get currentTheme => getAppThemes()[_currentThemeKey] ?? getAppThemes()['Catppuccin']!;
  
  ShadThemeData get currentShadTheme => getShadThemes()[_currentThemeKey] ?? getShadThemes()['Catppuccin']!;
  
  String get currentThemeKey => _currentThemeKey;

  Map<String, ShadThemeData> get availableThemes => getShadThemes();
  
  bool get isDarkMode => _currentThemeKey == 'Dark Mode' || _currentThemeKey == 'Catppuccin';

  void setTheme(String themeKey) {
    if (getAppThemes().containsKey(themeKey)) {
      _currentThemeKey = themeKey;
      notifyListeners();
    }
  }
}