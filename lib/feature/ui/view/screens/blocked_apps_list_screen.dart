import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../view_model/app_list_cubit/app_list_cubit.dart';
import '../../view_model/app_list_cubit/app_list_state.dart';
import '../../../data/models/blocked_app.dart';
import '../../../data/models/app_info.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../feature/data/repositories/settings_repository.dart';
import '../widgets/blocked_app_card.dart';
import '../widgets/empty_blocked_apps_message.dart';
import '../widgets/loading_message.dart';
import '../widgets/error_message.dart';
import '../widgets/unlock_challenge_dialog.dart';

class BlockedAppsListScreen extends StatefulWidget {
  const BlockedAppsListScreen({super.key});

  @override
  State<BlockedAppsListScreen> createState() => _BlockedAppsListScreenState();
}

class _BlockedAppsListScreenState extends State<BlockedAppsListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure apps are loaded
    getIt<AppListCubit>().loadInstalledApps();
  }

  void _showRemoveDialog(BlockedApp app) {
    final localizations = AppLocalizations.of(context);
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.confirm,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('unblock_app_confirm').replaceAll('{appName}', app.appName),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.unblockAppInfo,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // 1. Get current challenge type
              final challengeType = await getIt<SettingsRepository>()
                  .getUnlockChallengeType();

              // 2. Show challenge if enabled
              bool shouldProceed = true;
              if (challengeType != AppConstants.challengeNone && mounted) {
                shouldProceed =
                    await showDialog<bool>(
                      context: currentContext,
                      barrierDismissible: false,
                      builder: (context) =>
                          UnlockChallengeDialog(challengeType: challengeType),
                    ) ??
                    false;
              }

              // 3. Delete if challenge passed
              if (shouldProceed) {
                await getIt<BlockedAppsCubit>().removeBlockedApp(
                  app.packageName,
                );
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.translate('app_unblocked').replaceAll('{appName}', app.appName),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.unblock),
          ),
        ],
      ),
    );
  }

  void _showRemoveAllDialog(List<BlockedApp> apps) {
    final localizations = AppLocalizations.of(context);
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.confirm,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('unblock_all_confirm').replaceAll('{count}', apps.length.toString()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.unblockAllInfo,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // 1. Get current challenge type
              final challengeType = await getIt<SettingsRepository>()
                  .getUnlockChallengeType();

              // 2. Show challenge if enabled
              bool shouldProceed = true;
              if (challengeType != AppConstants.challengeNone && mounted) {
                shouldProceed =
                    await showDialog<bool>(
                      context: currentContext,
                      barrierDismissible: false,
                      builder: (context) =>
                          UnlockChallengeDialog(challengeType: challengeType),
                    ) ??
                    false;
              }

              // 3. Delete all if challenge passed
              if (shouldProceed) {
                for (var app in apps) {
                  await getIt<BlockedAppsCubit>().removeBlockedApp(
                    app.packageName,
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.translate('all_apps_unblocked').replaceAll('{count}', apps.length.toString()),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.unblockAll),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.blockedApps),
        elevation: 0,
        actions: [
          BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
            bloc: getIt<BlockedAppsCubit>(),
            builder: (context, state) {
              if (state is BlockedAppsLoaded && state.blockedApps.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: localizations.unblockAll,
                  onPressed: () => _showRemoveAllDialog(state.blockedApps),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: localizations.searchApps,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Apps List
          Expanded(
            child: BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
              bloc: getIt<BlockedAppsCubit>(),
              builder: (context, blockedAppsState) {
                if (blockedAppsState is BlockedAppsLoading) {
                  return Center(child: LoadingMessage());
                }

                if (blockedAppsState is BlockedAppsError) {
                  return Center(child: ErrorMessage(message: blockedAppsState.message));
                }

                if (blockedAppsState is BlockedAppsLoaded) {
                  final blockedApps = blockedAppsState.blockedApps
                      .where(
                        (app) =>
                            _searchQuery.isEmpty ||
                            app.appName.toLowerCase().contains(_searchQuery) ||
                            app.packageName.toLowerCase().contains(
                              _searchQuery,
                            ),
                      )
                      .toList();

                  if (blockedApps.isEmpty) {
                    return Center(
                      child: EmptyBlockedAppsMessage(
                        isSearch: _searchQuery.isNotEmpty,
                        onAddApps: _searchQuery.isEmpty
                            ? () => Navigator.pushNamed(context, '/app-selection')
                            : null,
                      ),
                    );
                  }

                  return BlocBuilder<AppListCubit, AppListState>(
                    bloc: getIt<AppListCubit>(),
                    builder: (context, appListState) {
                      final allApps = appListState is AppListLoaded
                          ? appListState.apps
                          : <AppInfo>[];

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: blockedApps.length,
                        itemBuilder: (context, index) {
                          final blockedApp = blockedApps[index];
                          final appInfo = allApps.firstWhere(
                            (app) => app.packageName == blockedApp.packageName,
                            orElse: () => AppInfo(
                              packageName: blockedApp.packageName,
                              appName: blockedApp.appName,
                            ),
                          );
                          return BlockedAppCard(
                            blockedApp: blockedApp,
                            appInfo: appInfo,
                            theme: theme,
                            onRemove: () => _showRemoveDialog(blockedApp),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...
}
