import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/blocked_app.dart';
import '../models/app_usage_limit.dart';

/// Helper class for running heavy operations in isolates
/// Prevents UI freezing during JSON encoding/decoding and data processing
class AppRepositoryIsolateHelper {
  /// Encode blocked apps to JSON in isolate
  static Future<String> encodeBlockedAppsJson(
    List<BlockedApp> blockedApps,
  ) async {
    return await compute(_encodeBlockedAppsInIsolate, blockedApps);
  }

  static String _encodeBlockedAppsInIsolate(List<BlockedApp> blockedApps) {
    return jsonEncode(
      blockedApps.map((app) => app.toJson()).toList(),
    );
  }

  /// Decode blocked apps from JSON in isolate
  static Future<List<BlockedApp>> decodeBlockedAppsJson(
    String jsonString,
  ) async {
    return await compute(_decodeBlockedAppsInIsolate, jsonString);
  }

  static List<BlockedApp> _decodeBlockedAppsInIsolate(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => BlockedApp.fromJson(json)).toList();
  }

  /// Encode usage limits to JSON in isolate
  static Future<String> encodeUsageLimitsJson(
    List<AppUsageLimit> limits,
  ) async {
    return await compute(_encodeUsageLimitsInIsolate, limits);
  }

  static String _encodeUsageLimitsInIsolate(List<AppUsageLimit> limits) {
    return jsonEncode(
      limits.map((limit) => limit.toJson()).toList(),
    );
  }

  /// Sync block attempts from native (heavy JSON parsing)
  static Future<List<BlockedApp>> syncBlockAttemptsFromNativeJson(
    String nativeJson,
    List<BlockedApp> currentApps,
  ) async {
    return await compute(
      _syncBlockAttemptsInIsolate,
      {
        'nativeJson': nativeJson,
        'currentApps': currentApps.map((a) => a.toJson()).toList(),
      },
    );
  }

  static List<BlockedApp> _syncBlockAttemptsInIsolate(
    Map<String, dynamic> params,
  ) {
    final nativeJson = params['nativeJson'] as String;
    final currentAppsJson =
        params['currentApps'] as List<Map<String, dynamic>>;

    // Parse native JSON
    final List<dynamic> jsonList = jsonDecode(nativeJson);
    final nativeApps = jsonList.map((json) => BlockedApp.fromJson(json));

    // Convert current apps from JSON
    final currentApps =
        currentAppsJson.map((json) => BlockedApp.fromJson(json)).toList();

    // Merge: update block attempts from native
    for (final nativeApp in nativeApps) {
      final index = currentApps.indexWhere(
        (app) => app.packageName == nativeApp.packageName,
      );
      if (index != -1 &&
          currentApps[index].blockAttempts != nativeApp.blockAttempts) {
        currentApps[index] = currentApps[index].copyWith(
          blockAttempts: nativeApp.blockAttempts,
        );
      }
    }

    return currentApps;
  }
}
