import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocked_app.dart';
import '../models/schedule.dart';
import '../models/app_usage_limit.dart';
import '../models/focus_list.dart';
import '../models/focus_session.dart';
import '../models/focus_session_history.dart';
import '../models/focus_mode_config.dart';
import '../models/custom_focus_mode.dart';
import '../../../core/constants/app_constants.dart';

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

  // ========== Usage Limits ==========

  Future<List<AppUsageLimit>> getUsageLimits() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyUsageLimits);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => AppUsageLimit.fromJson(json)).toList();
  }

  Future<bool> saveUsageLimits(List<AppUsageLimit> limits) async {
    final jsonList = limits.map((limit) => limit.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyUsageLimits, jsonString) ??
        false;
  }

  Future<bool> updateUsageTime(String packageName, int usedMinutes) async {
    final limits = await getUsageLimits();
    final index = limits.indexWhere((l) => l.packageName == packageName);
    if (index != -1) {
      limits[index] = limits[index].copyWith(usedMinutesToday: usedMinutes);
      return await saveUsageLimits(limits);
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

  Future<String?> getLanguageCode() async {
    return _preferences?.getString(AppConstants.keyLanguageCode);
  }

  Future<bool> setLanguageCode(String languageCode) async {
    return await _preferences?.setString(AppConstants.keyLanguageCode, languageCode) ??
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

  // ========== Block Screen Style ==========

  Future<String> getBlockScreenStyle() async {
    // Default style is 'classic'
    return _preferences?.getString(AppConstants.keyBlockScreenStyle) ??
        'classic';
  }

  Future<bool> setBlockScreenStyle(String style) async {
    return await _preferences?.setString(
            AppConstants.keyBlockScreenStyle, style) ??
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

  // ========== Focus Lists ==========

  Future<List<FocusList>> getFocusLists() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyFocusLists);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => FocusList.fromJson(json)).toList();
  }

  Future<bool> saveFocusLists(List<FocusList> lists) async {
    final jsonList = lists.map((list) => list.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyFocusLists, jsonString) ??
        false;
  }

  Future<bool> addFocusList(FocusList list) async {
    final lists = await getFocusLists();
    if (!lists.any((l) => l.id == list.id)) {
      lists.add(list);
      return await saveFocusLists(lists);
    }
    return false;
  }

  Future<bool> updateFocusList(FocusList list) async {
    final lists = await getFocusLists();
    final index = lists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      lists[index] = list;
      return await saveFocusLists(lists);
    }
    return false;
  }

  Future<bool> deleteFocusList(String id) async {
    final lists = await getFocusLists();
    lists.removeWhere((list) => list.id == id);
    return await saveFocusLists(lists);
  }

  // ========== Active Focus Session ==========

  Future<FocusSession?> getActiveSession() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyActiveFocusSession);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return FocusSession.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveActiveSession(FocusSession? session) async {
    if (session == null) {
      return await clearActiveSession();
    }
    final jsonString = json.encode(session.toJson());
    return await _preferences?.setString(
            AppConstants.keyActiveFocusSession, jsonString) ??
        false;
  }

  Future<bool> clearActiveSession() async {
    return await _preferences?.remove(AppConstants.keyActiveFocusSession) ??
        false;
  }

  // ========== Focus Session History ==========

  Future<List<FocusSessionHistory>> getSessionHistory({int limit = 50}) async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyFocusSessionHistory);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    final List<FocusSessionHistory> history =
        jsonList.map((json) => FocusSessionHistory.fromJson(json)).toList();

    // Sort by date descending and limit
    history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return history.take(limit).toList();
  }

  Future<bool> addSessionToHistory(FocusSessionHistory session) async {
    final history = await getSessionHistory(limit: 1000); // Get all first
    history.insert(0, session); // Add at beginning

    // Keep only last 100 entries
    final limitedHistory = history.take(100).toList();

    final jsonList = limitedHistory.map((h) => h.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyFocusSessionHistory, jsonString) ??
        false;
  }

  Future<bool> clearOldHistory({int keepLast = 100}) async {
    final history = await getSessionHistory(limit: 1000);
    final limitedHistory = history.take(keepLast).toList();

    final jsonList = limitedHistory.map((h) => h.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyFocusSessionHistory, jsonString) ??
        false;
  }

  Future<bool> clearAllHistory() async {
    return await _preferences?.remove(AppConstants.keyFocusSessionHistory) ??
        false;
  }

  // ========== Focus Mode Configs ==========

  Future<List<FocusModeConfig>> getFocusModeConfigs() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyFocusModeConfigs);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => FocusModeConfig.fromJson(json)).toList();
  }

  Future<bool> saveFocusModeConfigs(List<FocusModeConfig> configs) async {
    final jsonList = configs.map((config) => config.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyFocusModeConfigs, jsonString) ??
        false;
  }

  Future<bool> saveFocusModeConfig(FocusModeConfig config) async {
    final configs = await getFocusModeConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);

    if (index != -1) {
      // Update existing
      configs[index] = config;
    } else {
      // Add new
      configs.add(config);
    }

    return await saveFocusModeConfigs(configs);
  }

  Future<bool> updateFocusModeConfig(FocusModeConfig config) async {
    final configs = await getFocusModeConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);

    if (index != -1) {
      configs[index] = config;
      return await saveFocusModeConfigs(configs);
    }

    return false;
  }

  Future<bool> deleteFocusModeConfig(String id) async {
    final configs = await getFocusModeConfigs();
    configs.removeWhere((config) => config.id == id);
    return await saveFocusModeConfigs(configs);
  }

  // ========== Custom Focus Modes ==========

  Future<List<CustomFocusMode>> getCustomFocusModes() async {
    final String? jsonString =
        _preferences?.getString(AppConstants.keyCustomFocusModes);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => CustomFocusMode.fromJson(json)).toList();
  }

  Future<bool> saveCustomFocusModes(List<CustomFocusMode> modes) async {
    final jsonList = modes.map((mode) => mode.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return await _preferences?.setString(
            AppConstants.keyCustomFocusModes, jsonString) ??
        false;
  }

  Future<bool> addCustomFocusMode(CustomFocusMode mode) async {
    final modes = await getCustomFocusModes();
    if (!modes.any((m) => m.id == mode.id)) {
      modes.add(mode);
      return await saveCustomFocusModes(modes);
    }
    return false;
  }

  Future<bool> updateCustomFocusMode(CustomFocusMode mode) async {
    final modes = await getCustomFocusModes();
    final index = modes.indexWhere((m) => m.id == mode.id);
    if (index != -1) {
      modes[index] = mode;
      return await saveCustomFocusModes(modes);
    }
    return false;
  }

  Future<bool> deleteCustomFocusMode(String id) async {
    final modes = await getCustomFocusModes();
    modes.removeWhere((mode) => mode.id == id);
    return await saveCustomFocusModes(modes);
  }

  Future<CustomFocusMode?> getCustomFocusModeById(String id) async {
    final modes = await getCustomFocusModes();
    try {
      return modes.firstWhere((mode) => mode.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== Presets Initialization Flag ==========

  Future<bool> getPresetsInitialized() async {
    return _preferences?.getBool(AppConstants.keyPresetsInitialized) ?? false;
  }

  Future<bool> setPresetsInitialized(bool value) async {
    return await _preferences?.setBool(
            AppConstants.keyPresetsInitialized, value) ??
        false;
  }

  // ========== Clear All Data ==========

  Future<bool> clearAllData() async {
    return await _preferences?.clear() ?? false;
  }

  // ========== Generic Getters/Setters for new features ==========

  String? getString(String key) {
    return _preferences?.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  Set<String> getKeys() {
    return _preferences?.getKeys() ?? {};
  }
}
