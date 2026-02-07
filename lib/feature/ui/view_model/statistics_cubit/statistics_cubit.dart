import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/comparison_stats.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'statistics_state.dart';

/// Cubit for managing statistics dashboard state
class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository _statisticsRepository;
  final PlatformChannelService _platformService;

  ComparisonMode _currentMode = ComparisonMode.todayVsYesterday;

  // Cache OEM check result
  bool? _hasOEMRestrictions;
  String? _manufacturer;

  // Debouncing timer for refresh operations
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  // Track if a load is in progress
  bool _isLoading = false;

  // Cache last successful load timestamp to prevent too frequent refreshes
  DateTime? _lastLoadTime;
  static const _minRefreshInterval = Duration(seconds: 5);

  StatisticsCubit(this._statisticsRepository, this._platformService)
    : super(StatisticsInitial());

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// Load dashboard data for the selected comparison mode
  /// Optional [startDate] and [endDate] to filter data for specific period
  Future<void> loadDashboard({
    ComparisonMode? mode,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (_isLoading) return;

    // Prevent too frequent refreshes (unless forced)
    if (!forceRefresh && _lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad < _minRefreshInterval) {
        return;
      }
    }

    if (mode != null) _currentMode = mode;

    _isLoading = true;
    emit(StatisticsLoading());

    try {
      // Check OEM restrictions once
      if (_hasOEMRestrictions == null) {
        await _checkOEMRestrictions();
      }

      final dashboardData = await _statisticsRepository.getDashboardData(
        _currentMode,
        startDate: startDate,
        endDate: endDate,
      );

      if (!isClosed) {
        _lastLoadTime = DateTime.now();
        emit(
          StatisticsDashboardLoaded(
            dashboardData: dashboardData,
            currentMode: _currentMode,
            hasOEMRestrictions: _hasOEMRestrictions ?? false,
            manufacturer: _manufacturer ?? '',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(StatisticsError(e.toString()));
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Check if device has OEM restrictions
  Future<void> _checkOEMRestrictions() async {
    try {
      final result = await _platformService.checkOEMRestrictions();
      _hasOEMRestrictions = result['hasRestrictions'] as bool;
      _manufacturer = result['manufacturer'] as String;
    } catch (e) {
      _hasOEMRestrictions = false;
      _manufacturer = 'unknown';
    }
  }

  /// Change comparison mode and reload data
  Future<void> changeComparisonMode(ComparisonMode mode) async {
    await loadDashboard(mode: mode);
  }

  /// Load dashboard data for a specific time period
  Future<void> loadDashboardForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await loadDashboard(startDate: startDate, endDate: endDate);
  }

  /// Refresh current dashboard data (debounced)
  Future<void> refresh() async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      loadDashboard();
    });
  }

  /// Refresh immediately without debouncing (force refresh)
  Future<void> refreshImmediate() async {
    _debounceTimer?.cancel();
    await loadDashboard(forceRefresh: true);
  }

  /// Save today's snapshot (call from app lifecycle or periodically)
  Future<void> saveTodaySnapshot() async {
    try {
      await _statisticsRepository.saveTodaySnapshot();
    } catch (e) {
      // Silent fail - don't disrupt the app
      // In production, log this error
    }
  }

  /// Clean stored usage data (remove our own app from statistics)
  /// This should be called once on app startup to clean any old data
  Future<void> cleanOwnAppFromStatistics() async {
    try {
      await _platformService.cleanStoredUsageData();
      AppLogger.i('Successfully cleaned own app from statistics');
    } catch (e) {
      // Silent fail - don't disrupt the app
      AppLogger.w('Error cleaning own app from statistics: $e');
    }
  }

  /// Get current comparison mode
  ComparisonMode get currentMode => _currentMode;

  /// Reset all statistics data (Debug feature to fix corrupted stats)
  Future<void> resetStatistics() async {
    try {
      emit(StatisticsLoading());
      await _statisticsRepository.resetStatistics();
      // Reload dashboard after reset
      await loadDashboard(forceRefresh: true);
    } catch (e) {
      emit(StatisticsError('Failed to reset statistics: $e'));
    }
  }
}
