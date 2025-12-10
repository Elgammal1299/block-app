import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_usage_stats.dart';
import '../../../data/repositories/app_repository.dart';
import 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final AppRepository _appRepository;

  StatisticsCubit(this._appRepository) : super(StatisticsInitial());

  Future<void> loadDailyStats() async {
    emit(StatisticsLoading());
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final statsMap = await _appRepository.getAppUsageStats(startOfDay, endOfDay);

      final dailyStats = statsMap.entries
          .map((entry) => AppUsageStats.fromMap(
                entry.key,
                entry.key, // We'll need to get app name separately
                entry.value,
                now,
              ))
          .toList()
        ..sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));

      if (state is StatisticsLoaded) {
        final currentState = state as StatisticsLoaded;
        emit(StatisticsLoaded(
          dailyStats: dailyStats,
          weeklyStats: currentState.weeklyStats,
        ));
      } else {
        emit(StatisticsLoaded(dailyStats: dailyStats, weeklyStats: []));
      }
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  Future<void> loadWeeklyStats() async {
    emit(StatisticsLoading());
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final statsMap =
          await _appRepository.getAppUsageStats(startOfWeekDay, endOfWeek);

      final weeklyStats = statsMap.entries
          .map((entry) => AppUsageStats.fromMap(
                entry.key,
                entry.key, // We'll need to get app name separately
                entry.value,
                now,
              ))
          .toList()
        ..sort((a, b) => b.totalTimeInMillis.compareTo(a.totalTimeInMillis));

      if (state is StatisticsLoaded) {
        final currentState = state as StatisticsLoaded;
        emit(StatisticsLoaded(
          dailyStats: currentState.dailyStats,
          weeklyStats: weeklyStats,
        ));
      } else {
        emit(StatisticsLoaded(dailyStats: [], weeklyStats: weeklyStats));
      }
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadDailyStats();
    await loadWeeklyStats();
  }
}
