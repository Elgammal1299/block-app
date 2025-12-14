import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository _settingsRepository;

  ThemeCubit(this._settingsRepository) : super(ThemeInitial()) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    emit(ThemeLoading());
    final isDarkMode = await _settingsRepository.getDarkMode();
    emit(ThemeLoaded(isDarkMode));
  }

  Future<void> toggleTheme() async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;
      final newValue = !currentState.isDarkMode;
      await _settingsRepository.setDarkMode(newValue);
      emit(ThemeLoaded(newValue));
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;
      if (currentState.isDarkMode != value) {
        await _settingsRepository.setDarkMode(value);
        emit(ThemeLoaded(value));
      }
    }
  }
}
