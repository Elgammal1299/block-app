import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/comparison_stats.dart';
import '../../view_model/statistics_cubit/statistics_cubit.dart';
import '../../view_model/statistics_cubit/statistics_state.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../widgets/statistics/comparison_card.dart';
import '../widgets/statistics/pie_chart_card.dart';
import '../widgets/statistics/top_apps_list_card.dart';
import '../widgets/statistics/block_attempts_card.dart';

/// Main statistics dashboard screen with comparison modes
class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() =>
      _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StatisticsCubit _statisticsCubit;

  final List<ComparisonMode> _comparisonModes = [
    ComparisonMode.todayVsYesterday,
    ComparisonMode.thisWeekVsLastWeek,
    ComparisonMode.peakDay,
  ];

  @override
  void initState() {
    super.initState();
    _statisticsCubit = getIt<StatisticsCubit>();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    _statisticsCubit.loadDashboard();

    // Save today's snapshot
    _statisticsCubit.saveTodaySnapshot();

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _statisticsCubit.changeComparisonMode(_comparisonModes[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _statisticsCubit.refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.today),
              text: 'Daily',
            ),
            Tab(
              icon: Icon(Icons.calendar_view_week),
              text: 'Weekly',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Peak',
            ),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
        ),
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        bloc: _statisticsCubit,
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return _buildLoadingState();
          } else if (state is StatisticsError) {
            return _buildErrorState(state.message);
          } else if (state is StatisticsDashboardLoaded) {
            return _buildDashboard(state);
          }

          return _buildEmptyState();
        },
      ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildDashboard(StatisticsDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        await _statisticsCubit.refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Comparison Card
            ComparisonCard(
              stats: state.comparisonStats,
            ),

            // Block Attempts Card
            BlockAttemptsCard(
              totalAttempts: state.totalBlockAttempts,
            ),

            // Pie Chart Card
            PieChartCard(
              data: state.pieChartData,
            ),

            // Top Apps List
            TopAppsListCard(
              topApps: state.topApps,
              usageLimitsMap: state.dashboardData.usageLimitsMap,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
