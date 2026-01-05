import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../feature/data/models/app_info.dart';
import '../../feature/data/models/schedule.dart';

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
        print('Unknown method call: ${call.method}');
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
      print('Error getting installed apps: ${e.message}');
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
    } on PlatformException catch (e) {
      print('Error checking usage stats permission: ${e.message}');
      return false;
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodRequestUsageStatsPermission,
      );
    } on PlatformException catch (e) {
      print('Error requesting usage stats permission: ${e.message}');
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckOverlayPermission,
      );
      return result;
    } on PlatformException catch (e) {
      print('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod(AppConstants.methodRequestOverlayPermission);
    } on PlatformException catch (e) {
      print('Error requesting overlay permission: ${e.message}');
    }
  }

  Future<bool> checkAccessibilityPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        AppConstants.methodCheckAccessibilityPermission,
      );
      return result;
    } on PlatformException catch (e) {
      print('Error checking accessibility permission: ${e.message}');
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodRequestAccessibilityPermission,
      );
    } on PlatformException catch (e) {
      print('Error requesting accessibility permission: ${e.message}');
    }
  }

  // ========== Monitoring Service Methods ==========

  Future<void> startMonitoringService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStartMonitoringService);
    } on PlatformException catch (e) {
      print('Error starting monitoring service: ${e.message}');
    }
  }

  Future<void> stopMonitoringService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStopMonitoringService);
    } on PlatformException catch (e) {
      print('Error stopping monitoring service: ${e.message}');
    }
  }

  Future<void> startUsageTrackingService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStartUsageTrackingService);
    } on PlatformException catch (e) {
      print('Error starting usage tracking service: ${e.message}');
    }
  }

  Future<void> stopUsageTrackingService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStopUsageTrackingService);
    } on PlatformException catch (e) {
      print('Error stopping usage tracking service: ${e.message}');
    }
  }

  // ========== Update Blocked Apps and Schedules ==========

  Future<void> updateBlockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod(AppConstants.methodUpdateBlockedApps, {
        'packageNames': packageNames,
      });
    } on PlatformException catch (e) {
      print('Error updating blocked apps: ${e.message}');
    }
  }

  Future<void> updateBlockedAppsJson(String appsJson) async {
    try {
      await _channel.invokeMethod('updateBlockedAppsJson', {
        'appsJson': appsJson,
      });
    } on PlatformException catch (e) {
      print('Error updating blocked apps JSON: ${e.message}');
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
      print('Error updating schedules: ${e.message}');
    }
  }

  // ========== Usage Limits ==========

  Future<void> updateUsageLimitsJson(String limitsJson) async {
    try {
      await _channel.invokeMethod(AppConstants.methodUpdateUsageLimits, {
        'limitsJson': limitsJson,
      });
    } on PlatformException catch (e) {
      print('Error updating usage limits: ${e.message}');
    }
  }

  // ========== Usage Statistics ==========

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
      print('Error getting app usage stats: ${e.message}');
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
        print('UsageTrackingService data is empty or stale');
        return {};
      }

      // Convert dynamic map to Map<String, int>
      return result.map((key, value) => MapEntry(key.toString(), value as int));
    } on PlatformException catch (e) {
      print('Error getting today usage from tracking service: ${e.message}');
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
      print('Error getting usage for date from tracking: ${e.message}');
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
      print('Error getting pending snapshot dates: ${e.message}');
      return [];
    }
  }

  /// Clear the list of pending snapshot dates after processing
  Future<void> clearPendingSnapshotDates() async {
    try {
      await _channel.invokeMethod('clearPendingSnapshotDates');
    } on PlatformException catch (e) {
      print('Error clearing pending snapshot dates: ${e.message}');
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
      print('Error checking OEM restrictions: ${e.message}');
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
      print('Error cleaning stored usage data: ${e.message}');
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
      print('Error getting today session counts from tracking: ${e.message}');
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
      print('Error getting block attempts for date: ${e.message}');
      return {};
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
      print('Error ending focus session: ${e.message}');
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
      print('Error setting block screen style: ${e.message}');
    } on MissingPluginException catch (e) {
      // تجاهل على المنصات اللي مفيهاش تنفيذ (iOS/Web)
      print(
        'Block screen style not implemented on this platform: ${e.message}',
      );
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
}
