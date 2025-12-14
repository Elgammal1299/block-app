import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'app_usage_stats.dart';
import 'app_usage_limit.dart';
import 'comparison_stats.dart';

/// Model representing data for a single pie chart section
class PieChartData extends Equatable {
  final String packageName;
  final String appName;
  final int timeInMillis;
  final double percentage;
  final Color color;

  const PieChartData({
    required this.packageName,
    required this.appName,
    required this.timeInMillis,
    required this.percentage,
    required this.color,
  });

  /// Get formatted time string
  String get formattedTime {
    if (timeInMillis == 0) return '0m';

    final hours = timeInMillis ~/ 3600000;
    final minutes = (timeInMillis % 3600000) ~/ 60000;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  @override
  List<Object?> get props => [
        packageName,
        appName,
        timeInMillis,
        percentage,
        color,
      ];
}

/// Comprehensive model containing all statistics dashboard data
class StatisticsDashboardData extends Equatable {
  final ComparisonStats comparisonStats;
  final List<AppUsageStats> todayTopApps;
  final int totalBlockAttempts;
  final Map<String, AppUsageLimit> usageLimitsMap;
  final List<PieChartData> pieChartData;

  const StatisticsDashboardData({
    required this.comparisonStats,
    required this.todayTopApps,
    required this.totalBlockAttempts,
    required this.usageLimitsMap,
    required this.pieChartData,
  });

  /// Get usage limit for a specific app
  AppUsageLimit? getLimitForApp(String packageName) {
    return usageLimitsMap[packageName];
  }

  /// Check if an app has a usage limit
  bool hasUsageLimit(String packageName) {
    return usageLimitsMap.containsKey(packageName);
  }

  /// Get total number of apps with usage limits
  int get totalAppsWithLimits => usageLimitsMap.length;

  /// Get number of apps that reached their limit
  int get appsReachedLimit {
    return usageLimitsMap.values.where((limit) => limit.isLimitReached).length;
  }

  @override
  List<Object?> get props => [
        comparisonStats,
        todayTopApps,
        totalBlockAttempts,
        usageLimitsMap,
        pieChartData,
      ];
}

/// Predefined color palette for pie charts
class PieChartColors {
  static const List<Color> palette = [
    Color(0xFF0293EE), // Blue
    Color(0xFFF8B250), // Orange
    Color(0xFF845EC2), // Purple
    Color(0xFFD65DB1), // Pink
    Color(0xFFFF6F91), // Light Pink
    Color(0xFFFF9671), // Coral
    Color(0xFFFFC75F), // Yellow
    Color(0xFFF9F871), // Light Yellow
    Color(0xFF00C9A7), // Teal
    Color(0xFFC34A36), // Red-Brown
  ];

  /// Get color for index (wraps around if needed)
  static Color getColor(int index) {
    return palette[index % palette.length];
  }
}
