import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/schedule.dart';
import '../models/block_screen_theme.dart';
import '../local/shared_prefs_service.dart';
import '../../../core/services/platform_channel_service.dart';

class SettingsRepository {
  final SharedPrefsService _prefsService;
  final PlatformChannelService _platformService;

  SettingsRepository(this._prefsService, this._platformService);

  // ========== Schedules ==========

  Future<List<Schedule>> getSchedules() async {
    return await _prefsService.getSchedules();
  }

  Future<bool> addSchedule(Schedule schedule) async {
    final result = await _prefsService.addSchedule(schedule);
    if (result) {
      await _syncSchedulesToNative();
    }
    return result;
  }

  Future<bool> updateSchedule(Schedule schedule) async {
    final result = await _prefsService.updateSchedule(schedule);
    if (result) {
      await _syncSchedulesToNative();
    }
    return result;
  }

  Future<bool> removeSchedule(String scheduleId) async {
    final result = await _prefsService.removeSchedule(scheduleId);
    if (result) {
      await _syncSchedulesToNative();
    }
    return result;
  }

  Future<bool> toggleSchedule(String scheduleId) async {
    final result = await _prefsService.toggleSchedule(scheduleId);
    if (result) {
      await _syncSchedulesToNative();
    }
    return result;
  }

  Future<void> _syncSchedulesToNative() async {
    final schedules = await _prefsService.getSchedules();
    await _platformService.updateSchedules(schedules);
  }

  // ========== Dark Mode ==========

  Future<bool> getDarkMode() async {
    return await _prefsService.getDarkMode();
  }

  Future<bool> setDarkMode(bool value) async {
    return await _prefsService.setDarkMode(value);
  }

  // ========== Language ==========

  Future<String?> getLanguageCode() async {
    return await _prefsService.getLanguageCode();
  }

  Future<bool> setLanguageCode(String languageCode) async {
    return await _prefsService.setLanguageCode(languageCode);
  }

  // ========== Unlock Challenge Type ==========

  Future<String> getUnlockChallengeType() async {
    return await _prefsService.getUnlockChallengeType();
  }

  Future<bool> setUnlockChallengeType(String type) async {
    return await _prefsService.setUnlockChallengeType(type);
  }

  // ========== Block Screen Style ==========

  Future<String> getBlockScreenStyle() async {
    return await _prefsService.getBlockScreenStyle();
  }

  Future<bool> setBlockScreenStyle(String style) async {
    return await _prefsService.setBlockScreenStyle(style);
  }

  Future<String> getBlockScreenColor() async {
    return await _prefsService.getBlockScreenColor();
  }

  Future<bool> setBlockScreenColor(String color) async {
    final result = await _prefsService.setBlockScreenColor(color);
    if (result) {
      await _syncCustomizationToNative();
    }
    return result;
  }

  Future<String> getBlockScreenQuote() async {
    return await _prefsService.getBlockScreenQuote();
  }

  Future<bool> setBlockScreenQuote(String quote) async {
    final result = await _prefsService.setBlockScreenQuote(quote);
    if (result) {
      await _syncCustomizationToNative();
    }
    return result;
  }

  Future<void> _syncCustomizationToNative() async {
    final color = await _prefsService.getBlockScreenColor();
    final quote = await _prefsService.getBlockScreenQuote();
    await _platformService.syncBlockScreenCustomization(color, quote);
  }

  Future<List<BlockScreenTheme>> getBlockScreenThemes() async {
    return await _prefsService.getBlockScreenThemes();
  }

  Future<bool> saveBlockScreenThemes(List<BlockScreenTheme> themes) async {
    return await _prefsService.saveBlockScreenThemes(themes);
  }

  // ========== PIN Protection ==========

  Future<String?> getSettingsPin() async {
    return await _prefsService.getSettingsPin();
  }

  Future<bool> setSettingsPin(String pin) async {
    // Hash the PIN before storing
    final hashedPin = _hashPin(pin);
    return await _prefsService.setSettingsPin(hashedPin);
  }

  Future<bool> removeSettingsPin() async {
    return await _prefsService.removeSettingsPin();
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _prefsService.getSettingsPin();
    if (storedPin == null) return true; // No PIN set

    final hashedPin = _hashPin(pin);
    return hashedPin == storedPin;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // ========== Focus Streak ==========

  Future<int> getFocusStreak() async {
    return await _prefsService.getFocusStreak();
  }

  Future<bool> setFocusStreak(int streak) async {
    return await _prefsService.setFocusStreak(streak);
  }

  Future<String?> getLastFocusDate() async {
    return await _prefsService.getLastFocusDate();
  }

  Future<bool> setLastFocusDate(String date) async {
    return await _prefsService.setLastFocusDate(date);
  }

  // Update focus streak (call this daily)
  Future<void> updateFocusStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final lastFocusDate = await getLastFocusDate();

    if (lastFocusDate == null) {
      // First time
      await setFocusStreak(1);
      await setLastFocusDate(today);
    } else {
      final lastDate = DateTime.parse(lastFocusDate);
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      if (lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        // Already updated today, do nothing
        return;
      } else if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        // Consecutive day - increment streak
        final currentStreak = await getFocusStreak();
        await setFocusStreak(currentStreak + 1);
        await setLastFocusDate(today);
      } else {
        // Streak broken - reset to 1
        await setFocusStreak(1);
        await setLastFocusDate(today);
      }
    }
  }
}
