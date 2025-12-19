import '../models/app_usage_stats.dart';
import '../models/comparison_stats.dart';
import '../models/statistics_dashboard_data.dart';
import '../models/hourly_usage_data.dart';
import '../models/app_usage_limit.dart';
import 'package:flutter/foundation.dart';

/// Helper class for running statistics computations in isolates
/// This prevents UI freezing during heavy data processing
class StatisticsIsolateHelper {
  /// Generate pie chart data from top apps (run in isolate)
  static Future<List<PieChartData>> generatePieChartData({
    required List<AppUsageStats> topApps,
  }) async {
    return await compute(_generatePieChartDataInIsolate, topApps);
  }

  static List<PieChartData> _generatePieChartDataInIsolate(List<AppUsageStats> topApps) {
    if (topApps.isEmpty) return [];

    // Take top 5 apps only for pie chart
    final limitedApps = topApps.take(5).toList();
    final total = limitedApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInMillis,
    );

    if (total == 0) return [];

    return limitedApps.asMap().entries.map((entry) {
      final index = entry.key;
      final app = entry.value;
      final percentage = (app.totalTimeInMillis / total) * 100;

      return PieChartData(
        packageName: app.packageName,
        appName: app.appName,
        timeInMillis: app.totalTimeInMillis,
        percentage: percentage,
        color: PieChartColors.getColor(index),
      );
    }).toList();
  }

  /// Process app names in batch (run in isolate)
  static Future<Map<String, String>> processAppNamesBatch(
    Map<String, String> packageNamesToProcess,
  ) async {
    return await compute(_processAppNamesInIsolate, packageNamesToProcess);
  }

  static Map<String, String> _processAppNamesInIsolate(
    Map<String, String> packageNamesToProcess,
  ) {
    // This would be called from main thread with already-fetched names
    // Just return as-is since the heavy work is done by platform channel
    return packageNamesToProcess;
  }

  /// Calculate statistics aggregations in isolate
  static Future<Map<String, dynamic>> calculateAggregations({
    required List<AppUsageStats> stats,
  }) async {
    return await compute(_calculateAggregationsInIsolate, stats);
  }

  static Map<String, dynamic> _calculateAggregationsInIsolate(
    List<AppUsageStats> stats,
  ) {
    int totalTime = 0;
    int totalApps = stats.length;
    final Map<String, int> packageTotals = {};

    for (final stat in stats) {
      totalTime += stat.totalTimeInMillis;
      packageTotals[stat.packageName] =
          (packageTotals[stat.packageName] ?? 0) + stat.totalTimeInMillis;
    }

    // Sort by usage
    final sortedPackages = packageTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalTime': totalTime,
      'totalApps': totalApps,
      'topPackages': sortedPackages.take(10).map((e) => {
        'packageName': e.key,
        'totalTime': e.value,
      }).toList(),
    };
  }

  /// Process comparison calculations in isolate
  static Future<Map<String, dynamic>> calculateComparison({
    required List<AppUsageStats> currentStats,
    required List<AppUsageStats> previousStats,
  }) async {
    return await compute(_calculateComparisonInIsolate, {
      'current': currentStats,
      'previous': previousStats,
    });
  }

  static Map<String, dynamic> _calculateComparisonInIsolate(
    Map<String, dynamic> data,
  ) {
    final currentStats = data['current'] as List<AppUsageStats>;
    final previousStats = data['previous'] as List<AppUsageStats>;

    int currentTotal = 0;
    int previousTotal = 0;

    for (final stat in currentStats) {
      currentTotal += stat.totalTimeInMillis;
    }

    for (final stat in previousStats) {
      previousTotal += stat.totalTimeInMillis;
    }

    final difference = currentTotal - previousTotal;
    final percentageChange = previousTotal > 0
        ? (difference / previousTotal * 100)
        : 0.0;

    return {
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'difference': difference,
      'percentageChange': percentageChange,
      'isIncrease': difference > 0,
    };
  }

  /// Sort and filter top apps in isolate
  static Future<List<AppUsageStats>> sortTopApps({
    required List<AppUsageStats> apps,
    required int limit,
  }) async {
    return await compute(_sortTopAppsInIsolate, {
      'apps': apps,
      'limit': limit,
    });
  }

  static List<AppUsageStats> _sortTopAppsInIsolate(Map<String, dynamic> data) {
    final apps = data['apps'] as List<AppUsageStats>;
    final limit = data['limit'] as int;

    // Sort by total time descending
    final sorted = List<AppUsageStats>.from(apps)
      ..sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));

    return sorted.take(limit).toList();
  }

  /// Process hourly data aggregations in isolate
  static Future<List<HourlyUsageData>> processHourlyData({
    required Map<int, Map<String, int>> hourlyMap,
  }) async {
    return await compute(_processHourlyDataInIsolate, hourlyMap);
  }

  static List<HourlyUsageData> _processHourlyDataInIsolate(
    Map<int, Map<String, int>> hourlyMap,
  ) {
    final result = <HourlyUsageData>[];

    for (int hour = 0; hour < 24; hour++) {
      final hourData = hourlyMap[hour] ?? {};
      int totalTime = 0;

      for (final time in hourData.values) {
        totalTime += time;
      }

      result.add(HourlyUsageData(
        hour: hour,
        totalTimeInMillis: totalTime,
        appBreakdown: hourData,
      ));
    }

    return result;
  }
}
