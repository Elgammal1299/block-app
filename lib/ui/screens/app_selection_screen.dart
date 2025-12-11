import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../DI/setup_get_it.dart';
import '../../presentation/cubit/app_list/app_list_cubit.dart';
import '../../presentation/cubit/app_list/app_list_state.dart';
import '../../presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import '../../presentation/cubit/blocked_apps/blocked_apps_state.dart';
import '../../data/models/app_info.dart';
import '../../data/models/blocked_app.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  final Set<String> _selectedPackages = {};

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final appListCubit = getIt<AppListCubit>();
    final blockedAppsCubit = getIt<BlockedAppsCubit>();

    // Start loading apps (don't await - let it load in background)
    // This allows the CircularProgressIndicator to animate smoothly
    appListCubit.loadInstalledApps();

    // Load currently blocked apps and add to selection
    await blockedAppsCubit.loadBlockedApps();

    if (mounted) {
      final blockedAppsState = blockedAppsCubit.state;
      if (blockedAppsState is BlockedAppsLoaded) {
        setState(() {
          _selectedPackages.addAll(
            blockedAppsState.blockedApps.map((app) => app.packageName),
          );
        });
      }
    }
  }

  Future<void> _saveSelection() async {
    final appListCubit = getIt<AppListCubit>();
    final appListState = appListCubit.state;

    // Create BlockedApp objects for selected packages
    final blockedApps = _selectedPackages.map((packageName) {
      List<AppInfo> apps = [];
      if (appListState is AppListLoaded) {
        apps = appListState.apps;
      }

      final appInfo = apps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      return BlockedApp(
        packageName: packageName,
        appName: appInfo.appName,
        isBlocked: true,
        blockAttempts: 0,
        scheduleIds: [], // Will be set in next screen
      );
    }).toList();

    // Navigate to schedule selection screen
    if (mounted) {
      Navigator.of(context).pushNamed(
        '/app-schedule-selection',
        arguments: blockedApps,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
        actions: [
          if (_selectedPackages.isNotEmpty)
            TextButton(
              onPressed: _saveSelection,
              child: Text(
                'Save (${_selectedPackages.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: BlocBuilder<AppListCubit, AppListState>(
        bloc: getIt<AppListCubit>(),
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    getIt<AppListCubit>().setSearchQuery(value);
                  },
                ),
              ),

              // Show System Apps Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('Show system apps'),
                    const Spacer(),
                    Switch(
                      value: state is AppListLoaded ? state.showSystemApps : false,
                      onChanged: (value) {
                        getIt<AppListCubit>().toggleShowSystemApps();
                      },
                    ),
                  ],
                ),
              ),

              // Selected Count
              if (_selectedPackages.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedPackages.length} apps selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),

              // Apps List
              Expanded(
                child: state is AppListLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is AppListLoaded
                        ? state.apps.isEmpty
                            ? const Center(
                                child: Text('No apps found'),
                              )
                            : ListView.builder(
                                itemCount: state.apps.length,
                                itemBuilder: (context, index) {
                                  final app = state.apps[index];
                                  final isSelected =
                                      _selectedPackages.contains(app.packageName);

                                  return _buildAppItem(app, isSelected);
                                },
                              )
                        : state is AppListError
                            ? Center(
                                child: Text('Error: ${state.message}'),
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedPackages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveSelection,
              icon: const Icon(Icons.check),
              label: Text('Block ${_selectedPackages.length} Apps'),
            )
          : null,
    );
  }

  Widget _buildAppItem(AppInfo app, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedPackages.add(app.packageName);
            } else {
              _selectedPackages.remove(app.packageName);
            }
          });
        },
        title: Text(
          app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          app.packageName,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        secondary: app.icon != null && app.icon!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  app.icon!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.apps, size: 48);
                  },
                ),
              )
            : const Icon(Icons.apps, size: 48),
      ),
    );
  }
}
