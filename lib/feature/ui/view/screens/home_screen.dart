import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../view_model/schedule_cubit/schedule_cubit.dart';
import '../../view_model/schedule_cubit/schedule_state.dart';
// import '../../view_model/theme_cubit/theme_cubit.dart';
// import '../../view_model/theme_cubit/theme_state.dart';
// import '../../view_model/locale_cubit/locale_cubit.dart';
// import '../../view_model/locale_cubit/locale_state.dart';
// import '../../../../core/localization/app_localizations.dart';
import '../../view_model/daily_goal_cubit/daily_goal_cubit.dart';
import '../../view_model/gamification_cubit/gamification_cubit.dart';
import '../../view_model/suggestions_cubit/suggestions_cubit.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/home/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        getIt<DailyGoalCubit>().loadDailyGoal(),
        getIt<GamificationCubit>().loadUserProgress(),
        getIt<SmartSuggestionsCubit>().generateSuggestions(),
      ]);
    } catch (e) {
      print('Error loading home screen data: $e');
    }
  }

  Future<void> _initializeService() async {
    try {
      await _syncDataToNative();
      final platformService = getIt<PlatformChannelService>();
      await platformService.startMonitoringService();
      await platformService.startUsageTrackingService();
    } catch (e) {
      print('Error initializing service: $e');
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
      print('Error syncing data to Native: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DailyGoalCubit>()),
        BlocProvider(create: (_) => getIt<GamificationCubit>()),
        BlocProvider(create: (_) => getIt<SmartSuggestionsCubit>()),
        BlocProvider.value(value: getIt<FocusSessionCubit>()),
        BlocProvider.value(value: getIt<ScheduleCubit>()),
        BlocProvider.value(
          value: getIt<BlockedAppsCubit>(),
        ), // Ensure BlockedAppsCubit is provided for calculations
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FA),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 16),
                  _buildWhiteQuickBlockCard(context),
                  const SizedBox(height: 24),
                  _buildDualActionCard(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteQuickBlockCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      '0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.block, size: 14, color: Colors.grey[600]),
                  ],
                ),
              ),
              const Text(
                'الحظر السريع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'ابدأ الحظر فورًا بضغطة واحدة.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.quickBlockSettings);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'هيا نبدأ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.play_arrow_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.diamond, color: Colors.orange[700], size: 20),
                const Text(
                  'المؤقت & طريقة البومودورو',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.timer_outlined, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualActionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.schedules),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF1877F2),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'جدول جديد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: Colors.grey[200],
            ),
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.usageLimitSelection),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[600]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.timer_rounded,
                          color: Colors.orange[600],
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'حد التطبيق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      getIt<DailyGoalCubit>().loadDailyGoal(),
      getIt<BlockedAppsCubit>().loadBlockedApps(),
      getIt<ScheduleCubit>().loadSchedules(),
    ]);
  }
}
