import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../feature/data/models/app_info.dart';
import '../../feature/data/models/schedule.dart';
import '../utils/app_logger.dart';

class PlatformChannelService {
  static final PlatformChannelService _instance =
      PlatformChannelService._internal();
  factory PlatformChannelService() => _instance;
  PlatformChannelService._internal();

  final MethodChannel _channel = const MethodChannel(AppConstants.channelName);

  // Callback handlers
  Function(String packageName, int attempts)? onAppBlocked;
  Function(bool isRunning)? onServiceStatusChanged;

  // Initialize channel and set up callback handlers
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // Handle incoming method calls from Native
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case AppConstants.callbackOnAppBlocked:
        final String packageName = call.arguments['packageName'] as String;
        final int attempts = call.arguments['attempts'] as int;
        onAppBlocked?.call(packageName, attempts);
        break;

      case AppConstants.callbackOnServiceStatusChanged:
        final bool isRunning = call.arguments['isRunning'] as bool;
        onServiceStatusChanged?.call(isRunning);
        break;

      default:
        AppLogger.w('Unknown method call: ${call.method}');
    }
  }

  // ========== Get Installed Apps ==========

  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        AppConstants.methodGetInstalledApps,
      );
      return result.map((app) => AppInfo.fromMap(app)).toList();
    } on PlatformException catch (e) {
      AppLogger.e('Error getting installed apps', e);
      return [];
    }
  }

  // ========== Permission Methods ==========

  Future<bool> checkUsageStatsPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckUsageStatsPermission,
      );
      return result;
    } on MissingPluginException catch (e) {
      AppLogger.w('Permission handler not ready: ${e.message}');
      // Assume not granted if plugin not ready
      return false;
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.e('Activity not available for permission check', e);
      } else {
        AppLogger.e('Error checking usage stats permission', e);
      }
      return false;
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodRequestUsageStatsPermission,
      );
    } on MissingPluginException {
      AppLogger.w('Permission handler not ready for request');
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.w('Activity not available for permission request');
      } else {
        AppLogger.e('Error requesting usage stats permission', e);
      }
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckOverlayPermission,
      );
      return result;
    } on MissingPluginException catch (e) {
      AppLogger.w('Permission handler not ready: ${e.message}');
      return false;
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.e('Activity not available for permission check', e);
      } else {
        AppLogger.e('Error checking overlay permission', e);
      }
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod(AppConstants.methodRequestOverlayPermission);
    } on MissingPluginException {
      AppLogger.w('Permission handler not ready for request');
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.w('Activity not available for permission request');
      } else {
        AppLogger.e('Error requesting overlay permission', e);
      }
    }
  }

  Future<bool> checkAccessibilityPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckAccessibilityPermission,
      );
      return result;
    } on MissingPluginException catch (e) {
      AppLogger.w('Permission handler not ready: ${e.message}');
      return false;
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.e('Activity not available for permission check', e);
      } else {
        AppLogger.e('Error checking accessibility permission', e);
      }
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodRequestAccessibilityPermission,
      );
    } on MissingPluginException {
      AppLogger.w('Permission handler not ready for request');
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.w('Activity not available for permission request');
      } else {
        AppLogger.e('Error requesting accessibility permission', e);
      }
    }
  }

  Future<bool> checkNotificationListenerPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckNotificationListenerPermission,
      );
      return result;
    } on MissingPluginException catch (e) {
      AppLogger.w('Permission handler not ready: ${e.message}');
      return false;
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.e('Activity not available for permission check', e);
      } else {
        AppLogger.e('Error checking notification listener permission', e);
      }
      return false;
    }
  }

  Future<void> requestNotificationListenerPermission() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodRequestNotificationListenerPermission,
      );
    } on MissingPluginException {
      AppLogger.w('Permission handler not ready for request');
    } on PlatformException catch (e) {
      if (e.message?.contains('Activity') ?? false) {
        AppLogger.w('Activity not available for permission request');
      } else {
        AppLogger.e('Error requesting notification listener permission', e);
      }
    }
  }

  // ========== Monitoring Service Methods ==========

  Future<void> startMonitoringService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStartMonitoringService);
    } on PlatformException catch (e) {
      AppLogger.e('Error starting monitoring service', e);
    }
  }

  Future<void> stopMonitoringService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStopMonitoringService);
    } on PlatformException catch (e) {
      AppLogger.e('Error stopping monitoring service', e);
    }
  }

  Future<void> startUsageTrackingService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStartUsageTrackingService);
    } on PlatformException catch (e) {
      AppLogger.e('Error starting usage tracking service', e);
    }
  }

  Future<void> stopUsageTrackingService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStopUsageTrackingService);
    } on PlatformException catch (e) {
      AppLogger.e('Error stopping usage tracking service', e);
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodIsServiceRunning,
      );
      return result;
    } on PlatformException catch (e) {
      AppLogger.e('Error checking if service is running', e);
      return false;
    }
  }

  // ========== Update Blocked Apps and Schedules ==========

  Future<void> updateBlockedAppsJson(String appsJson) async {
    try {
      print('📱 [CHANNEL] Sending updateBlockedAppsJson to native');
      print(
        '📱 [CHANNEL] JSON preview: ${appsJson.substring(0, (appsJson.length > 300 ? 300 : appsJson.length))}...',
      );
      print('📱 [CHANNEL] JSON size: ${appsJson.length} bytes');

      await _channel.invokeMethod('updateBlockedAppsJson', {
        'appsJson': appsJson,
      });

      print('📱 [CHANNEL] ✅ Method invoked successfully!');
    } on PlatformException catch (e) {
      print('📱 [CHANNEL] ❌ PlatformException: ${e.message}');
      AppLogger.e('Error updating blocked apps JSON', e);
    } catch (e) {
      print('📱 [CHANNEL] ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updateSchedules(List<Schedule> schedules) async {
    try {
      final List<Map<String, dynamic>> scheduleMaps = schedules
          .map((s) => s.toJson())
          .toList();
      await _channel.invokeMethod(AppConstants.methodUpdateSchedules, {
        'schedules': scheduleMaps,
      });
    } on PlatformException catch (e) {
      AppLogger.e('Error updating schedules', e);
    }
  }

  // ========== Usage Limits ==========

  Future<void> updateUsageLimitsJson(String limitsJson) async {
    try {
      await _channel.invokeMethod(AppConstants.methodUpdateUsageLimits, {
        'limitsJson': limitsJson,
      });
    } on PlatformException catch (e) {
      AppLogger.e('Error updating usage limits', e);
    }
  }

  // ========== Usage Statistics ==========

  /// Phase 2 Optimization: Batched daily statistics call
  /// Combines getTodayUsageFromTrackingService, getTodaySessionCountsFromTracking,
  /// and getTodayBlockAttemptsFromTracking into a single native call
  ///
  /// Returns:
  /// ```
  /// {
  ///   'usage': { 'packageName': milliseconds, ... },
  ///   'sessions': { 'packageName': count, ... },
  ///   'blockAttempts': { 'packageName': count, ... }
  /// }
  /// ```
  Future<Map<String, dynamic>> getDailyStats() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getDailyStats',
      );

      return {
        'usage': _convertDynamicMap(result['usage'] ?? {}),
        'sessions': _convertDynamicMap(result['sessions'] ?? {}),
        'blockAttempts': _convertDynamicMap(result['blockAttempts'] ?? {}),
      };
    } on PlatformException catch (e) {
      AppLogger.e('Error getting daily stats', e);
      return {'usage': {}, 'sessions': {}, 'blockAttempts': {}};
    }
  }

  /// Helper to convert dynamic maps to Map<String, int>
  static Map<String, int> _convertDynamicMap(dynamic map) {
    if (map is! Map) return {};
    return map.map((key, value) => MapEntry(key.toString(), value as int));
  }

  Future<Map<String, int>> getAppUsageStats(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final Map<dynamic, dynamic> result = await _channel
          .invokeMethod(AppConstants.methodGetAppUsageStats, {
            'startTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
          });
      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      AppLogger.e('Error getting app usage stats', e);
      return {};
    }
  }

  /// Get app name from package name
  Future<String?> getAppName(String packageName) async {
    try {
      final String result = await _channel.invokeMethod('getAppName', {
        'packageName': packageName,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error getting app name: ${e.message}');
      return null;
    }
  }

  /// Get hourly usage statistics for a time range
  /// Returns a list of 24 hourly data points, each containing:
  /// - hour: Hour of day (0-23)
  /// - totalTimeInMillis: Total usage time in that hour
  /// - appBreakdown: Map of package names to usage time
  Future<List<Map<String, dynamic>>> getHourlyUsageStats(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final List<dynamic> result = await _channel
          .invokeMethod('getHourlyUsageStats', {
            'startTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
          });
      return result.map((item) => Map<String, dynamic>.from(item)).toList();
    } on PlatformException catch (e) {
      print('Error getting hourly usage stats: ${e.message}');
      return [];
    }
  }

  /// Get today's usage from UsageTrackingService (real-time, more accurate)
  /// This uses data that's updated every 10 seconds by the background service
  /// Returns empty map if service data is stale or unavailable
  Future<Map<String, int>> getTodayUsageFromTrackingService() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getTodayUsageFromTrackingService',
      );

      if (result.isEmpty) {
        AppLogger.w('UsageTrackingService data is empty or stale');
        return {};
      }

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      AppLogger.e('Error getting today usage from tracking service', e);
      return {};
    }
  }

  /// Get usage for a specific date from UsageTrackingService storage
  /// Date format: "YYYY-M-D" (e.g., "2025-1-15")
  Future<Map<String, int>> getUsageForDateFromTracking(String date) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getUsageForDateFromTracking',
        {'date': date},
      );

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      AppLogger.e('Error getting usage for date from tracking', e);
      return {};
    }
  }

  /// Get list of dates that have pending snapshots to be saved to database
  Future<List<String>> getPendingSnapshotDates() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getPendingSnapshotDates',
      );

      return result.map((date) => date.toString()).toList();
    } on PlatformException catch (e) {
      AppLogger.e('Error getting pending snapshot dates', e);
      return [];
    }
  }

  /// Clear the list of pending snapshot dates after processing
  Future<void> clearPendingSnapshotDates() async {
    try {
      await _channel.invokeMethod('clearPendingSnapshotDates');
    } on PlatformException catch (e) {
      AppLogger.e('Error clearing pending snapshot dates', e);
    }
  }

  /// Check if device has OEM restrictions that may affect tracking accuracy
  Future<Map<String, dynamic>> checkOEMRestrictions() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'checkOEMRestrictions',
      );

      return {
        'hasRestrictions': result['hasRestrictions'] as bool,
        'manufacturer': result['manufacturer'] as String,
        'model': result['model'] as String,
      };
    } on PlatformException catch (e) {
      AppLogger.e('Error checking OEM restrictions', e);
      return {
        'hasRestrictions': false,
        'manufacturer': 'unknown',
        'model': 'unknown',
      };
    }
  }

  /// Clean stored usage data (remove our own app from all statistics)
  Future<bool> cleanStoredUsageData() async {
    try {
      final bool result = await _channel.invokeMethod('cleanStoredUsageData');
      return result;
    } on PlatformException catch (e) {
      AppLogger.e('Error cleaning stored usage data', e);
      return false;
    }
  }

  // ========== Session Counts (Open Counts) ==========

  /// Get session counts (number of times apps were opened) for a time range
  /// Uses UsageEvents to count MOVE_TO_FOREGROUND events
  Future<Map<String, int>> getSessionCounts(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final Map<dynamic, dynamic> result = await _channel
          .invokeMethod('getSessionCounts', {
            'startTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
          });

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      print('Error getting session counts: ${e.message}');
      return {};
    }
  }

  /// Get today's session counts from UsageTrackingService (real-time, more accurate)
  /// This uses data that's updated in real-time by the background service
  Future<Map<String, int>> getTodaySessionCountsFromTracking() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getTodaySessionCountsFromTracking',
      );

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      AppLogger.e('Error getting today session counts from tracking', e);
      return {};
    }
  }

  /// Get session counts for a specific date from UsageTrackingService storage
  /// Date format: "YYYY-M-D" (e.g., "2026-1-5")
  Future<Map<String, int>> getSessionCountsForDate(String date) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getSessionCountsForDate',
        {'date': date},
      );

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      print('Error getting session counts for date: ${e.message}');
      return {};
    }
  }

  // ========== Block Attempts (Failed Open Attempts) ==========

  /// Get today's block attempts from tracking (real-time)
  /// Returns map of packageName -> number of times user tried to open blocked app
  Future<Map<String, int>> getTodayBlockAttemptsFromTracking() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getTodayBlockAttemptsFromTracking',
      );

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      print('Error getting today block attempts from tracking: ${e.message}');
      return {};
    }
  }

  /// Get block attempts for a specific date from tracking storage
  /// Date format: "YYYY-M-D" (e.g., "2026-1-5")
  Future<Map<String, int>> getBlockAttemptsForDate(String date) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getBlockAttemptsForDate',
        {'date': date},
      );

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      AppLogger.e('Error getting block attempts for date', e);
      return {};
    }
  }

  // ========== Reset Statistics ==========

  /// Clear all usage statistics from Native storage
  /// This helps in resetting the data if it gets corrupted or for debugging
  Future<bool> clearUsageData() async {
    try {
      final bool result = await _channel.invokeMethod('clearUsageData') as bool;
      return result;
    } on PlatformException catch (e) {
      print('Error clearing usage data: ${e.message}');
      return false;
    }
  }

  // ========== Focus Mode Methods ==========

  Future<void> startFocusSession({
    required List<String> packageNames,
    required int durationMinutes,
  }) async {
    try {
      await _channel.invokeMethod(AppConstants.methodStartFocusSession, {
        'packageNames': packageNames,
        'durationMinutes': durationMinutes,
      });
    } on PlatformException catch (e) {
      print('Error starting focus session: ${e.message}');
    }
  }

  Future<void> endFocusSession() async {
    try {
      await _channel.invokeMethod(AppConstants.methodEndFocusSession);
    } on PlatformException catch (e) {
      AppLogger.e('Error ending focus session', e);
    }
  }

  // ========== Block Screen Style ==========

  Future<void> setBlockScreenStyle(String style) async {
    // Implemented حاليًا على أندرويد فقط
    const platform = MethodChannel(AppConstants.channelName);
    try {
      await platform.invokeMethod(AppConstants.methodSetBlockScreenStyle, {
        'style': style,
      });
    } on PlatformException catch (e) {
      AppLogger.e('Error setting block screen style', e);
    } on MissingPluginException {
      // تجاهل على المنصات اللي مفيهاش تنفيذ (iOS/Web)
      AppLogger.w('Block screen style not implemented on this platform');
    }
  }

  // ========== Sync Block Attempts from Native ==========

  /// Sync block attempts from Android SharedPreferences to Flutter
  Future<String?> getBlockedAppsJsonFromNative() async {
    try {
      final String result = await _channel.invokeMethod('getBlockedAppsJson');
      return result;
    } on PlatformException catch (e) {
      print('Error getting blocked apps JSON from native: ${e.message}');
      return null;
    }
  }

  Future<void> syncBlockScreenCustomization(String color, String quote) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodSyncBlockScreenCustomization,
        {'color': color, 'quote': quote},
      );
    } on PlatformException catch (e) {
      print('Error syncing block screen customization: ${e.message}');
    }
  }

  // ========== Icon Cache Management (Phase 3.5) ==========

  /// Preload app icons for list of packages
  /// Call this on app startup to eliminate icon loading delays
  Future<void> preloadAppIcons(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('preloadAppIcons', {
        'packageNames': packageNames,
      });
      AppLogger.i(
        'Platform: Preload request sent for ${packageNames.length} icons',
      );
    } on PlatformException catch (e) {
      AppLogger.e('Error preloading app icons', e);
    }
  }

  /// Invalidate icon cache for specific app
  /// Call when: app install, update, uninstall, reboot
  Future<void> invalidateAppIcon(String packageName) async {
    try {
      await _channel.invokeMethod('invalidateAppIcon', {
        'packageName': packageName,
      });
      AppLogger.d('Platform: Icon invalidated for $packageName');
    } on PlatformException catch (e) {
      AppLogger.e('Error invalidating app icon', e);
    }
  }

  /// Clear entire icon cache
  Future<void> clearIconCache() async {
    try {
      await _channel.invokeMethod('clearIconCache');
      AppLogger.i('Platform: Icon cache cleared');
    } on PlatformException catch (e) {
      AppLogger.e('Error clearing icon cache', e);
    }
  }

  /// Get icon cache statistics
  Future<Map<String, dynamic>> getIconCacheStats() async {
    try {
      final result = await _channel.invokeMethod('getIconCacheStats');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      AppLogger.e('Error getting icon cache stats', e);
      return {};
    }
  }

  // ========== Explicit Cache Control (Phase 4) ==========

  /// Force Accessibility Service to reload its cache from SharedPreferences immediately
  /// Useful after critical setup steps to ensure zero latency
  Future<bool> forceRefreshAccessibilityCache() async {
    try {
      final bool result = await _channel.invokeMethod('forceRefreshCache');
      if (result) {
        AppLogger.i(
          'Platform: Accessibility cache refresh forced successfully',
        );
      } else {
        AppLogger.w(
          'Platform: Accessibility Service NOT running - cannot force refresh',
        );
      }
      return result;
    } on PlatformException catch (e) {
      AppLogger.e('Error forcing cache refresh', e);
      return false;
    }
  }
}
