import 'package:get_it/get_it.dart';
import 'package:block_app/data/local/shared_prefs_service.dart';
import 'package:block_app/services/platform_channel_service.dart';
import 'package:block_app/data/repositories/app_repository.dart';
import 'package:block_app/data/repositories/settings_repository.dart';
import 'package:block_app/data/repositories/focus_repository.dart';
import 'package:block_app/presentation/cubit/theme/theme_cubit.dart';
import 'package:block_app/presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import 'package:block_app/presentation/cubit/app_list/app_list_cubit.dart';
import 'package:block_app/presentation/cubit/schedule/schedule_cubit.dart';
import 'package:block_app/presentation/cubit/statistics/statistics_cubit.dart';
import 'package:block_app/presentation/cubit/locale/locale_cubit.dart';
import 'package:block_app/presentation/cubit/focus_list/focus_list_cubit.dart';
import 'package:block_app/presentation/cubit/focus_session/focus_session_cubit.dart';

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

  // ==================== Cubits - Factory ====================
  // Cubits are created fresh each time they are requested
  // This ensures proper state management and prevents memory leaks

  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(getIt<SettingsRepository>()),
  );

  getIt.registerFactory<BlockedAppsCubit>(
    () => BlockedAppsCubit(getIt<AppRepository>()),
  );

  getIt.registerFactory<AppListCubit>(
    () => AppListCubit(getIt<AppRepository>()),
  );

  getIt.registerFactory<ScheduleCubit>(
    () => ScheduleCubit(getIt<SettingsRepository>()),
  );

  getIt.registerFactory<StatisticsCubit>(
    () => StatisticsCubit(getIt<AppRepository>()),
  );

  getIt.registerFactory<LocaleCubit>(
    () => LocaleCubit(getIt<SettingsRepository>()),
  );

  getIt.registerFactory<FocusListCubit>(
    () => FocusListCubit(getIt<FocusRepository>()),
  );

  getIt.registerFactory<FocusSessionCubit>(
    () => FocusSessionCubit(
      getIt<FocusRepository>(),
      getIt<SettingsRepository>(),
    ),
  );
}
