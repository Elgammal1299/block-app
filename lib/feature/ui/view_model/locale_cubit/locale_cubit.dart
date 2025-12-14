import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final SettingsRepository _settingsRepository;

  LocaleCubit(this._settingsRepository) : super(LocaleInitial()) {
    loadLocale();
  }

  Future<void> loadLocale() async {
    try {
      final languageCode = await _settingsRepository.getLanguageCode();
      final locale = Locale(languageCode ?? 'en');
      emit(LocaleLoaded(locale));
    } catch (e) {
      emit(const LocaleLoaded(Locale('en'))); // Default to English
    }
  }

  Future<void> changeLocale(Locale locale) async {
    try {
      await _settingsRepository.setLanguageCode(locale.languageCode);
      emit(LocaleLoaded(locale));
    } catch (e) {
      // Handle error silently or emit error state if needed
    }
  }

  Future<void> toggleLocale() async {
    if (state is LocaleLoaded) {
      final currentState = state as LocaleLoaded;
      final newLocale = currentState.isArabic
          ? const Locale('en')
          : const Locale('ar');
      await changeLocale(newLocale);
    }
  }
}
