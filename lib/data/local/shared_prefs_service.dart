import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocked_app.dart';
import '../models/schedule.dart';
import '../../core/constants/app_constants.dart';

class SharedPrefsService {
  static SharedPrefsService? _instance;
  static SharedPreferences? _preferences;

  // Singleton pattern
  SharedPrefsService._();

  static Future<SharedPrefsService> getInstance() async {
    _instance ??= SharedPrefsService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ========== Blocked Apps ==========

  Future<List<BlockedApp>> getBlockedApps() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyBlockedApps);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => BlockedApp.fromJson(json)).toList();
  }

  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final jsonList = apps.map((app) => app.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyBlockedApps, jsonString) ??
        false;
  }

  Future<bool> addBlockedApp(BlockedApp app) async {
    final apps = await getBlockedApps();
    if (!apps.any((a) => a.packageName == app.packageName)) {
      apps.add(app);
      return await saveBlockedApps(apps);
    }
    return false;
  }

  Future<bool> removeBlockedApp(String packageName) async {
    final apps = await getBlockedApps();
    apps.removeWhere((app) => app.packageName == packageName);
    return await saveBlockedApps(apps);
  }

  Future<bool> updateBlockAttempts(String packageName, int attempts) async {
    final apps = await getBlockedApps();
    final index = apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      apps[index] = apps[index].copyWith(blockAttempts: attempts);
      return await saveBlockedApps(apps);
    }
    return false;
  }

  Future<bool> incrementBlockAttempts(String packageName) async {
    final apps = await getBlockedApps();
    final index = apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final currentAttempts = apps[index].blockAttempts;
      apps[index] = apps[index].copyWith(blockAttempts: currentAttempts + 1);
      return await saveBlockedApps(apps);
    }
    return false;
  }

  // ========== Schedules ==========

  Future<List<Schedule>> getSchedules() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keySchedules);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Schedule.fromJson(json)).toList();
  }

  Future<bool> saveSchedules(List<Schedule> schedules) async {
    final jsonList = schedules.map((schedule) => schedule.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keySchedules, jsonString) ??
        false;
  }

  Future<bool> addSchedule(Schedule schedule) async {
    final schedules = await getSchedules();
    if (!schedules.any((s) => s.id == schedule.id)) {
      schedules.add(schedule);
      return await saveSchedules(schedules);
    }
    return false;
  }

  Future<bool> updateSchedule(Schedule schedule) async {
    final schedules = await getSchedules();
    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      schedules[index] = schedule;
      return await saveSchedules(schedules);
    }
    return false;
  }

  Future<bool> removeSchedule(String scheduleId) async {
    final schedules = await getSchedules();
    schedules.removeWhere((schedule) => schedule.id == scheduleId);
    return await saveSchedules(schedules);
  }

  Future<bool> toggleSchedule(String scheduleId) async {
    final schedules = await getSchedules();
    final index = schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      schedules[index] =
          schedules[index].copyWith(isEnabled: !schedules[index].isEnabled);
      return await saveSchedules(schedules);
    }
    return false;
  }

  // ========== Settings ==========

  Future<bool> getDarkMode() async {
    return _preferences?.getBool(AppConstants.keyDarkMode) ?? false;
  }

  Future<bool> setDarkMode(bool value) async {
    return await _preferences?.setBool(AppConstants.keyDarkMode, value) ??
        false;
  }

  Future<String> getUnlockChallengeType() async {
    return _preferences?.getString(AppConstants.keyUnlockChallengeType) ??
        'math';
  }

  Future<bool> setUnlockChallengeType(String type) async {
    return await _preferences?.setString(
            AppConstants.keyUnlockChallengeType, type) ??
        false;
  }

  Future<String?> getSettingsPin() async {
    return _preferences?.getString(AppConstants.keySettingsPin);
  }

  Future<bool> setSettingsPin(String pin) async {
    return await _preferences?.setString(AppConstants.keySettingsPin, pin) ??
        false;
  }

  Future<bool> removeSettingsPin() async {
    return await _preferences?.remove(AppConstants.keySettingsPin) ?? false;
  }

  // ========== Focus Streak ==========

  Future<int> getFocusStreak() async {
    return _preferences?.getInt(AppConstants.keyFocusStreak) ?? 0;
  }

  Future<bool> setFocusStreak(int streak) async {
    return await _preferences?.setInt(AppConstants.keyFocusStreak, streak) ??
        false;
  }

  Future<String?> getLastFocusDate() async {
    return _preferences?.getString(AppConstants.keyLastFocusDate);
  }

  Future<bool> setLastFocusDate(String date) async {
    return await _preferences?.setString(
            AppConstants.keyLastFocusDate, date) ??
        false;
  }

  // ========== Clear All Data ==========

  Future<bool> clearAllData() async {
    return await _preferences?.clear() ?? false;
  }
}
