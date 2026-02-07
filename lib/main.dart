import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_block/core/router/app_routes.dart';
import 'package:app_block/core/router/route.dart';
import 'package:app_block/core/DI/setup_get_it.dart';
import 'package:app_block/core/theme/app_theme.dart';
import 'package:app_block/core/localization/app_localizations.dart';
import 'package:app_block/core/services/platform_channel_service.dart';
import 'package:app_block/core/utils/app_startup_optimizer.dart';
import 'package:app_block/core/utils/memory_pressure_listener.dart';
import 'package:app_block/feature/ui/view_model/theme_cubit/theme_cubit.dart';
import 'package:app_block/feature/ui/view_model/theme_cubit/theme_state.dart';
import 'package:app_block/feature/ui/view_model/locale_cubit/locale_cubit.dart';
import 'package:app_block/feature/ui/view_model/locale_cubit/locale_state.dart';
import 'package:app_block/feature/ui/view_model/app_list_cubit/app_list_cubit.dart';
import 'package:app_block/feature/data/repositories/focus_mode_config_repository.dart';
import 'package:app_block/feature/ui/view_model/focus_mode_config_cubit/focus_mode_config_cubit.dart';
import 'package:app_block/core/utils/app_logger.dart';
import 'package:app_block/feature/ui/view/screens/critical_error_screen.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Setup Logging & Error Handlers
      FlutterError.onError = (details) {
        AppLogger.e(
          'Flutter Framework Error',
          details.exception,
          details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.e('Platform Async Error', error, stack);
        return true;
      };

      bool setupSuccess = false;
      String errorMessage = '';

      try {
        // 2. Setup dependency injection
        await setupGetIt();

        // 3. Initialize core features
        await _initializeFocusModePresets();

        // Phase 3.5: Run startup optimizer (essential data + icon preload)
        // IMPORTANT: Ensure platform channels are ready before icon preload
        await AppStartupOptimizer().optimizeStartup();

        // Phase 3.5+: Start memory pressure listener
        // IMPORTANT: Only start after Flutter engine is fully initialized
        unawaited(MemoryPressureListener().startListening());

        // Pre-load apps (non-blocking but logged)
        unawaited(_preloadApps());

        setupSuccess = true;
      } catch (e, stack) {
        AppLogger.e('Critical Setup Failure', e, stack);
        errorMessage = e.toString();
      }

      if (!setupSuccess) {
        runApp(
          CriticalErrorScreen(
            message: 'حدث خطأ أثناء تهيئة التطبيق: $errorMessage',
            onRetry: () => main(),
          ),
        );
        return;
      }

      // 4. Permission Check & Initial Route
      final platformService = getIt<PlatformChannelService>();
      final hasUsageStats = await platformService.checkUsageStatsPermission();
      final hasOverlay = await platformService.checkOverlayPermission();
      final hasAccessibility = await platformService
          .checkAccessibilityPermission();
      final allPermissionsGranted =
          hasUsageStats && hasOverlay && hasAccessibility;

      // Start services automatically if permissions are granted
      if (allPermissionsGranted) {
        _startServicesInBackground();
      }

      runApp(
        MyApp(
          initialRoute: allPermissionsGranted
              ? AppRoutes.home
              : AppRoutes.permissions,
        ),
      );
    },
    (error, stack) {
      AppLogger.e('Global Uncaught Exception', error, stack);
    },
  );
}

/// Pre-load apps in background to make them ready when needed
Future<void> _preloadApps() async {
  try {
    final appListCubit = getIt<AppListCubit>();
    await appListCubit.loadInstalledApps();
    AppLogger.i('Apps pre-loaded successfully');
  } catch (e, stack) {
    AppLogger.e('Silent failure during app pre-loading', e, stack);
  }
}

/// Start monitoring and tracking services in background
Future<void> _startServicesInBackground() async {
  try {
    final platformService = getIt<PlatformChannelService>();

    // Start both services
    await platformService.startMonitoringService();
    await platformService.startUsageTrackingService();

    AppLogger.i('Services started automatically in background');
  } catch (e, stack) {
    AppLogger.e('Error starting services in background', e, stack);
  }
}

/// Initialize focus mode presets correctly
Future<void> _initializeFocusModePresets() async {
  try {
    final configRepo = getIt<FocusModeConfigRepository>();
    final configCubit = getIt<FocusModeConfigCubit>();

    // Check if already initialized
    final initialized = await configRepo.arePresetsInitialized();

    if (!initialized) {
      AppLogger.i('Initializing focus mode presets...');
      await configRepo.initializePresets();
    }

    // Load configs into cubit
    await configCubit.loadConfigs();
  } catch (e, stack) {
    AppLogger.e('Error initializing focus mode presets', e, stack);
    rethrow; // Rethrow to let setupSuccess handle it
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = AppRoutes.permissions});

  @override
  Widget build(BuildContext context) {
    final themeCubit = getIt<ThemeCubit>();
    final localeCubit = getIt<LocaleCubit>();

    return BlocBuilder<LocaleCubit, LocaleState>(
      bloc: localeCubit,
      builder: (context, localeState) {
        final locale = localeState is LocaleLoaded ? localeState.locale : null;

        return BlocBuilder<ThemeCubit, ThemeState>(
          bloc: themeCubit,
          builder: (context, themeState) {
            final isDarkMode = themeState is ThemeLoaded
                ? themeState.isDarkMode
                : false;

            return MaterialApp(
              title: 'App Blocker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              initialRoute: initialRoute,
              onGenerateRoute: AppRouter.generateRoute,
            );
          },
        );
      },
    );
  }
}
