import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/local/shared_prefs_service.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/platform_channel_service.dart';
import 'presentation/cubit/theme/theme_cubit.dart';
import 'presentation/cubit/theme/theme_state.dart';
import 'presentation/cubit/locale/locale_cubit.dart';
import 'presentation/cubit/locale/locale_state.dart';
import 'presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import 'presentation/cubit/app_list/app_list_cubit.dart';
import 'presentation/cubit/schedule/schedule_cubit.dart';
import 'presentation/cubit/statistics/statistics_cubit.dart';
import 'core/localization/app_localizations.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/permissions_guide_screen.dart';
import 'ui/screens/app_selection_screen.dart';
import 'ui/screens/schedule_screen.dart';
import 'ui/screens/app_schedule_selection_screen.dart';
import 'data/models/blocked_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefsService = await SharedPrefsService.getInstance();
  final platformService = PlatformChannelService();
  platformService.initialize();

  // Initialize repositories
  final appRepository = AppRepository(prefsService, platformService);
  final settingsRepository = SettingsRepository(prefsService, platformService);

  // Check if all permissions are granted
  final hasUsageStats = await platformService.checkUsageStatsPermission();
  final hasOverlay = await platformService.checkOverlayPermission();
  final hasAccessibility = await platformService.checkAccessibilityPermission();
  final allPermissionsGranted = hasUsageStats && hasOverlay && hasAccessibility;

  runApp(MyApp(
    appRepository: appRepository,
    settingsRepository: settingsRepository,
    initialRoute: allPermissionsGranted ? '/home' : '/permissions',
  ));
}

class MyApp extends StatelessWidget {
  final AppRepository appRepository;
  final SettingsRepository settingsRepository;
  final String initialRoute;

  const MyApp({
    super.key,
    required this.appRepository,
    required this.settingsRepository,
    this.initialRoute = '/permissions',
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Cubits
        BlocProvider(
          create: (_) => ThemeCubit(settingsRepository),
        ),
        BlocProvider(
          create: (_) => BlockedAppsCubit(appRepository),
        ),
        BlocProvider(
          create: (_) => AppListCubit(appRepository),
        ),
        BlocProvider(
          create: (_) => ScheduleCubit(settingsRepository),
        ),
        BlocProvider(
          create: (_) => StatisticsCubit(appRepository),
        ),
        BlocProvider(
          create: (_) => LocaleCubit(settingsRepository),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          final locale = localeState is LocaleLoaded ? localeState.locale : null;

          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final isDarkMode = themeState is ThemeLoaded ? themeState.isDarkMode : false;

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
                routes: {
                  '/permissions': (context) => const PermissionsGuideScreen(),
                  '/home': (context) => const HomeScreen(),
                  '/app-selection': (context) => const AppSelectionScreen(),
                  '/schedules': (context) => const ScheduleScreen(),
                },
                onGenerateRoute: (settings) {
                  if (settings.name == '/app-schedule-selection') {
                    final apps = settings.arguments as List<BlockedApp>;
                    return MaterialPageRoute(
                      builder: (context) => AppScheduleSelectionScreen(selectedApps: apps),
                    );
                  }
                  return null;
                },
              );
            },
          );
        },
      ),
    );
  }
}
