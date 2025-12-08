import 'package:flutter/material.dart';
import '../data/models/app_usage_stats.dart';
import '../data/repositories/app_repository.dart';

class StatisticsProvider extends ChangeNotifier {
  final AppRepository _appRepository;
  List<AppUsageStats> _dailyStats = [];
  List<AppUsageStats> _weeklyStats = [];
  bool _isLoading = false;

  StatisticsProvider(this._appRepository);

  List<AppUsageStats> get dailyStats => _dailyStats;
  List<AppUsageStats> get weeklyStats => _weeklyStats;
  bool get isLoading => _isLoading;

  Future<void> loadDailyStats() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final statsMap =
        await _appRepository.getAppUsageStats(startOfDay, endOfDay);

    _dailyStats = statsMap.entries
        .map((entry) => AppUsageStats.fromMap(
              entry.key,
              entry.key, // We'll need to get app name separately
              entry.value,
              now,
            ))
        .toList();

    // Sort by usage time (descending)
    _dailyStats.sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWeeklyStats() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final statsMap =
        await _appRepository.getAppUsageStats(startOfWeekDay, endOfWeek);

    _weeklyStats = statsMap.entries
        .map((entry) => AppUsageStats.fromMap(
              entry.key,
              entry.key, // We'll need to get app name separately
              entry.value,
              now,
            ))
        .toList();

    // Sort by usage time (descending)
    _weeklyStats.sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));

    _isLoading = false;
    notifyListeners();
  }

  int get totalDailyScreenTime {
    return _dailyStats.fold(0, (sum, stat) => sum + stat.totalTimeInMillis);
  }

  int get totalWeeklyScreenTime {
    return _weeklyStats.fold(0, (sum, stat) => sum + stat.totalTimeInMillis);
  }

  String get totalDailyScreenTimeFormatted {
    final hours = (totalDailyScreenTime / 3600000).floor();
    final minutes = ((totalDailyScreenTime % 3600000) / 60000).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get totalWeeklyScreenTimeFormatted {
    final hours = (totalWeeklyScreenTime / 3600000).floor();
    final minutes = ((totalWeeklyScreenTime % 3600000) / 60000).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void refresh() {
    loadDailyStats();
    loadWeeklyStats();
  }
}
