import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../view_model/schedule_cubit/schedule_cubit.dart';
import '../../view_model/schedule_cubit/schedule_state.dart';
import '../../view_model/theme_cubit/theme_cubit.dart';
import '../../view_model/theme_cubit/theme_state.dart';
import '../../view_model/locale_cubit/locale_cubit.dart';
import '../../view_model/locale_cubit/locale_state.dart';
import '../../view_model/daily_goal_cubit/daily_goal_cubit.dart';
import '../../view_model/gamification_cubit/gamification_cubit.dart';
import '../../view_model/suggestions_cubit/suggestions_cubit.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/home/simple_daily_goal_card.dart';
import '../widgets/home/quick_actions_section.dart';
import '../widgets/home/focus_modes_grid.dart';
import '../widgets/home/achievements_banner.dart';
import '../widgets/home/smart_suggestion_card.dart';
import '../widgets/home/active_schedule_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start monitoring service and sync data automatically
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
      // Sync schedules and blocked apps to Native
      await _syncDataToNative();

      // Start monitoring service
      final platformService = getIt<PlatformChannelService>();
      await platformService.startMonitoringService();

      // Start usage tracking service for accurate statistics
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

      // Ensure data is loaded at least once before syncing
      if (scheduleCubit.state is ScheduleInitial) {
        await scheduleCubit.loadSchedules();
      }
      if (blockedAppsCubit.state is BlockedAppsInitial) {
        await blockedAppsCubit.loadBlockedApps();
      }

      // Sync schedules
      final scheduleState = scheduleCubit.state;
      if (scheduleState is ScheduleLoaded) {
        final schedules = scheduleState.schedules;
        await platformService.updateSchedules(schedules);
        print('Synced ${schedules.length} schedules to Native');
      }

      // Sync blocked apps
      final blockedAppsState = blockedAppsCubit.state;
      if (blockedAppsState is BlockedAppsLoaded) {
        final blockedApps = blockedAppsState.blockedApps;
        final appsJson = jsonEncode(blockedApps.map((app) => app.toJson()).toList());
        await platformService.updateBlockedAppsJson(appsJson);
        print('Synced ${blockedApps.length} blocked apps to Native');
      }
    } catch (e) {
      print('Error syncing data to Native: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<DailyGoalCubit>(),
        ),
        BlocProvider(
          create: (_) => getIt<GamificationCubit>(),
        ),
        BlocProvider(
          create: (_) => getIt<SmartSuggestionsCubit>(),
        ),
        BlocProvider.value(
          value: getIt<FocusSessionCubit>(),
        ),
        BlocProvider.value(
          value: getIt<ScheduleCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: _buildSettingsDrawer(context, localizations),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Quick Block Section
                _buildQuickBlockSection(context),
                const SizedBox(height: 24),

                // 2. Pomodoro Section
                _buildPomodoroSection(context),
                const SizedBox(height: 24),

                // 3. Quick Modes Section
                _buildSectionHeader(context, 'الأوضاع السريعة', Icons.flash_on),
                const SizedBox(height: 12),
                const FocusModesGrid(),
                const SizedBox(height: 20),

                // 4. Daily Goal Card
                const SimpleDailyGoalCard(),
                const SizedBox(height: 16),

                // 5. Smart Suggestion
                const SmartSuggestionCard(),
                const SizedBox(height: 16),

                // 6. Achievements
                _buildSectionHeader(context, 'الإنجازات', Icons.emoji_events),
                const SizedBox(height: 12),
                const AchievementsBanner(),
                const SizedBox(height: 16),

                // 7. Active Schedule Preview
                const ActiveSchedulePreview(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      getIt<DailyGoalCubit>().loadDailyGoal(),
      getIt<GamificationCubit>().loadUserProgress(),
      getIt<SmartSuggestionsCubit>().generateSuggestions(),
      getIt<BlockedAppsCubit>().loadBlockedApps(),
      getIt<ScheduleCubit>().loadSchedules(),
    ]);
  }

  Widget _buildQuickBlockSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'الحظر السريع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ الحظر فورا بضغطة واحدة.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.quickBlockSettings);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'هيا نبدأ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'المؤقت & طريقة البومودورو',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.diamond,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timer,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'البرومودورو',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.diamond,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'تقنية إدارة الوقت لتحسين التركيز والإنتاجية',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPomodoroButton(
                  context,
                  '25 دقيقة',
                  'جلسة قياسية',
                  Icons.play_arrow,
                  Colors.green,
                  () => _startPomodoroSession(context, 25),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPomodoroButton(
                  context,
                  '50 دقيقة',
                  'جلسة طويلة',
                  Icons.play_arrow,
                  Colors.orange,
                  () => _startPomodoroSession(context, 50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startPomodoroSession(BuildContext context, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بدأت جلسة البومودورو لمدة $minutes دقيقة'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'إلغاء',
          onPressed: () {
            // TODO: Cancel pomodoro session
          },
        ),
      ),
    );
    
    // TODO: Start actual pomodoro session
    // This would integrate with FocusSessionCubit
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsDrawer(BuildContext context, AppLocalizations localizations) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'الإعدادات السريعة',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Language
            BlocBuilder<LocaleCubit, LocaleState>(
              bloc: getIt<LocaleCubit>(),
              builder: (context, state) {
                final currentLocale =
                    state is LocaleLoaded ? state.locale.languageCode : 'en';
                final isArabic = currentLocale == 'ar';
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('اللغة'),
                  subtitle: Text(isArabic ? 'العربية' : 'English'),
                  onTap: () {
                    getIt<LocaleCubit>().toggleLocale();
                  },
                );
              },
            ),
            // Theme
            BlocBuilder<ThemeCubit, ThemeState>(
              bloc: getIt<ThemeCubit>(),
              builder: (context, state) {
                final isDarkMode = state is ThemeLoaded ? state.isDarkMode : false;
                return SwitchListTile(
                  secondary: const Icon(Icons.brightness_6),
                  title: const Text('الوضع الليلي'),
                  value: isDarkMode,
                  onChanged: (_) {
                    getIt<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
            const Divider(),
            // Block screen style
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('شكل شاشة الحظر'),
              subtitle: const Text('اختر الشكل الذي تريده عند حظر التطبيقات'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.blockScreenStyle);
              },
            ),
          ],
        ),
      ),
    );
  }
}
