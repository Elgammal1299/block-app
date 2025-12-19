import 'dart:convert';
import '../models/app_info.dart';
import '../models/blocked_app.dart';
import '../models/app_usage_limit.dart';
import '../local/shared_prefs_service.dart';
import '../../../core/services/platform_channel_service.dart';

class AppRepository {
  final SharedPrefsService _prefsService;
  final PlatformChannelService _platformService;

  AppRepository(this._prefsService, this._platformService);

  // Get all installed apps from native side
  Future<List<AppInfo>> getInstalledApps() async {
    return await _platformService.getInstalledApps();
  }

  // Get blocked apps from local storage
  Future<List<BlockedApp>> getBlockedApps() async {
    return await _prefsService.getBlockedApps();
  }

  // Add app to blocked list
  Future<bool> addBlockedApp(BlockedApp app) async {
    final result = await _prefsService.addBlockedApp(app);
    if (result) {
      // Sync with native side
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Remove app from blocked list
  Future<bool> removeBlockedApp(String packageName) async {
    final result = await _prefsService.removeBlockedApp(packageName);
    if (result) {
      // Sync with native side
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Save multiple blocked apps
  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final result = await _prefsService.saveBlockedApps(apps);
    if (result) {
      // Sync with native side
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Sync blocked apps to native Android
  Future<void> _syncBlockedAppsToNative() async {
    final blockedApps = await _prefsService.getBlockedApps();
    // Send full app data as JSON to native side
    final appsJson = jsonEncode(blockedApps.map((app) => app.toJson()).toList());
    await _platformService.updateBlockedAppsJson(appsJson);
  }

  // Get block attempts for a package
  Future<int> getBlockAttempts(String packageName) async {
    final apps = await _prefsService.getBlockedApps();
    final app = apps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => BlockedApp(packageName: packageName, appName: ''),
    );
    return app.blockAttempts;
  }

  // Increment block attempts
  Future<bool> incrementBlockAttempts(String packageName) async {
    return await _prefsService.incrementBlockAttempts(packageName);
  }

  // Get total block attempts across all blocked apps
  Future<int> getTotalBlockAttempts() async {
    final apps = await _prefsService.getBlockedApps();
    return apps.fold<int>(0, (sum, app) => sum + app.blockAttempts);
  }

  // Sync block attempts from native Android to Flutter
  // Timestamp of last sync to avoid redundant syncs
  static DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(seconds: 5);

  Future<void> syncBlockAttemptsFromNative({bool force = false}) async {
    try {
      // Check if we synced recently (within last 5 seconds) - avoid redundant syncs
      if (!force && _lastSyncTime != null) {
        final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
        if (timeSinceLastSync < _syncCooldown) {
          // Too soon, skip sync
          return;
        }
      }

      // Get the latest blocked apps JSON from Android SharedPreferences
      final nativeJson = await _platformService.getBlockedAppsJsonFromNative();
      if (nativeJson != null && nativeJson.isNotEmpty && nativeJson != '[]') {
        // Parse the JSON and update Flutter SharedPreferences
        final List<dynamic> jsonList = jsonDecode(nativeJson);
        final nativeApps = jsonList.map((json) => BlockedApp.fromJson(json)).toList();

        // Get current apps from Flutter
        final currentApps = await _prefsService.getBlockedApps();

        bool hasChanges = false;

        // Update block attempts for each app
        for (final nativeApp in nativeApps) {
          final index = currentApps.indexWhere(
            (app) => app.packageName == nativeApp.packageName,
          );
          if (index != -1) {
            // Update the block attempts if changed
            if (currentApps[index].blockAttempts != nativeApp.blockAttempts) {
              currentApps[index] = currentApps[index].copyWith(
                blockAttempts: nativeApp.blockAttempts,
              );
              hasChanges = true;
            }
          }
        }

        // Only save if there were actual changes
        if (hasChanges) {
          await _prefsService.saveBlockedApps(currentApps);
          print('Synced block attempts from native (${nativeApps.length} apps)');
        }

        // Update last sync timestamp
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      print('Error syncing block attempts from native: $e');
    }
  }

  // Get usage statistics
  Future<Map<String, int>> getAppUsageStats(DateTime startTime, DateTime endTime) async {
    return await _platformService.getAppUsageStats(startTime, endTime);
  }

  // ==================== Usage Limits ====================

  // Get all usage limits from local storage
  Future<List<AppUsageLimit>> getUsageLimits() async {
    return await _prefsService.getUsageLimits();
  }

  // Save usage limits to local storage and sync with native
  Future<bool> saveUsageLimits(List<AppUsageLimit> limits) async {
    final result = await _prefsService.saveUsageLimits(limits);
    if (result) {
      // Sync with native side
      await _syncUsageLimitsToNative(limits);
    }
    return result;
  }

  // Sync usage limits to native Android
  Future<void> _syncUsageLimitsToNative(List<AppUsageLimit> limits) async {
    // Send usage limits as JSON to native side for monitoring
    final limitsJson = jsonEncode(limits.map((limit) => limit.toJson()).toList());
    await _platformService.updateUsageLimitsJson(limitsJson);
  }

  // Get a specific usage limit
  Future<AppUsageLimit?> getUsageLimit(String packageName) async {
    final limits = await _prefsService.getUsageLimits();
    try {
      return limits.firstWhere((l) => l.packageName == packageName);
    } catch (e) {
      return null;
    }
  }

  // Update usage time for an app
  Future<bool> updateUsageTime(String packageName, int usedMinutes) async {
    return await _prefsService.updateUsageTime(packageName, usedMinutes);
  }
}
