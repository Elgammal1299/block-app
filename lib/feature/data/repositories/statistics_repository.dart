import 'dart:typed_data';
import '../local/database_service.dart';
import '../models/app_usage_stats.dart';
import '../models/comparison_stats.dart';
import '../models/statistics_dashboard_data.dart';
import '../models/hourly_usage_data.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/request_cache.dart';
import 'app_repository.dart';
import 'statistics_isolate_helper.dart';

/// Repository for managing statistics data and comparisons
class StatisticsRepository {
  final DatabaseService _databaseService;
  final AppRepository _appRepository;
  final PlatformChannelService _platformService;

  // Cache for app icons
  Map<String, Uint8List?> _appIconsCache = {};
  bool _iconsCacheInitialized = false;

  // Phase 2: Request-level caching for platform channel calls
  late final RequestCache<Map<String, dynamic>> _dailyStatsCache =
      RequestCache<Map<String, dynamic>>(
    ttl: const Duration(seconds: 1),
    maxEntries: 10,
  );

  StatisticsRepository(
    this._databaseService,
    this._appRepository,
    this._platformService,
  );

  /// Process pending snapshots from Native
  /// This is now the ONLY responsibility of this method
  /// Daily reset is handled by MidnightResetReceiver on Android side
  Future<void> saveTodaySnapshot() async {
    try {
      // Process any pending snapshots from Native (marked by MidnightResetReceiver)
      await processPendingSnapshots();

      // Clean up old data
      await _databaseService.cleanupOldData();
    } catch (e) {
      // Log error but don't throw - snapshot saving shouldn't crash the app
      AppLogger.e('Error processing pending snapshots', e);
    }
  }

  /// Process pending snapshots marked by UsageTrackingService
  Future<void> processPendingSnapshots() async {
    try {
      // Get pending snapshots list from SharedPreferences via platform
      final pendingDates = await _platformService.getPendingSnapshotDates();

      if (pendingDates.isEmpty) {
        return;
      }

      AppLogger.i('Processing ${pendingDates.length} pending snapshots from Native');

      for (final dateStr in pendingDates) {
        try {
          // Get usage data for this date from UsageTrackingService storage
          final usageMap = await _platformService.getUsageForDateFromTracking(
            dateStr,
          );

          // ✨ NEW: Get session counts for this date
          final sessionCounts = await _platformService.getSessionCountsForDate(
            dateStr,
          );

          // ✨ NEW: Get block attempts for this date
          final blockAttempts = await _platformService.getBlockAttemptsForDate(
            dateStr,
          );

          if (usageMap.isEmpty) {
            AppLogger.w('No data found for pending snapshot: $dateStr');
            continue;
          }

          // Convert to AppUsageStats list
          final statsList = <AppUsageStats>[];
          final date = DateTime.parse(dateStr);

          for (final entry in usageMap.entries) {
            String appName = entry.key;
            try {
              appName =
                  await _platformService.getAppName(entry.key) ?? entry.key;
            } catch (e) {
              appName = entry.key;
            }

            statsList.add(
              AppUsageStats(
                packageName: entry.key,
                appName: appName,
                totalTimeInMillis: entry.value,
                date: date,
                openCount: sessionCounts[entry.key] ?? 0, // ✨ NEW
                blockAttempts: blockAttempts[entry.key] ?? 0, // ✨ NEW
              ),
            );
          }

          // Save to database
          if (statsList.isNotEmpty) {
            await _databaseService.saveDailyUsageSnapshot(statsList, dateStr);
            AppLogger.i(
              'Saved pending snapshot for $dateStr (${statsList.length} apps)',
            );
          }
        } catch (e) {
          AppLogger.e('Error processing pending snapshot for $dateStr', e);
        }
      }

      // Clear pending snapshots after processing
      await _platformService.clearPendingSnapshotDates();
    } catch (e) {
      AppLogger.e('Error processing pending snapshots', e);
    }
  }

  /// Get comprehensive dashboard data for a specific comparison mode
  /// Optional [startDate] and [endDate] to filter data for specific period
  Future<StatisticsDashboardData> getDashboardData(
    ComparisonMode mode, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Sync block attempts from native Android first
    await _appRepository.syncBlockAttemptsFromNative();

    // Get comparison stats based on mode OR custom period
    ComparisonStats comparisonStats;
    if (startDate != null && endDate != null) {
      // Custom period - create comparison stats for this specific period
      comparisonStats = await _getCustomPeriodComparison(startDate, endDate);
    } else {
      // Use predefined comparison mode
      comparisonStats = await _getComparisonStats(mode);
    }

    // Get top apps for the period (default to today if no dates provided)
    final topApps = await getTopAppsForPeriod(
      startDate: startDate,
      endDate: endDate,
      limit: 10,
    );

    // Get total block attempts
    final totalBlockAttempts = await _appRepository.getTotalBlockAttempts();

    // Get usage limits
    final usageLimits = await _appRepository.getUsageLimits();
    final usageLimitsMap = {
      for (var limit in usageLimits) limit.packageName: limit,
    };

    // Run heavy computations in parallel using isolates
    final results = await Future.wait([
      // Generate pie chart data in isolate
      StatisticsIsolateHelper.generatePieChartData(topApps: topApps),
      // Get hourly usage data (already optimized with platform channel)
      getHourlyUsageForPeriod(startDate: startDate, endDate: endDate),
    ]);

    final pieChartData = results[0] as List<PieChartData>;
    final hourlyUsageData = results[1] as List<HourlyUsageData>;

    // Calculate total apps used
    final totalAppsUsed = topApps.length;

    return StatisticsDashboardData(
      comparisonStats: comparisonStats,
      todayTopApps: topApps,
      totalBlockAttempts: totalBlockAttempts,
      usageLimitsMap: usageLimitsMap,
      pieChartData: pieChartData,
      hourlyUsageData: hourlyUsageData,
      totalAppsUsedToday: totalAppsUsed,
    );
  }

  /// Create comparison stats for a custom period
  Future<ComparisonStats> _getCustomPeriodComparison(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get stats for the selected period
    final periodStats = await _getUsageForPeriod(startDate, endDate);
    final totalUsage = _calculateTotal(periodStats);

    // Calculate period duration in days
    final duration = endDate.difference(startDate).inDays + 1;

    // Create label based on duration
    String label;
    if (duration == 1) {
      // Single day
      if (_isToday(startDate)) {
        label = 'Today';
      } else if (_isYesterday(startDate)) {
        label = 'Yesterday';
      } else {
        label = _formatDisplayDate(startDate);
      }
    } else if (duration <= 7) {
      label = 'Last $duration days';
    } else if (duration <= 30) {
      label = 'Last $duration days';
    } else {
      label = 'Custom Period';
    }

    final currentPeriod = PeriodStats(
      label: label,
      startDate: startDate,
      endDate: endDate,
      totalScreenTimeMillis: totalUsage,
      topApps: _getTopApps(periodStats, 5),
      totalBlockAttempts: await _appRepository.getTotalBlockAttempts(),
    );

    // For comparison, use the previous period of same duration
    final previousEndDate = startDate.subtract(const Duration(seconds: 1));
    final previousStartDate = previousEndDate.subtract(
      Duration(days: duration - 1),
    );

    final previousPeriodStats = await _getUsageForPeriod(
      DateTime(
        previousStartDate.year,
        previousStartDate.month,
        previousStartDate.day,
      ),
      DateTime(
        previousEndDate.year,
        previousEndDate.month,
        previousEndDate.day,
        23,
        59,
        59,
      ),
    );

    final previousPeriod = PeriodStats(
      label: 'Previous $duration days',
      startDate: previousStartDate,
      endDate: previousEndDate,
      totalScreenTimeMillis: _calculateTotal(previousPeriodStats),
      topApps: _getTopApps(previousPeriodStats, 5),
      totalBlockAttempts: 0, // Not tracked for previous periods
    );

    return ComparisonStats(
      mode: ComparisonMode
          .todayVsYesterday, // Default mode, not used for custom periods
      currentPeriod: currentPeriod,
      previousPeriod: previousPeriod,
    );
  }

  /// Get comparison stats based on mode
  Future<ComparisonStats> _getComparisonStats(ComparisonMode mode) async {
    switch (mode) {
      case ComparisonMode.todayVsYesterday:
        return await getTodayVsYesterday();
      case ComparisonMode.thisWeekVsLastWeek:
        return await getThisWeekVsLastWeek();
      case ComparisonMode.thisMonthVsLastMonth:
        return await getThisMonthVsLastMonth();
      case ComparisonMode.peakDay:
        return await getPeakDayComparison();
    }
  }

  /// Compare today with yesterday
  Future<ComparisonStats> getTodayVsYesterday() async {
    final now = DateTime.now();

    // Get today's data (live from platform)
    final todayStats = await _getTodayUsage();
    final todayAttempts = await _appRepository.getTotalBlockAttempts();

    // Get yesterday's data (from Native API)
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterdayStartTime = DateTime(
      yesterdayDate.year,
      yesterdayDate.month,
      yesterdayDate.day,
    );
    final yesterdayEndTime = DateTime(
      yesterdayDate.year,
      yesterdayDate.month,
      yesterdayDate.day,
      23,
      59,
      59,
    );
    final yesterdayStats = await _getUsageForPeriod(
      yesterdayStartTime,
      yesterdayEndTime,
    );

    // Get yesterday's block attempts from database (or use current as fallback)
    final yesterdayDateKey = _formatDate(yesterdayDate);
    final yesterdayAttempts = await _databaseService.getDailyBlockAttempts(
      yesterdayDateKey,
    );

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

  /// Get usage stats for any period using Native API
  Future<List<AppUsageStats>> _getUsageForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Get usage stats directly from Native API
      final statsMap = await _platformService.getAppUsageStats(start, end);

      // ✨ NEW: Get session counts for this period
      final sessionCounts = await _platformService.getSessionCounts(start, end);

      // Filter out our own app (safety check)
      statsMap.removeWhere(
        (packageName, _) => packageName == 'com.example.block_app',
      );
      sessionCounts.removeWhere(
        (packageName, _) => packageName == 'com.example.block_app',
      );

      // Initialize icons cache if needed
      await _initializeIconsCache();

      // Convert to AppUsageStats list with real app names
      final statsList = <AppUsageStats>[];
      for (final entry in statsMap.entries) {
        String appName = entry.key;
        try {
          appName = await _platformService.getAppName(entry.key) ?? entry.key;
        } catch (e) {
          appName = entry.key;
        }

        statsList.add(
          AppUsageStats(
            packageName: entry.key,
            appName: appName,
            totalTimeInMillis: entry.value,
            date: end,
            icon: _appIconsCache[entry.key],
            openCount:
                sessionCounts[entry.key] ?? 0, // ✨ NEW: Add session count
          ),
        );
      }

      return statsList;
    } catch (e) {
      AppLogger.e('Error getting usage for period', e);
      return [];
    }
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
    final thisWeekAttempts = await _getWeekBlockAttempts(
      thisWeekStart,
      thisWeekEnd,
    );

    // Get last week's data
    final lastWeekStats = await _getWeekUsage(lastWeekStart, lastWeekEnd);
    final lastWeekAttempts = await _getWeekBlockAttempts(
      lastWeekStart,
      lastWeekEnd,
    );

    final currentPeriod = PeriodStats(
      label: 'This Week',
      startDate: DateTime(
        thisWeekStart.year,
        thisWeekStart.month,
        thisWeekStart.day,
      ),
      endDate: thisWeekEnd,
      totalScreenTimeMillis: _calculateTotal(thisWeekStats),
      topApps: _getTopApps(thisWeekStats, 5),
      totalBlockAttempts: thisWeekAttempts,
    );

    final previousPeriod = PeriodStats(
      label: 'Last Week',
      startDate: DateTime(
        lastWeekStart.year,
        lastWeekStart.month,
        lastWeekStart.day,
      ),
      endDate: DateTime(
        lastWeekEnd.year,
        lastWeekEnd.month,
        lastWeekEnd.day,
        23,
        59,
        59,
      ),
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

  /// Compare this month with last month
  Future<ComparisonStats> getThisMonthVsLastMonth() async {
    final now = DateTime.now();

    // Calculate month boundaries
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = now;

    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
    final lastMonthEnd = DateTime(
      lastMonthDate.year,
      lastMonthDate.month + 1,
      0,
      23,
      59,
      59,
    );

    // Get this month's data
    final thisMonthStats = await _getWeekUsage(thisMonthStart, thisMonthEnd);
    final thisMonthAttempts = await _getWeekBlockAttempts(
      thisMonthStart,
      thisMonthEnd,
    );

    // Get last month's data
    final lastMonthStats = await _getWeekUsage(lastMonthStart, lastMonthEnd);
    final lastMonthAttempts = await _getWeekBlockAttempts(
      lastMonthStart,
      lastMonthEnd,
    );

    final currentPeriod = PeriodStats(
      label: 'This Month',
      startDate: thisMonthStart,
      endDate: thisMonthEnd,
      totalScreenTimeMillis: _calculateTotal(thisMonthStats),
      topApps: _getTopApps(thisMonthStats, 5),
      totalBlockAttempts: thisMonthAttempts,
    );

    final previousPeriod = PeriodStats(
      label: 'Last Month',
      startDate: lastMonthStart,
      endDate: lastMonthEnd,
      totalScreenTimeMillis: _calculateTotal(lastMonthStats),
      topApps: _getTopApps(lastMonthStats, 5),
      totalBlockAttempts: lastMonthAttempts,
    );

    return ComparisonStats(
      mode: ComparisonMode.thisMonthVsLastMonth,
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
      final peakDayAttempts = await _databaseService.getDailyBlockAttempts(
        peakDate,
      );
      final peakDateTime = DateTime.parse(peakDate);

      peakPeriod = PeriodStats(
        label: 'Peak Day (${_formatDisplayDate(peakDateTime)})',
        startDate: DateTime(
          peakDateTime.year,
          peakDateTime.month,
          peakDateTime.day,
        ),
        endDate: DateTime(
          peakDateTime.year,
          peakDateTime.month,
          peakDateTime.day,
          23,
          59,
          59,
        ),
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
    // Use isolate for sorting
    return await StatisticsIsolateHelper.sortTopApps(
      apps: todayStats,
      limit: limit,
    );
  }

  /// Get top apps for a specific period
  Future<List<AppUsageStats>> getTopAppsForPeriod({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    // Default to today if no dates provided
    if (startDate == null || endDate == null) {
      return getTodayTopApps(limit: limit);
    }

    // Get usage stats from platform for the period
    final statsMap = await _platformService.getAppUsageStats(
      startDate,
      endDate,
    );

    // ✨ NEW: Get session counts for this period
    final sessionCounts = await _platformService.getSessionCounts(
      startDate,
      endDate,
    );

    // Filter out our own app (safety check)
    statsMap.removeWhere(
      (packageName, _) => packageName == 'com.example.block_app',
    );
    sessionCounts.removeWhere(
      (packageName, _) => packageName == 'com.example.block_app',
    );

    // Initialize icons cache if needed
    await _initializeIconsCache();

    // Convert to AppUsageStats list with real app names and icons
    final statsList = <AppUsageStats>[];
    for (final entry in statsMap.entries) {
      String appName = entry.key;
      try {
        appName = await _platformService.getAppName(entry.key) ?? entry.key;
      } catch (e) {
        appName = entry.key;
      }

      statsList.add(
        AppUsageStats(
          packageName: entry.key,
          appName: appName,
          totalTimeInMillis: entry.value,
          date: endDate,
          icon: _appIconsCache[entry.key], // Add icon from cache
          openCount: sessionCounts[entry.key] ?? 0, // ✨ NEW: Add session count
        ),
      );
    }

    // Sort and limit using isolate for better performance
    return await StatisticsIsolateHelper.sortTopApps(
      apps: statsList,
      limit: limit,
    );
  }

  /// Get hourly usage data for today
  Future<List<HourlyUsageData>> getHourlyUsageForToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final hourlyDataMaps = await _platformService.getHourlyUsageStats(
        startOfDay,
        now,
      );

      return hourlyDataMaps.map((map) => HourlyUsageData.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting hourly usage data', e);
      // Return empty hourly data (24 hours with 0 usage)
      return List.generate(24, (hour) => HourlyUsageData.empty(hour));
    }
  }

  /// Get hourly usage data for a specific period
  Future<List<HourlyUsageData>> getHourlyUsageForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Default to today if no dates provided
    if (startDate == null || endDate == null) {
      return getHourlyUsageForToday();
    }

    try {
      final hourlyDataMaps = await _platformService.getHourlyUsageStats(
        startDate,
        endDate,
      );

      return hourlyDataMaps.map((map) => HourlyUsageData.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting hourly usage data for period', e);
      // Return empty hourly data (24 hours with 0 usage)
      return List.generate(24, (hour) => HourlyUsageData.empty(hour));
    }
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
      AppLogger.e('Error initializing icons cache', e);
    }
  }

  /// Get today's usage from platform service
  /// Phase 2 Optimization: Uses batched getDailyStats call with request caching
  /// Combines getTodayUsageFromTrackingService + getTodaySessionCountsFromTracking
  /// + getTodayBlockAttemptsFromTracking into a single native call
  /// Result is cached for 1 second (prevents redundant native calls)
  Future<List<AppUsageStats>> _getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Phase 2: Use batched call with request caching
    // This eliminates 3 separate platform channel calls into 1 cached call
    final dailyStats = await _dailyStatsCache.get(
      'daily_stats',
      () => _platformService.getDailyStats(),
    );

    Map<String, int> statsMap = dailyStats['usage'] ?? {};
    Map<String, int> sessionCounts = dailyStats['sessions'] ?? {};
    Map<String, int> blockAttempts = dailyStats['blockAttempts'] ?? {};

    // If UsageTrackingService data is empty or stale, fallback to UsageStats API
    if (statsMap.isEmpty) {
      AppLogger.i('Falling back to UsageStats API for today\'s data');
      statsMap = await _platformService.getAppUsageStats(startOfDay, now);

      // ✨ Also fallback for session counts
      sessionCounts = await _platformService.getSessionCounts(startOfDay, now);

      // Block attempts don't have fallback (only tracked by AccessibilityService)
    } else {
      AppLogger.i(
        'Using real-time data from UsageTrackingService (${statsMap.length} apps) - cached',
      );
      AppLogger.i('Retrieved session counts for ${sessionCounts.length} apps - cached');
      AppLogger.i('Retrieved block attempts for ${blockAttempts.length} apps - cached');
    }

    // Filter out our own app (safety check in case native filter missed it)
    statsMap.removeWhere(
      (packageName, _) => packageName == 'com.example.block_app',
    );
    sessionCounts.removeWhere(
      (packageName, _) => packageName == 'com.example.block_app',
    );
    blockAttempts.removeWhere(
      (packageName, _) => packageName == 'com.example.block_app',
    );

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

      statsList.add(
        AppUsageStats(
          packageName: entry.key,
          appName: appName,
          totalTimeInMillis: entry.value,
          date: now,
          icon: _appIconsCache[entry.key],
          openCount: sessionCounts[entry.key] ?? 0, // ✨ Add session count
          blockAttempts:
              blockAttempts[entry.key] ?? 0, // ✨ NEW: Add block attempts
        ),
      );
    }

    return statsList;
  }

  /// Get aggregated usage for a period (using Native API directly)
  Future<List<AppUsageStats>> _getWeekUsage(
    DateTime start,
    DateTime end,
  ) async {
    return await _getUsageForPeriod(start, end);
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

  /// Format DateTime to YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date for display (e.g., "Jan 15")
  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is yesterday
  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Reset all statistics (Clear Native Storage + Local Database if needed)
  Future<void> resetStatistics() async {
    // 1. Clear Native Storage (Source of Truth for Today)
    await _platformService.clearUsageData();

    // 2. Clear Local Database (Source of Truth for History)
    // For now, let's just clear native cache which fixes the immediate "stale/corruption" issue
    // If user wants full wipe, we can add database clean call here
  }
}
