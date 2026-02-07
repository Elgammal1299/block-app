import '../models/app_info.dart';
import '../models/blocked_app.dart';
import '../models/app_usage_limit.dart';
import '../local/shared_prefs_service.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../../core/services/cached_prefs_service.dart';
import '../../../core/utils/app_logger.dart';
import 'app_repository_isolate_helper.dart';

class AppRepository {
  final SharedPrefsService _prefsService;
  final CachedPreferencesService _cachedPrefsService;
  final PlatformChannelService _platformService;

  AppRepository(this._prefsService, this._platformService,
      [CachedPreferencesService? cachedPrefsService])
      : _cachedPrefsService =
            cachedPrefsService ?? CachedPreferencesService(_prefsService);

  // Get all installed apps from native side
  Future<List<AppInfo>> getInstalledApps() async {
    return await _platformService.getInstalledApps();
  }

  // Get blocked apps from local storage (via cache for performance)
  Future<List<BlockedApp>> getBlockedApps() async {
    return await _cachedPrefsService.getBlockedApps();
  }

  // Add app to blocked list
  Future<bool> addBlockedApp(BlockedApp app) async {
    print('🟢 [ADD] Adding app: ${app.packageName}');
    final result = await _cachedPrefsService.addBlockedApp(app);
    print('🟢 [ADD] Result: $result');
    if (result) {
      // Sync with native side
      print('🟢 [ADD] Syncing to native...');
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Remove app from blocked list
  Future<bool> removeBlockedApp(String packageName) async {
    final result = await _cachedPrefsService.removeBlockedApp(packageName);
    if (result) {
      // Sync with native side
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Save multiple blocked apps
  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final result = await _cachedPrefsService.saveBlockedApps(apps);
    if (result) {
      // Sync with native side
      await _syncBlockedAppsToNative();
    }
    return result;
  }

  // Sync blocked apps to native Android
  Future<void> _syncBlockedAppsToNative() async {
    print('🔴 [SYNC] Starting sync to native...');
    final blockedApps = await _cachedPrefsService.getBlockedApps();
    print('🔴 [SYNC] Blocked apps in cache: ${blockedApps.length}');
    blockedApps.forEach((app) {
      print('🔴 [SYNC]   - ${app.packageName} (blocked: ${app.isBlocked})');
    });
    
    // Phase 2: Use isolate for JSON encoding to prevent main thread blocking
    final appsJson = await AppRepositoryIsolateHelper.encodeBlockedAppsJson(
      blockedApps,
    );
    print('🔴 [SYNC] JSON encoded: ${appsJson.substring(0, (appsJson.length > 500 ? 500 : appsJson.length))}...');
    print('🔴 [SYNC] JSON size: ${appsJson.length} bytes');
    
    await _platformService.updateBlockedAppsJson(appsJson);
    print('🔴 [SYNC] ✅ Sync completed to native!');
  }

  // Get block attempts for a package
  Future<int> getBlockAttempts(String packageName) async {
    final apps = await _cachedPrefsService.getBlockedApps();
    final app = apps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => BlockedApp(packageName: packageName, appName: ''),
    );
    return app.blockAttempts;
  }

  // Increment block attempts
  Future<bool> incrementBlockAttempts(String packageName) async {
    return await _cachedPrefsService.incrementBlockAttempts(packageName);
  }

  // Get total block attempts across all blocked apps
  Future<int> getTotalBlockAttempts() async {
    final apps = await _cachedPrefsService.getBlockedApps();
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
        // Phase 2: Use isolate for heavy JSON parsing and merging
        final currentApps = await _cachedPrefsService.getBlockedApps();
        final updatedApps =
            await AppRepositoryIsolateHelper.syncBlockAttemptsFromNativeJson(
          nativeJson,
          currentApps,
        );

        // Check if there were actual changes
        bool hasChanges = false;
        for (int i = 0; i < currentApps.length; i++) {
          if (currentApps[i].blockAttempts != updatedApps[i].blockAttempts) {
            hasChanges = true;
            break;
          }
        }

        // Only save if there were actual changes
        if (hasChanges) {
          await _cachedPrefsService.saveBlockedApps(updatedApps);
          AppLogger.i(
            'Synced block attempts from native (${updatedApps.length} apps)',
          );
        }

        // Update last sync timestamp
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      AppLogger.e('Error syncing block attempts from native', e);
    }
  }

  // Get usage statistics
  Future<Map<String, int>> getAppUsageStats(
    DateTime startTime,
    DateTime endTime,
  ) async {
    return await _platformService.getAppUsageStats(startTime, endTime);
  }

  // ==================== Usage Limits ====================

  // Get all usage limits from local storage (via cache)
  Future<List<AppUsageLimit>> getUsageLimits() async {
    final limitsList = await _cachedPrefsService.getUsageLimits();
    return limitsList;
  }

  // Save usage limits to local storage and sync with native
  Future<bool> saveUsageLimits(List<AppUsageLimit> limits) async {
    final result = await _cachedPrefsService.saveUsageLimits(limits);
    if (result) {
      // Sync with native side
      await _syncUsageLimitsToNative(limits);
    }
    return result;
  }

  // Sync usage limits to native Android
  Future<void> _syncUsageLimitsToNative(List<AppUsageLimit> limits) async {
    // Phase 2: Use isolate for JSON encoding
    final limitsJson = await AppRepositoryIsolateHelper.encodeUsageLimitsJson(
      limits,
    );
    await _platformService.updateUsageLimitsJson(limitsJson);
  }

  // Get a specific usage limit
  Future<AppUsageLimit?> getUsageLimit(String packageName) async {
    final limitsList = await _cachedPrefsService.getUsageLimits();
    // Convert list to map for lookup
    final limitsAsMap = {for (var limit in limitsList) limit.packageName: limit};
    return limitsAsMap[packageName];
  }

  // Update usage time for an app
  Future<bool> updateUsageTime(String packageName, int usedMinutes) async {
    return await _prefsService.updateUsageTime(packageName, usedMinutes);
  }
}
