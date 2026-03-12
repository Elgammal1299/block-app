import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../../core/utils/app_logger.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../view_model/schedule_cubit/schedule_cubit.dart';
import '../../view_model/schedule_cubit/schedule_state.dart';
import '../../view_model/usage_limit_cubit/usage_limit_cubit.dart';
import '../../view_model/usage_limit_cubit/usage_limit_state.dart';
import '../../view_model/statistics_cubit/statistics_cubit.dart';
import '../../view_model/daily_goal_cubit/daily_goal_cubit.dart';
import '../../view_model/gamification_cubit/gamification_cubit.dart';
import '../../view_model/suggestions_cubit/suggestions_cubit.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/home/quick_stat_card.dart';
import '../widgets/home/quick_action_card.dart';
import '../widgets/app_category_filter.dart';
import '../widgets/home/modes_row.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  AppCategory _selectedCategory = AppCategory.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // CRITICAL: Load data first, then sync to native (Sequential, not parallel!)
      await _loadData();
      await _initializeService();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        getIt<DailyGoalCubit>().loadDailyGoal(),
        getIt<GamificationCubit>().loadUserProgress(),
        getIt<SmartSuggestionsCubit>().generateSuggestions(),
        getIt<StatisticsCubit>().loadDashboard(),
      ]);
    } catch (e) {
      AppLogger.e('Error loading home screen data', e);
    }
  }

  Future<void> _initializeService() async {
    try {
      await _syncDataToNative();
      final platformService = getIt<PlatformChannelService>();
      await platformService.startMonitoringService();
      await platformService.startUsageTrackingService();
    } catch (e) {
      AppLogger.e('Error initializing service', e);
    }
  }

  Future<void> _syncDataToNative() async {
    try {
      final scheduleCubit = getIt<ScheduleCubit>();
      final blockedAppsCubit = getIt<BlockedAppsCubit>();
      final platformService = getIt<PlatformChannelService>();

      if (scheduleCubit.state is ScheduleInitial) {
        await scheduleCubit.loadSchedules();
      }
      if (blockedAppsCubit.state is BlockedAppsInitial) {
        await blockedAppsCubit.loadBlockedApps();
      }

      final scheduleState = scheduleCubit.state;
      if (scheduleState is ScheduleLoaded) {
        await platformService.updateSchedules(scheduleState.schedules);
      }

      final blockedAppsState = blockedAppsCubit.state;
      if (blockedAppsState is BlockedAppsLoaded) {
        final blockedApps = blockedAppsState.blockedApps;
        final appsJson = jsonEncode(
          blockedApps.map((app) => app.toJson()).toList(),
        );
        await platformService.updateBlockedAppsJson(appsJson);
      }
    } catch (e) {
      AppLogger.e('Error syncing data to Native', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<DailyGoalCubit>()),
        BlocProvider.value(value: getIt<GamificationCubit>()),
        BlocProvider.value(value: getIt<SmartSuggestionsCubit>()),
        BlocProvider.value(value: getIt<FocusSessionCubit>()),
        BlocProvider.value(value: getIt<ScheduleCubit>()),
        BlocProvider.value(value: getIt<BlockedAppsCubit>()),
        BlocProvider.value(value: getIt<UsageLimitCubit>()),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 80,

          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Text(
                'App Block',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Block Card
                  _buildQuickBlockCard(context),
                  const SizedBox(height: 24),

                  // Quick Actions Section (2x2 Grid)
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 32),

                  // Focus Modes Row
                  const ModesRow(),

                  // Search and Filter Section
                  // _buildSearchAndFilter(context),

                  // Active Schedules Section
                  // _buildSchedulesPreview(context),

                  // Blocked Apps Preview
                  // _buildBlockedAppsPreview(context),
                  // Quick Stats Cards (Solid Red for Blocked)
                  const SizedBox(height: 20),
                  _buildQuickStatsCards(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     Navigator.of(context).pushNamed(AppRoutes.appSelection);
        //   },
        //   backgroundColor: const Color(0xFF1877F2),
        //   child: const Icon(Icons.add, color: Colors.white, size: 28),
        // ),
      ),
    );
  }

  Widget _buildQuickBlockCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Start Button
                ElevatedButton(
                  onPressed: () {
                    // This button should ideally switch to the Focus tab
                    // For now, we'll just keep it as is or navigate to focus lists if available
                    Navigator.of(context).pushNamed(AppRoutes.focusLists);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'هيا نبدأ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Title and Icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          'الحظر السريع',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.flash_on_rounded,
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'قم بحظر المشتتات بضغطة واحدة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider and bottom section
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacing12,
              horizontal: AppTheme.spacing20,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLarge),
                bottomRight: Radius.circular(AppTheme.radiusLarge),
              ),
              border: Border(
                top: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'المؤقت & طريقة البومودورو',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentWarning,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(BuildContext context) {
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
                  schedulesCount = scheduleState.schedules
                      .where((s) => s.isEnabled)
                      .length;
                }
                if (usageLimitState is UsageLimitLoaded) {
                  limitsCount = usageLimitState.limits.length;
                }

                return Column(
                  children: [
                    QuickStatCard(
                      label: 'محظور',
                      value: blockedCount.toString(),
                      icon: Icons.block,
                      color: AppTheme.accentError,
                      isSolid: true, // Matching mockup (Red card)
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.blockedAppsList),
                    ),
                    const SizedBox(height: 12),
                    QuickStatCard(
                      label: 'جداول نشطة',
                      value: schedulesCount.toString(),
                      icon: Icons.schedule,
                      color: AppTheme.accentSuccess,
                      isSolid: true,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.schedules),
                    ),
                    const SizedBox(height: 12),
                    QuickStatCard(
                      label: 'حدود استخدام',
                      value: limitsCount.toString(),
                      icon: Icons.timer,
                      color: AppTheme.accentWarning,
                      isSolid: true,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.usageLimitSelection),
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        QuickActionCard(
          title: 'حظر التطبيقات',
          subtitle: 'إضافة تطبيق للحظر',
          icon: Icons.add_circle_outline,
          color: AppTheme.accentError,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.appSelection),
        ),
        QuickActionCard(
          title: 'جداول زمنية',
          subtitle: 'حظر حسب الوقت',
          icon: Icons.calendar_today,
          color: AppTheme.accentSuccess,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.schedules),
        ),
        QuickActionCard(
          title: 'حدود الاستخدام',
          subtitle: 'تحديد حدود يومية',
          icon: Icons.timer_outlined,
          color: AppTheme.accentWarning,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.usageLimitSelection),
        ),
        QuickActionCard(
          title: 'قائمة المحظورات',
          subtitle: 'عرض كل المحظورات',
          icon: Icons.list_alt,
          color: AppTheme.accentInfo,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.blockedAppsList),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن تطبيق...',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Category Filter
        const Text(
          'التصنيفات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        AppCategoryFilter(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSchedulesPreview(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      bloc: getIt<ScheduleCubit>(),
      builder: (context, scheduleState) {
        if (scheduleState is ScheduleLoaded &&
            scheduleState.schedules.isNotEmpty) {
          final activeSchedules = scheduleState.schedules
              .where((s) => s.isEnabled)
              .take(3)
              .toList();
          if (activeSchedules.isEmpty) {
            return _buildEmptySchedules();
          }

          return BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
            bloc: getIt<BlockedAppsCubit>(),
            builder: (context, blockedAppsState) {
              // Get blocked apps count for each schedule
              int getAppsCountForSchedule(String scheduleId) {
                if (blockedAppsState is BlockedAppsLoaded) {
                  return blockedAppsState.blockedApps
                      .where((app) => app.scheduleIds.contains(scheduleId))
                      .length;
                }
                return 0;
              }

              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: activeSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = activeSchedules[index];
                    final appsCount = getAppsCountForSchedule(schedule.id);

                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(
                        left: index == activeSchedules.length - 1 ? 0 : 12,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'نشط',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: Text(
                              schedule.getDaysString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${schedule.startTimeFormatted} - ${schedule.endTimeFormatted}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.block,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$appsCount تطبيق',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
        return _buildEmptySchedules();
      },
    );
  }

  Widget _buildEmptySchedules() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد جداول نشطة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('أنشئ جدولاً جديداً للبدء', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsPreview(BuildContext context) {
    return BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
      bloc: getIt<BlockedAppsCubit>(),
      builder: (context, state) {
        if (state is BlockedAppsLoaded && state.blockedApps.isNotEmpty) {
          final apps = state.blockedApps.take(5).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.blockedAppsList);
                    },
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: Color(0xFF1877F2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'محظور مؤخراً',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...apps.map(
                (app) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (app.blockAttempts > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: app.blockAttempts > 10
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${app.blockAttempts}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              app.appName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app.scheduleIds.isEmpty
                                  ? 'محظور دائماً'
                                  : '${app.scheduleIds.length} جدول',
                              style: TextStyle(
                                fontSize: 13,
                                color: app.scheduleIds.isEmpty
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.block,
                          color: AppTheme.accentError,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return _buildEmptyBlockedApps();
      },
    );
  }

  Widget _buildEmptyBlockedApps() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.block_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تطبيقات محظورة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('ابدأ بحظر تطبيق الآن!', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.appSelection);
            },
            icon: const Icon(Icons.add),
            label: const Text('حظر تطبيق'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      getIt<DailyGoalCubit>().loadDailyGoal(),
      getIt<BlockedAppsCubit>().loadBlockedApps(),
      getIt<ScheduleCubit>().loadSchedules(),
      getIt<UsageLimitCubit>().loadUsageLimits(),
    ]);
  }
}
