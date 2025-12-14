import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../data/models/app_info.dart';
import '../data/models/schedule.dart';

class PlatformChannelService {
  static final PlatformChannelService _instance =
      PlatformChannelService._internal();
  factory PlatformChannelService() => _instance;
  PlatformChannelService._internal();

  final MethodChannel _channel =
      const MethodChannel(AppConstants.channelName);

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
      await _channel.invokeMethod(
        AppConstants.methodRequestOverlayPermission,
      );
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
      await _channel.invokeMethod(
        AppConstants.methodStartMonitoringService,
      );
    } on PlatformException catch (e) {
      print('Error starting monitoring service: ${e.message}');
    }
  }

  Future<void> stopMonitoringService() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodStopMonitoringService,
      );
    } on PlatformException catch (e) {
      print('Error stopping monitoring service: ${e.message}');
    }
  }

  // ========== Update Blocked Apps and Schedules ==========

  Future<void> updateBlockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodUpdateBlockedApps,
        {'packageNames': packageNames},
      );
    } on PlatformException catch (e) {
      print('Error updating blocked apps: ${e.message}');
    }
  }

  Future<void> updateBlockedAppsJson(String appsJson) async {
    try {
      await _channel.invokeMethod(
        'updateBlockedAppsJson',
        {'appsJson': appsJson},
      );
    } on PlatformException catch (e) {
      print('Error updating blocked apps JSON: ${e.message}');
    }
  }

  Future<void> updateSchedules(List<Schedule> schedules) async {
    try {
      final List<Map<String, dynamic>> scheduleMaps =
          schedules.map((s) => s.toJson()).toList();
      await _channel.invokeMethod(
        AppConstants.methodUpdateSchedules,
        {'schedules': scheduleMaps},
      );
    } on PlatformException catch (e) {
      print('Error updating schedules: ${e.message}');
    }
  }

  // ========== Usage Limits ==========

  Future<void> updateUsageLimitsJson(String limitsJson) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodUpdateUsageLimits,
        {'limitsJson': limitsJson},
      );
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
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        AppConstants.methodGetAppUsageStats,
        {
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );
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
      final String result = await _channel.invokeMethod(
        'getAppName',
        {'packageName': packageName},
      );
      return result;
    } on PlatformException catch (e) {
      print('Error getting app name: ${e.message}');
      return null;
    }
  }

  // ========== Focus Mode Methods ==========

  Future<void> startFocusSession({
    required List<String> packageNames,
    required int durationMinutes,
  }) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodStartFocusSession,
        {
          'packageNames': packageNames,
          'durationMinutes': durationMinutes,
        },
      );
    } on PlatformException catch (e) {
      print('Error starting focus session: ${e.message}');
    }
  }

  Future<void> endFocusSession() async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodEndFocusSession,
      );
    } on PlatformException catch (e) {
      print('Error ending focus session: ${e.message}');
    }
  }
}
