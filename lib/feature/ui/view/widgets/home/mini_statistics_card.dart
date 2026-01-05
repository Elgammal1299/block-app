import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/statistics_cubit/statistics_cubit.dart';
import '../../../view_model/statistics_cubit/statistics_state.dart';
import '../../../../../core/router/app_routes.dart';

class MiniStatisticsCard extends StatelessWidget {
  const MiniStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! StatisticsDashboardLoaded) {
          return const SizedBox.shrink();
        }

        final data = state.dashboardData;
        final topApps = data.todayTopApps.take(3).toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أكثر التطبيقات استخداماً',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.statisticsDashboard);
                      },
                      child: const Text('عرض المزيد'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (topApps.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'لا توجد بيانات بعد',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...topApps.map((app) => _buildAppItem(context, app)),

                const SizedBox(height: 12),

                // Block attempts today
                Row(
                  children: [
                    Icon(
                      Icons.block,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'محاولات الحظر اليوم: ${data.totalBlockAttempts}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppItem(BuildContext context, dynamic app) {
    final theme = Theme.of(context);
    final totalMinutes = (app.totalTimeInMillis / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final timeText = hours > 0
        ? '$hours س $minutes د'
        : '$minutes د';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.apps,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
