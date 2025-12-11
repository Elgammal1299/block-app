import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:block_app/router/app_routes.dart';
import 'package:block_app/router/route.dart';
import 'package:block_app/DI/setup_get_it.dart';
import 'package:block_app/core/theme/app_theme.dart';
import 'package:block_app/core/localization/app_localizations.dart';
import 'package:block_app/services/platform_channel_service.dart';
import 'package:block_app/presentation/cubit/theme/theme_cubit.dart';
import 'package:block_app/presentation/cubit/theme/theme_state.dart';
import 'package:block_app/presentation/cubit/locale/locale_cubit.dart';
import 'package:block_app/presentation/cubit/locale/locale_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupGetIt();

  // Check if all permissions are granted
  final platformService = getIt<PlatformChannelService>();
  final hasUsageStats = await platformService.checkUsageStatsPermission();
  final hasOverlay = await platformService.checkOverlayPermission();
  final hasAccessibility = await platformService.checkAccessibilityPermission();
  final allPermissionsGranted = hasUsageStats && hasOverlay && hasAccessibility;

  runApp(MyApp(
    initialRoute: allPermissionsGranted ? AppRoutes.home : AppRoutes.permissions,
  ));
}

/// Root widget - Clean and simple
/// All state management is handled through GetIt dependency injection
class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    this.initialRoute = AppRoutes.permissions,
  });

  @override
  Widget build(BuildContext context) {
    // Get Cubits from GetIt
    final themeCubit = getIt<ThemeCubit>();
    final localeCubit = getIt<LocaleCubit>();

    return BlocBuilder<LocaleCubit, LocaleState>(
      bloc: localeCubit,
      builder: (context, localeState) {
        final locale = localeState is LocaleLoaded ? localeState.locale : null;

        return BlocBuilder<ThemeCubit, ThemeState>(
          bloc: themeCubit,
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
              onGenerateRoute: AppRouter.generateRoute,
            );
          },
        );
      },
    );
  }
}
