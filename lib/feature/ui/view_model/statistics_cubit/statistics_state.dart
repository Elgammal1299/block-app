import 'package:equatable/equatable.dart';
import '../../../data/models/app_usage_stats.dart';
import '../../../data/models/comparison_stats.dart';
import '../../../data/models/statistics_dashboard_data.dart';
import '../../../data/models/hourly_usage_data.dart';

/// Base state for statistics
abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when cubit is created
class StatisticsInitial extends StatisticsState {}

/// Loading state when fetching statistics data
class StatisticsLoading extends StatisticsState {}

/// Loaded state with dashboard data
class StatisticsDashboardLoaded extends StatisticsState {
  final StatisticsDashboardData dashboardData;
  final ComparisonMode currentMode;
  final bool hasOEMRestrictions;
  final String manufacturer;

  const StatisticsDashboardLoaded({
    required this.dashboardData,
    required this.currentMode,
    this.hasOEMRestrictions = false,
    this.manufacturer = '',
  });

  @override
  List<Object?> get props => [dashboardData, currentMode, hasOEMRestrictions, manufacturer];

  // Convenience getters
  ComparisonStats get comparisonStats => dashboardData.comparisonStats;
  List<AppUsageStats> get topApps => dashboardData.todayTopApps;
  int get totalBlockAttempts => dashboardData.totalBlockAttempts;
  List<PieChartData> get pieChartData => dashboardData.pieChartData;
  List<HourlyUsageData> get hourlyUsageData => dashboardData.hourlyUsageData;
  int get totalAppsUsedToday => dashboardData.totalAppsUsedToday;

  // Get comparison label based on current mode
  String get comparisonLabel {
    switch (currentMode) {
      case ComparisonMode.todayVsYesterday:
        return 'Today vs Yesterday';
      case ComparisonMode.thisWeekVsLastWeek:
        return 'This Week vs Last Week';
      case ComparisonMode.thisMonthVsLastMonth:
        return 'This Month vs Last Month';
      case ComparisonMode.peakDay:
        return 'Peak Day (Last 7 Days)';
    }
  }
}

/// Error state when something goes wrong
class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
