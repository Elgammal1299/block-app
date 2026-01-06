import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../view_model/statistics_cubit/statistics_cubit.dart';
import '../../view_model/statistics_cubit/statistics_state.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../widgets/statistics/top_apps_list_card.dart';
import '../widgets/statistics/hourly_usage_chart.dart';
import '../widgets/statistics/usage_summary_card.dart';
import '../widgets/statistics/time_period_filter.dart';
import '../widgets/statistics/block_attempts_card.dart';

/// Radical, custom statistics dashboard used inside the bottom NavBar.
///

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() =>
      _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen> {
  late StatisticsCubit _statisticsCubit;

  TimePeriod _selectedPeriod = TimePeriod.today;

  @override
  void initState() {
    super.initState();
    _statisticsCubit = getIt<StatisticsCubit>();

    // Clean our own app from statistics (one-time cleanup on first load)
    _statisticsCubit.cleanOwnAppFromStatistics();

    // Load initial data
    _statisticsCubit.loadDashboard();

    // Save today's snapshot
    _statisticsCubit.saveTodaySnapshot();
  }

  /// Get display label for the selected period
  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return 'إجمالي الاستخدام اليوم';
      case TimePeriod.yesterday:
        return 'إجمالي الاستخدام بالأمس';
      case TimePeriod.last7Days:
        return 'إجمالي الاستخدام (آخر 7 أيام)';
      case TimePeriod.last14Days:
        return 'إجمالي الاستخدام (آخر 14 يوم)';
      case TimePeriod.last30Days:
        return 'إجمالي الاستخدام (آخر 30 يوم)';
    }
  }

  /// Get block attempts label for the selected period
  String _getBlockAttemptsLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return 'محاولات الحظر اليوم';
      case TimePeriod.yesterday:
        return 'محاولات الحظر بالأمس';
      case TimePeriod.last7Days:
        return 'محاولات الحظر (آخر 7 أيام)';
      case TimePeriod.last14Days:
        return 'محاولات الحظر (آخر 14 يوم)';
      case TimePeriod.last30Days:
        return 'محاولات الحظر (آخر 30 يوم)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      bloc: _statisticsCubit,
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return _buildLoadingState();
        } else if (state is StatisticsError) {
          return _buildErrorState(state.message);
        } else if (state is StatisticsDashboardLoaded) {
          return _buildDashboard(context, state);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    StatisticsDashboardLoaded state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await _statisticsCubit.refresh();
      },
      child: SafeArea(
        bottom: true,
        child: ColoredBox(
          color: colorScheme.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _buildPageHeader(theme),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: TimePeriodFilter(
                    selectedPeriod: _selectedPeriod,
                    onChanged: (period) {
                      setState(() {
                        _selectedPeriod = period;
                      });

                      // Get date range for selected period
                      final dateRange = period.getDateRange();

                      // Reload dashboard with selected period
                      _statisticsCubit.loadDashboardForPeriod(
                        startDate: dateRange.start,
                        endDate: dateRange.end,
                      );
                    },
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: UsageSummaryCard(
                    totalUsageTime:
                        state.comparisonStats.currentPeriod.formattedTotalTime,
                    totalAppsUsed: state.totalAppsUsedToday,
                    comparisonLabel: state.comparisonStats.comparisonLabel,
                    isIncrease: state.comparisonStats.isIncrease,
                    periodLabel: _getPeriodLabel(_selectedPeriod),
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: BlockAttemptsCard(
                    totalAttempts:
                        state.comparisonStats.currentPeriod.totalBlockAttempts,
                    periodLabel: _getBlockAttemptsLabel(_selectedPeriod),
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: HourlyUsageChart(
                    hourlyData: state.hourlyUsageData,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: TopAppsListCard(
                    topApps: state.topApps,
                    usageLimitsMap: state.dashboardData.usageLimitsMap,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لوحة الإحصائيات',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'تابع أبرز المؤشرات، وقارن الفترات بسهولة، مع تصميم مرتب للموبايل.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading statistics...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Error Loading Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _statisticsCubit.refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Statistics Yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start using apps to see your statistics here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
