import 'package:flutter/material.dart';
import 'package:block_app/router/app_routes.dart';
import 'package:block_app/router/router_transitions.dart';
import 'package:block_app/ui/screens/permissions_guide_screen.dart';
import 'package:block_app/ui/screens/home_screen.dart';
import 'package:block_app/ui/screens/app_selection_screen.dart';
import 'package:block_app/ui/screens/schedule_screen.dart';
import 'package:block_app/ui/screens/app_schedule_selection_screen.dart';
import 'package:block_app/ui/screens/blocked_apps_list_screen.dart';
import 'package:block_app/ui/screens/usage_limit_selection_screen.dart';
import 'package:block_app/ui/screens/focus_lists_screen.dart';
import 'package:block_app/ui/screens/focus_list_detail_screen.dart';
import 'package:block_app/ui/screens/create_focus_list_screen.dart';
import 'package:block_app/ui/screens/active_session_screen.dart';
import 'package:block_app/ui/screens/focus_history_screen.dart';
import 'package:block_app/ui/screens/statistics_dashboard_screen.dart';
import 'package:block_app/data/models/blocked_app.dart';
import 'package:block_app/data/models/focus_list.dart';

class AppRouter {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Main routes
      case AppRoutes.permissions:
        return RouterTransitions.build(
          const PermissionsGuideScreen(),
          settings: settings,
        );

      case AppRoutes.home:
        return RouterTransitions.buildFade(const HomeScreen());

      // App management routes
      case AppRoutes.appSelection:
        return RouterTransitions.buildHorizontal(const AppSelectionScreen());

      case AppRoutes.appScheduleSelection:
        final apps = settings.arguments as List<BlockedApp>;
        return RouterTransitions.buildHorizontal(
          AppScheduleSelectionScreen(selectedApps: apps),
        );

      case AppRoutes.blockedAppsList:
        return RouterTransitions.buildHorizontal(const BlockedAppsListScreen());

      case AppRoutes.usageLimitSelection:
        return RouterTransitions.buildHorizontal(const UsageLimitSelectionScreen());

      // Schedule routes
      case AppRoutes.schedules:
        return RouterTransitions.buildHorizontal(const ScheduleScreen());

      // Focus session routes
      case AppRoutes.focusLists:
        return RouterTransitions.buildHorizontal(const FocusListsScreen());

      case AppRoutes.focusListDetail:
        final focusList = settings.arguments as FocusList;
        return RouterTransitions.buildHorizontal(
          FocusListDetailScreen(focusList: focusList),
        );

      case AppRoutes.createFocusList:
        return RouterTransitions.buildVertical(const CreateFocusListScreen());

      case AppRoutes.activeSession:
        return RouterTransitions.buildFade(const ActiveSessionScreen());

      case AppRoutes.focusHistory:
        // Note: This route requires repositories to be passed as arguments
        final args = settings.arguments as Map<String, dynamic>?;
        return RouterTransitions.buildHorizontal(
          Builder(
            builder: (context) => FocusHistoryScreen(
              focusRepository: args?['focusRepository'],
              settingsRepository: args?['settingsRepository'],
            ),
          ),
        );

      // Statistics routes
      case AppRoutes.statisticsDashboard:
        return RouterTransitions.buildHorizontal(const StatisticsDashboardScreen());

      default:
        return null;
    }
  }
}
