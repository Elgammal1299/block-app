import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/DI/setup_get_it.dart';
import '../../../core/router/app_routes.dart';
import '../../ui/view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../ui/view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../ui/view_model/schedule_cubit/schedule_cubit.dart';
import '../../ui/view_model/schedule_cubit/schedule_state.dart';
import '../../ui/view_model/usage_limit_cubit/usage_limit_cubit.dart';
import '../../ui/view_model/usage_limit_cubit/usage_limit_state.dart';

/// Control Screen - Main hub for app blocking, schedules, and usage limits
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await getIt<BlockedAppsCubit>().loadBlockedApps();
          await getIt<ScheduleCubit>().loadSchedules();
          await getIt<UsageLimitCubit>().loadUsageLimits();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'App Control',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage blocked apps, schedules, and usage limits',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats Cards
              _buildQuickStatsSection(),
              const SizedBox(height: 24),

              // Main Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMainActionsGrid(context),
              const SizedBox(height: 24),

              // Blocked Apps Preview
              _buildBlockedAppsPreview(context),
              const SizedBox(height: 24),

              // Schedules Preview
              _buildSchedulesPreview(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.appSelection);
        },
        icon: const Icon(Icons.block),
        label: const Text('Block Apps'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
      bloc: getIt<BlockedAppsCubit>(),
      builder: (context, blockedAppsState) {
        return BlocBuilder<ScheduleCubit, ScheduleState>(
          bloc: getIt<ScheduleCubit>(),
          builder: (context, scheduleState) {
            return BlocBuilder<UsageLimitCubit, UsageLimitState>(
              bloc: getIt<UsageLimitCubit>(),
              builder: (context, usageLimitState) {
                int blockedCount = 0;
                int schedulesCount = 0;
                int limitsCount = 0;

                if (blockedAppsState is BlockedAppsLoaded) {
                  blockedCount = blockedAppsState.blockedApps.length;
                }
                if (scheduleState is ScheduleLoaded) {
                  schedulesCount = scheduleState.schedules.where((s) => s.isEnabled).length;
                }
                if (usageLimitState is UsageLimitLoaded) {
                  limitsCount = usageLimitState.limits.length;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Blocked\nApps',
                        blockedCount.toString(),
                        Icons.block,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Active\nSchedules',
                        schedulesCount.toString(),
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Usage\nLimits',
                        limitsCount.toString(),
                        Icons.timer,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          context,
          'Block Apps',
          'Add apps to block',
          Icons.add_circle_outline,
          Colors.red,
          () => Navigator.of(context).pushNamed(AppRoutes.appSelection),
        ),
        _buildActionCard(
          context,
          'Schedules',
          'Time-based blocking',
          Icons.calendar_today,
          Colors.green,
          () => Navigator.of(context).pushNamed(AppRoutes.schedules),
        ),
        _buildActionCard(
          context,
          'Usage Limits',
          'Set daily limits',
          Icons.timer_outlined,
          Colors.orange,
          () => Navigator.of(context).pushNamed(AppRoutes.usageLimitSelection),
        ),
        _buildActionCard(
          context,
          'Blocked List',
          'View all blocked',
          Icons.list_alt,
          Colors.purple,
          () => Navigator.of(context).pushNamed(AppRoutes.blockedAppsList),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedAppsPreview(BuildContext context) {
    return BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
      bloc: getIt<BlockedAppsCubit>(),
      builder: (context, state) {
        if (state is BlockedAppsLoaded && state.blockedApps.isNotEmpty) {
          final apps = state.blockedApps.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Blocked',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.blockedAppsList);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...apps.map((app) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.block, color: Colors.red, size: 24),
                      ),
                      title: Text(
                        app.appName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        app.scheduleIds.isEmpty
                            ? 'Always blocked'
                            : '${app.scheduleIds.length} schedule(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: app.scheduleIds.isEmpty ? Colors.red : Colors.blue,
                        ),
                      ),
                      trailing: app.blockAttempts > 0
                          ? Chip(
                              label: Text(
                                '${app.blockAttempts}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.orange[100],
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    ),
                  )),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSchedulesPreview(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      bloc: getIt<ScheduleCubit>(),
      builder: (context, state) {
        if (state is ScheduleLoaded && state.schedules.isNotEmpty) {
          final activeSchedules = state.schedules.where((s) => s.isEnabled).take(2).toList();
          if (activeSchedules.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Schedules',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.schedules);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...activeSchedules.map((schedule) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule, color: Colors.green, size: 24),
                      ),
                      title: Text(
                        schedule.getDaysString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${schedule.startTimeFormatted} - ${schedule.endTimeFormatted}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                    ),
                  )),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
