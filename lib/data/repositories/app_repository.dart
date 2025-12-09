import 'dart:convert';
import '../models/app_info.dart';
import '../models/blocked_app.dart';
import '../local/shared_prefs_service.dart';
import '../../services/platform_channel_service.dart';

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

  // Get usage statistics
  Future<Map<String, int>> getAppUsageStats(DateTime startTime, DateTime endTime) async {
    return await _platformService.getAppUsageStats(startTime, endTime);
  }
}
