import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/comparison_stats.dart';
import '../../../data/repositories/statistics_repository.dart';
import 'statistics_state.dart';

/// Cubit for managing statistics dashboard state
class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository _statisticsRepository;

  ComparisonMode _currentMode = ComparisonMode.todayVsYesterday;

  StatisticsCubit(this._statisticsRepository) : super(StatisticsInitial());

  /// Load dashboard data for the selected comparison mode
  Future<void> loadDashboard({ComparisonMode? mode}) async {
    if (mode != null) _currentMode = mode;

    emit(StatisticsLoading());
    try {
      final dashboardData = await _statisticsRepository.getDashboardData(_currentMode);
      emit(StatisticsDashboardLoaded(
        dashboardData: dashboardData,
        currentMode: _currentMode,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  /// Change comparison mode and reload data
  Future<void> changeComparisonMode(ComparisonMode mode) async {
    await loadDashboard(mode: mode);
  }

  /// Refresh current dashboard data
  Future<void> refresh() async {
    await loadDashboard();
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

  /// Get current comparison mode
  ComparisonMode get currentMode => _currentMode;
}
