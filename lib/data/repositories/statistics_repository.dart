import 'dart:typed_data';
import '../local/database_service.dart';
import '../models/app_usage_stats.dart';
import '../models/comparison_stats.dart';
import '../models/statistics_dashboard_data.dart';
import '../../services/platform_channel_service.dart';
import 'app_repository.dart';

/// Repository for managing statistics data and comparisons
class StatisticsRepository {
  final DatabaseService _databaseService;
  final AppRepository _appRepository;
  final PlatformChannelService _platformService;

  // Cache for app icons
  Map<String, Uint8List?> _appIconsCache = {};
  bool _iconsCacheInitialized = false;

  StatisticsRepository(
    this._databaseService,
    this._appRepository,
    this._platformService,
  );

  /// Save today's usage snapshot to database
  Future<void> saveTodaySnapshot() async {
    try {
      final now = DateTime.now();
      final dateKey = _formatDate(now);

      // Get today's usage from platform service
      final startOfDay = DateTime(now.year, now.month, now.day);
      final statsMap = await _platformService.getAppUsageStats(startOfDay, now);

      // Convert to AppUsageStats list with real app names
      final statsList = <AppUsageStats>[];
      for (final entry in statsMap.entries) {
        String appName = entry.key;
        try {
          // Try to get real app name from platform
          appName = await _platformService.getAppName(entry.key) ?? entry.key;
        } catch (e) {
          // If fails, use package name
          appName = entry.key;
        }

        statsList.add(AppUsageStats(
          packageName: entry.key,
          appName: appName,
          totalTimeInMillis: entry.value,
          date: now,
        ));
      }

      // Save to database
      if (statsList.isNotEmpty) {
        await _databaseService.saveDailyUsageSnapshot(statsList, dateKey);
      }

      // Save block attempts
      final totalAttempts = await _appRepository.getTotalBlockAttempts();
      await _databaseService.saveDailyBlockAttempts(totalAttempts, dateKey);

      // Clean up old data
      await _databaseService.cleanupOldData();
    } catch (e) {
      // Log error but don't throw - snapshot saving shouldn't crash the app
      print('Error saving today snapshot: $e');
    }
  }

  /// Get comprehensive dashboard data for a specific comparison mode
  Future<StatisticsDashboardData> getDashboardData(ComparisonMode mode) async {
    // Get comparison stats based on mode
    final comparisonStats = await _getComparisonStats(mode);

    // Get today's top apps
    final todayTopApps = await getTodayTopApps(limit: 10);

    // Get total block attempts
    final totalBlockAttempts = await _appRepository.getTotalBlockAttempts();

    // Get usage limits
    final usageLimits = await _appRepository.getUsageLimits();
    final usageLimitsMap = {
      for (var limit in usageLimits) limit.packageName: limit
    };

    // Generate pie chart data
    final pieChartData = _generatePieChartData(todayTopApps);

    return StatisticsDashboardData(
      comparisonStats: comparisonStats,
      todayTopApps: todayTopApps,
      totalBlockAttempts: totalBlockAttempts,
      usageLimitsMap: usageLimitsMap,
      pieChartData: pieChartData,
    );
  }

  /// Get comparison stats based on mode
  Future<ComparisonStats> _getComparisonStats(ComparisonMode mode) async {
    switch (mode) {
      case ComparisonMode.todayVsYesterday:
        return await getTodayVsYesterday();
      case ComparisonMode.thisWeekVsLastWeek:
        return await getThisWeekVsLastWeek();
      case ComparisonMode.peakDay:
        return await getPeakDayComparison();
    }
  }

  /// Compare today with yesterday
  Future<ComparisonStats> getTodayVsYesterday() async {
    final now = DateTime.now();
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));

    // Get today's data (live from platform)
    final todayStats = await _getTodayUsage();
    final todayAttempts = await _appRepository.getTotalBlockAttempts();

    // Get yesterday's data (from database)
    final yesterdayStats = await _databaseService.getDailyUsage(yesterday);
    final yesterdayAttempts = await _databaseService.getDailyBlockAttempts(yesterday);

    // Create period stats
    final todayStartTime = DateTime(now.year, now.month, now.day);
    final currentPeriod = PeriodStats(
      label: 'Today',
      startDate: todayStartTime,
      endDate: now,
      totalScreenTimeMillis: _calculateTotal(todayStats),
      topApps: _getTopApps(todayStats, 5),
      totalBlockAttempts: todayAttempts,
    );

    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterdayStartTime = DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day);
    final yesterdayEndTime = DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day, 23, 59, 59);

    final previousPeriod = PeriodStats(
      label: 'Yesterday',
      startDate: yesterdayStartTime,
      endDate: yesterdayEndTime,
      totalScreenTimeMillis: _calculateTotal(yesterdayStats),
      topApps: _getTopApps(yesterdayStats, 5),
      totalBlockAttempts: yesterdayAttempts,
    );

    return ComparisonStats(
      mode: ComparisonMode.todayVsYesterday,
      currentPeriod: currentPeriod,
      previousPeriod: previousPeriod,
    );
  }

  /// Compare this week with last week
  Future<ComparisonStats> getThisWeekVsLastWeek() async {
    final now = DateTime.now();

    // Calculate week boundaries (Monday to Sunday)
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = now;
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

    // Get this week's data
    final thisWeekStats = await _getWeekUsage(thisWeekStart, thisWeekEnd);
    final thisWeekAttempts = await _getWeekBlockAttempts(thisWeekStart, thisWeekEnd);

    // Get last week's data
    final lastWeekStats = await _getWeekUsage(lastWeekStart, lastWeekEnd);
    final lastWeekAttempts = await _getWeekBlockAttempts(lastWeekStart, lastWeekEnd);

    final currentPeriod = PeriodStats(
      label: 'This Week',
      startDate: DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day),
      endDate: thisWeekEnd,
      totalScreenTimeMillis: _calculateTotal(thisWeekStats),
      topApps: _getTopApps(thisWeekStats, 5),
      totalBlockAttempts: thisWeekAttempts,
    );

    final previousPeriod = PeriodStats(
      label: 'Last Week',
      startDate: DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day),
      endDate: DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59),
      totalScreenTimeMillis: _calculateTotal(lastWeekStats),
      topApps: _getTopApps(lastWeekStats, 5),
      totalBlockAttempts: lastWeekAttempts,
    );

    return ComparisonStats(
      mode: ComparisonMode.thisWeekVsLastWeek,
      currentPeriod: currentPeriod,
      previousPeriod: previousPeriod,
    );
  }

  /// Compare today with peak day (highest usage in last 7 days)
  Future<ComparisonStats> getPeakDayComparison() async {
    final now = DateTime.now();
    final last7DaysStart = now.subtract(const Duration(days: 6));

    // Find peak day in last 7 days
    final peakDate = await _databaseService.getPeakDayInRange(
      _formatDate(last7DaysStart),
      _formatDate(now),
    );

    // Get today's data
    final todayStats = await _getTodayUsage();
    final todayAttempts = await _appRepository.getTotalBlockAttempts();

    final todayStartTime = DateTime(now.year, now.month, now.day);
    final currentPeriod = PeriodStats(
      label: 'Today',
      startDate: todayStartTime,
      endDate: now,
      totalScreenTimeMillis: _calculateTotal(todayStats),
      topApps: _getTopApps(todayStats, 5),
      totalBlockAttempts: todayAttempts,
    );

    // Get peak day data
    PeriodStats? peakPeriod;
    if (peakDate != null) {
      final peakDayStats = await _databaseService.getDailyUsage(peakDate);
      final peakDayAttempts = await _databaseService.getDailyBlockAttempts(peakDate);
      final peakDateTime = DateTime.parse(peakDate);

      peakPeriod = PeriodStats(
        label: 'Peak Day (${_formatDisplayDate(peakDateTime)})',
        startDate: DateTime(peakDateTime.year, peakDateTime.month, peakDateTime.day),
        endDate: DateTime(peakDateTime.year, peakDateTime.month, peakDateTime.day, 23, 59, 59),
        totalScreenTimeMillis: _calculateTotal(peakDayStats),
        topApps: _getTopApps(peakDayStats, 5),
        totalBlockAttempts: peakDayAttempts,
      );
    }

    return ComparisonStats(
      mode: ComparisonMode.peakDay,
      currentPeriod: currentPeriod,
      peakPeriod: peakPeriod,
    );
  }

  /// Get today's top apps
  Future<List<AppUsageStats>> getTodayTopApps({int limit = 10}) async {
    final todayStats = await _getTodayUsage();
    return _getTopApps(todayStats, limit);
  }

  /// Initialize app icons cache
  Future<void> _initializeIconsCache() async {
    if (_iconsCacheInitialized) return;

    try {
      final installedApps = await _platformService.getInstalledApps();
      for (final app in installedApps) {
        _appIconsCache[app.packageName] = app.icon;
      }
      _iconsCacheInitialized = true;
    } catch (e) {
      print('Error initializing icons cache: $e');
    }
  }

  /// Get today's usage from platform service
  Future<List<AppUsageStats>> _getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final statsMap = await _platformService.getAppUsageStats(startOfDay, now);

    // Initialize icons cache if needed
    await _initializeIconsCache();

    // Get app names and icons for each package
    final statsList = <AppUsageStats>[];
    for (final entry in statsMap.entries) {
      String appName = entry.key;
      try {
        // Try to get real app name from platform
        appName = await _platformService.getAppName(entry.key) ?? entry.key;
      } catch (e) {
        // If fails, use package name
        appName = entry.key;
      }

      statsList.add(AppUsageStats(
        packageName: entry.key,
        appName: appName,
        totalTimeInMillis: entry.value,
        date: now,
        icon: _appIconsCache[entry.key],
      ));
    }

    return statsList;
  }

  /// Get aggregated usage for a week
  Future<List<AppUsageStats>> _getWeekUsage(DateTime start, DateTime end) async {
    final dates = _generateDateRange(start, end);
    final allStats = <String, int>{}; // packageName -> totalTime
    final appNames = <String, String>{}; // packageName -> appName

    for (final date in dates) {
      final dateKey = _formatDate(date);
      List<AppUsageStats> dayStats;

      // Use live data for today, database for past days
      if (_isToday(date)) {
        dayStats = await _getTodayUsage();
      } else {
        dayStats = await _databaseService.getDailyUsage(dateKey);
      }

      for (final stat in dayStats) {
        allStats[stat.packageName] = (allStats[stat.packageName] ?? 0) + stat.totalTimeInMillis;
        appNames[stat.packageName] = stat.appName;
      }
    }

    return allStats.entries.map((e) => AppUsageStats(
      packageName: e.key,
      appName: appNames[e.key]!,
      totalTimeInMillis: e.value,
      date: end,
    )).toList()..sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));
  }

  /// Get total block attempts for a week
  Future<int> _getWeekBlockAttempts(DateTime start, DateTime end) async {
    final dates = _generateDateRange(start, end);
    int total = 0;

    for (final date in dates) {
      final dateKey = _formatDate(date);

      if (_isToday(date)) {
        total += await _appRepository.getTotalBlockAttempts();
      } else {
        total += await _databaseService.getDailyBlockAttempts(dateKey);
      }
    }

    return total;
  }

  /// Generate list of dates between start and end (inclusive)
  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Calculate total usage time in milliseconds
  int _calculateTotal(List<AppUsageStats> stats) {
    return stats.fold(0, (sum, stat) => sum + stat.totalTimeInMillis);
  }

  /// Get top N apps sorted by usage
  List<AppUsageStats> _getTopApps(List<AppUsageStats> stats, int limit) {
    final sorted = List<AppUsageStats>.from(stats)
      ..sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));
    return sorted.take(limit).toList();
  }

  /// Generate pie chart data from app usage stats
  List<PieChartData> _generatePieChartData(List<AppUsageStats> stats) {
    if (stats.isEmpty) return [];

    final total = _calculateTotal(stats);
    if (total == 0) return [];

    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final percentage = (stat.totalTimeInMillis / total) * 100;

      return PieChartData(
        packageName: stat.packageName,
        appName: stat.appName,
        timeInMillis: stat.totalTimeInMillis,
        percentage: percentage,
        color: PieChartColors.getColor(index),
      );
    }).toList();
  }

  /// Format DateTime to YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date for display (e.g., "Jan 15")
  String _formatDisplayDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}
