import 'package:flutter/material.dart';
import '../data/repositories/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  bool _isDarkMode = false;

  ThemeProvider(this._settingsRepository) {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadTheme() async {
    _isDarkMode = await _settingsRepository.getDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsRepository.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      await _settingsRepository.setDarkMode(_isDarkMode);
      notifyListeners();
    }
  }
}
