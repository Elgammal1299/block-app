import 'package:get_it/get_it.dart';
import 'package:app_block/feature/data/local/shared_prefs_service.dart';
import 'package:app_block/feature/data/local/database_service.dart';
import 'package:app_block/core/services/platform_channel_service.dart';
import 'package:app_block/core/services/cached_prefs_service.dart';
import 'package:app_block/feature/data/repositories/app_repository.dart';
import 'package:app_block/feature/data/repositories/settings_repository.dart';
import 'package:app_block/feature/data/repositories/focus_repository.dart';
import 'package:app_block/feature/data/repositories/statistics_repository.dart';
import 'package:app_block/feature/data/repositories/daily_goal_repository.dart';
import 'package:app_block/feature/data/repositories/gamification_repository.dart';
import 'package:app_block/feature/data/repositories/suggestions_repository.dart';
import 'package:app_block/feature/data/repositories/focus_mode_config_repository.dart';
import 'package:app_block/feature/data/repositories/custom_focus_mode_repository.dart';
import 'package:app_block/feature/ui/view_model/theme_cubit/theme_cubit.dart';
import 'package:app_block/feature/ui/view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import 'package:app_block/feature/ui/view_model/app_list_cubit/app_list_cubit.dart';
import 'package:app_block/feature/ui/view_model/schedule_cubit/schedule_cubit.dart';
import 'package:app_block/feature/ui/view_model/statistics_cubit/statistics_cubit.dart';
import 'package:app_block/feature/ui/view_model/locale_cubit/locale_cubit.dart';
import 'package:app_block/feature/ui/view_model/focus_list_cubit/focus_list_cubit.dart';
import 'package:app_block/feature/ui/view_model/focus_session_cubit/focus_session_cubit.dart';
import 'package:app_block/feature/ui/view_model/usage_limit_cubit/usage_limit_cubit.dart';
import 'package:app_block/feature/ui/view_model/daily_goal_cubit/daily_goal_cubit.dart';
import 'package:app_block/feature/ui/view_model/gamification_cubit/gamification_cubit.dart';
import 'package:app_block/feature/ui/view_model/suggestions_cubit/suggestions_cubit.dart';
import 'package:app_block/feature/ui/view_model/focus_mode_config_cubit/focus_mode_config_cubit.dart';
import 'package:app_block/feature/ui/view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';

/// Global GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Setup all dependencies for the app
/// Call this function in main() before runApp()
Future<void> setupGetIt() async {
  // ==================== Services - Singleton ====================
  // Services are shared across the app and initialized once

  final prefsService = await SharedPrefsService.getInstance();
  getIt.registerSingleton<SharedPrefsService>(prefsService);

  // Cached Preferences Service (wraps SharedPrefsService with in-memory caching)
  // This eliminates repeated JSON decoding and reduces I/O
  getIt.registerSingleton<CachedPreferencesService>(
    CachedPreferencesService(getIt<SharedPrefsService>()),
  );

  final platformService = PlatformChannelService();
  platformService.initialize();
  getIt.registerSingleton<PlatformChannelService>(platformService);

  // ==================== Repositories - Singleton ====================
  // Repositories manage data and business logic

  getIt.registerSingleton<AppRepository>(
    AppRepository(
      getIt<SharedPrefsService>(),
      getIt<PlatformChannelService>(),
      getIt<CachedPreferencesService>(),
    ),
  );

  getIt.registerSingleton<SettingsRepository>(
    SettingsRepository(
      getIt<SharedPrefsService>(),
      getIt<PlatformChannelService>(),
    ),
  );

  getIt.registerSingleton<FocusRepository>(
    FocusRepository(
      getIt<SharedPrefsService>(),
      getIt<PlatformChannelService>(),
    ),
  );

  // Database Service
  final databaseService = DatabaseService();
  await databaseService.database; // Initialize database
  getIt.registerSingleton<DatabaseService>(databaseService);

  // Statistics Repository
  getIt.registerSingleton<StatisticsRepository>(
    StatisticsRepository(
      getIt<DatabaseService>(),
      getIt<AppRepository>(),
      getIt<PlatformChannelService>(),
    ),
  );

  // Daily Goal Repository
  getIt.registerSingleton<DailyGoalRepository>(
    DailyGoalRepository(getIt<SharedPrefsService>()),
  );

  // Gamification Repository
  getIt.registerSingleton<GamificationRepository>(
    GamificationRepository(getIt<SharedPrefsService>()),
  );

  // Suggestions Repository
  getIt.registerSingleton<SuggestionsRepository>(
    SuggestionsRepository(
      prefsService: getIt<SharedPrefsService>(),
      gamificationRepo: getIt<GamificationRepository>(),
      dailyGoalRepo: getIt<DailyGoalRepository>(),
    ),
  );

  // Focus Mode Config Repository
  getIt.registerSingleton<FocusModeConfigRepository>(
    FocusModeConfigRepository(
      getIt<SharedPrefsService>(),
      getIt<FocusRepository>(),
      getIt<PlatformChannelService>(),
    ),
  );

  // Custom Focus Mode Repository
  getIt.registerSingleton<CustomFocusModeRepository>(
    CustomFocusModeRepository(getIt<SharedPrefsService>()),
  );

  // ==================== Cubits - Singleton ====================
  // All Cubits are Singletons to maintain consistent state across screens
  // This is required when using bloc parameter with BlocBuilder

  getIt.registerSingleton<ThemeCubit>(ThemeCubit(getIt<SettingsRepository>()));

  getIt.registerSingleton<BlockedAppsCubit>(
    BlockedAppsCubit(getIt<AppRepository>()),
  );

  getIt.registerSingleton<AppListCubit>(AppListCubit(getIt<AppRepository>()));

  getIt.registerSingleton<ScheduleCubit>(
    ScheduleCubit(getIt<SettingsRepository>()),
  );

  getIt.registerSingleton<StatisticsCubit>(
    StatisticsCubit(
      getIt<StatisticsRepository>(),
      getIt<PlatformChannelService>(),
    ),
  );

  getIt.registerSingleton<LocaleCubit>(
    LocaleCubit(getIt<SettingsRepository>()),
  );

  getIt.registerSingleton<UsageLimitCubit>(
    UsageLimitCubit(getIt<AppRepository>()),
  );

  getIt.registerSingleton<FocusListCubit>(
    FocusListCubit(getIt<FocusRepository>()),
  );

  getIt.registerSingleton<FocusSessionCubit>(
    FocusSessionCubit(getIt<FocusRepository>(), getIt<SettingsRepository>()),
  );

  getIt.registerSingleton<DailyGoalCubit>(
    DailyGoalCubit(getIt<DailyGoalRepository>()),
  );

  getIt.registerSingleton<GamificationCubit>(
    GamificationCubit(getIt<GamificationRepository>()),
  );

  getIt.registerSingleton<SmartSuggestionsCubit>(
    SmartSuggestionsCubit(getIt<SuggestionsRepository>()),
  );

  getIt.registerSingleton<FocusModeConfigCubit>(
    FocusModeConfigCubit(getIt<FocusModeConfigRepository>()),
  );

  getIt.registerSingleton<CustomFocusModeCubit>(
    CustomFocusModeCubit(getIt<CustomFocusModeRepository>()),
  );
}
