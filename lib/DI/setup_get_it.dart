import 'package:get_it/get_it.dart';
import 'package:block_app/data/local/shared_prefs_service.dart';
import 'package:block_app/data/local/database_service.dart';
import 'package:block_app/services/platform_channel_service.dart';
import 'package:block_app/data/repositories/app_repository.dart';
import 'package:block_app/data/repositories/settings_repository.dart';
import 'package:block_app/data/repositories/focus_repository.dart';
import 'package:block_app/data/repositories/statistics_repository.dart';
import 'package:block_app/presentation/cubit/theme/theme_cubit.dart';
import 'package:block_app/presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import 'package:block_app/presentation/cubit/app_list/app_list_cubit.dart';
import 'package:block_app/presentation/cubit/schedule/schedule_cubit.dart';
import 'package:block_app/presentation/cubit/statistics/statistics_cubit.dart';
import 'package:block_app/presentation/cubit/locale/locale_cubit.dart';
import 'package:block_app/presentation/cubit/focus_list/focus_list_cubit.dart';
import 'package:block_app/presentation/cubit/focus_session/focus_session_cubit.dart';
import 'package:block_app/presentation/cubit/usage_limit/usage_limit_cubit.dart';

/// Global GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Setup all dependencies for the app
/// Call this function in main() before runApp()
Future<void> setupGetIt() async {
  // ==================== Services - Singleton ====================
  // Services are shared across the app and initialized once

  final prefsService = await SharedPrefsService.getInstance();
  getIt.registerSingleton<SharedPrefsService>(prefsService);

  final platformService = PlatformChannelService();
  platformService.initialize();
  getIt.registerSingleton<PlatformChannelService>(platformService);

  // ==================== Repositories - Singleton ====================
  // Repositories manage data and business logic

  getIt.registerSingleton<AppRepository>(
    AppRepository(
      getIt<SharedPrefsService>(),
      getIt<PlatformChannelService>(),
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

  // ==================== Cubits - Singleton ====================
  // All Cubits are Singletons to maintain consistent state across screens
  // This is required when using bloc parameter with BlocBuilder

  getIt.registerSingleton<ThemeCubit>(
    ThemeCubit(getIt<SettingsRepository>()),
  );

  getIt.registerSingleton<BlockedAppsCubit>(
    BlockedAppsCubit(getIt<AppRepository>()),
  );

  getIt.registerSingleton<AppListCubit>(
    AppListCubit(getIt<AppRepository>()),
  );

  getIt.registerSingleton<ScheduleCubit>(
    ScheduleCubit(getIt<SettingsRepository>()),
  );

  getIt.registerSingleton<StatisticsCubit>(
    StatisticsCubit(getIt<StatisticsRepository>()),
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
    FocusSessionCubit(
      getIt<FocusRepository>(),
      getIt<SettingsRepository>(),
    ),
  );
}
