import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/local/shared_prefs_service.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/platform_channel_service.dart';
import 'providers/theme_provider.dart';
import 'providers/blocked_apps_provider.dart';
import 'providers/app_list_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/statistics_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/permissions_guide_screen.dart';
import 'ui/screens/app_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefsService = await SharedPrefsService.getInstance();
  final platformService = PlatformChannelService();
  platformService.initialize();

  // Initialize repositories
  final appRepository = AppRepository(prefsService, platformService);
  final settingsRepository = SettingsRepository(prefsService, platformService);

  runApp(MyApp(
    appRepository: appRepository,
    settingsRepository: settingsRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AppRepository appRepository;
  final SettingsRepository settingsRepository;

  const MyApp({
    super.key,
    required this.appRepository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(settingsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BlockedAppsProvider(appRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AppListProvider(appRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(settingsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(appRepository),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'App Blocker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/permissions',
            routes: {
              '/permissions': (context) => const PermissionsGuideScreen(),
              '/home': (context) => const HomeScreen(),
              '/app-selection': (context) => const AppSelectionScreen(),
            },
          );
        },
      ),
    );
  }
}
