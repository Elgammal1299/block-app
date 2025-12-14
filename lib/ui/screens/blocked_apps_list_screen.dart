import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../DI/setup_get_it.dart';
import '../../presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import '../../presentation/cubit/blocked_apps/blocked_apps_state.dart';
import '../../presentation/cubit/app_list/app_list_cubit.dart';
import '../../presentation/cubit/app_list/app_list_state.dart';
import '../../data/models/blocked_app.dart';
import '../../data/models/app_info.dart';
import '../../core/localization/app_localizations.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
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
              'Are you sure you want to unblock "${app.appName}"?',
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This app will no longer be blocked and can be used freely.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await getIt<BlockedAppsCubit>().removeBlockedApp(app.packageName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${app.appName} has been unblocked'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showRemoveAllDialog(List<BlockedApp> apps) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              'Are you sure you want to unblock ALL ${apps.length} apps?',
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
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will remove all blocked apps and their schedules. This action cannot be undone.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Remove all apps
              for (var app in apps) {
                await getIt<BlockedAppsCubit>().removeBlockedApp(app.packageName);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All ${apps.length} apps have been unblocked'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock All'),
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
                  tooltip: 'Unblock All',
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
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Apps List
          Expanded(
            child: BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
              bloc: getIt<BlockedAppsCubit>(),
              builder: (context, blockedAppsState) {
                if (blockedAppsState is BlockedAppsLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          localizations.loading,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (blockedAppsState is BlockedAppsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          localizations.error,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          blockedAppsState.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (blockedAppsState is BlockedAppsLoaded) {
                  final blockedApps = blockedAppsState.blockedApps
                      .where((app) =>
                          _searchQuery.isEmpty ||
                          app.appName.toLowerCase().contains(_searchQuery) ||
                          app.packageName.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (blockedApps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.check_circle_outline : Icons.search_off,
                            size: 80,
                            color: theme.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No Blocked Apps'
                                : 'No apps found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'You haven\'t blocked any apps yet.\nTap the button below to add some.'
                                : 'Try searching with a different keyword',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/app-selection');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Block Apps'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
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

                          return _buildAppCard(blockedApp, appInfo, theme);
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

  Widget _buildAppCard(BlockedApp blockedApp, AppInfo appInfo, ThemeData theme) {
    final hasSchedules = blockedApp.scheduleIds.isNotEmpty;
    final scheduleText = hasSchedules
        ? '${blockedApp.scheduleIds.length} schedule(s)'
        : 'Always blocked (24/7)';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Could navigate to app details or edit screen
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // App Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: appInfo.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          appInfo.icon!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.apps,
                        size: 32,
                        color: theme.primaryColor,
                      ),
              ),
              const SizedBox(width: 16),

              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blockedApp.appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasSchedules ? Icons.schedule : Icons.block,
                          size: 14,
                          color: hasSchedules ? Colors.blue : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scheduleText,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasSchedules ? Colors.blue : Colors.red,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (blockedApp.blockAttempts > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.front_hand,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${blockedApp.blockAttempts} block attempts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Remove Button
              IconButton(
                onPressed: () => _showRemoveDialog(blockedApp),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                tooltip: 'Unblock',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
