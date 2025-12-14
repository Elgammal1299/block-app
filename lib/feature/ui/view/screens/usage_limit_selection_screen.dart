import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/app_list_cubit/app_list_cubit.dart';
import '../../view_model/app_list_cubit/app_list_state.dart';
import '../../view_model/usage_limit_cubit/usage_limit_cubit.dart';
import '../../view_model/usage_limit_cubit/usage_limit_state.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/app_usage_limit.dart';
import '../../../../core/localization/app_localizations.dart';

class UsageLimitSelectionScreen extends StatefulWidget {
  const UsageLimitSelectionScreen({super.key});

  @override
  State<UsageLimitSelectionScreen> createState() =>
      _UsageLimitSelectionScreenState();
}

class _UsageLimitSelectionScreenState
    extends State<UsageLimitSelectionScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    getIt<AppListCubit>().loadInstalledApps();
    getIt<UsageLimitCubit>().loadUsageLimits();
  }

  void _showLimitDialog(AppInfo app) {
    final usageLimitCubit = getIt<UsageLimitCubit>();
    final existingLimit = usageLimitCubit.getLimit(app.packageName);
    final currentLimit = existingLimit?.dailyLimitMinutes ?? 60;
    int selectedMinutes = currentLimit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                if (app.icon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      app.icon!,
                      width: 32,
                      height: 32,
                    ),
                  )
                else
                  const Icon(Icons.apps, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Set Daily Limit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display selected time
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppUsageLimit.formatMinutes(selectedMinutes),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Text(
                          'per day',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick presets
                  const Text(
                    'Quick Presets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(15, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                      _buildPresetChip(30, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                      _buildPresetChip(60, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                      _buildPresetChip(90, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                      _buildPresetChip(120, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                      _buildPresetChip(180, selectedMinutes, setDialogState,
                          (val) => selectedMinutes = val),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Custom slider
                  const Text(
                    'Custom Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 5,
                    max: 480, // 8 hours
                    divisions: 95,
                    label: AppUsageLimit.formatMinutes(selectedMinutes),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMinutes = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newLimit = AppUsageLimit(
                    packageName: app.packageName,
                    appName: app.appName,
                    dailyLimitMinutes: selectedMinutes,
                    usedMinutesToday: existingLimit?.usedMinutesToday ?? 0,
                    lastResetDate: existingLimit?.lastResetDate ?? DateTime.now(),
                    isEnabled: true,
                  );

                  await usageLimitCubit.setUsageLimit(newLimit);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Limit set for ${app.appName}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Set Limit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(int minutes, int selectedMinutes,
      StateSetter setDialogState, Function(int) onSelected) {
    final isSelected = selectedMinutes == minutes;
    return ChoiceChip(
      label: Text(AppUsageLimit.formatMinutes(minutes)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setDialogState(() {
            onSelected(minutes);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Set Daily Usage Limits'),
        elevation: 0,
        actions: [
          BlocBuilder<UsageLimitCubit, UsageLimitState>(
            bloc: getIt<UsageLimitCubit>(),
            builder: (context, state) {
              if (state is UsageLimitLoaded && state.limits.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '${state.limits.length} set',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: theme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Control Your Screen Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set daily time limits for apps. Once the limit is reached, the app will be blocked for the rest of the day.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Apps List
          Expanded(
            child: BlocBuilder<AppListCubit, AppListState>(
              bloc: getIt<AppListCubit>(),
              builder: (context, state) {
                if (state is AppListLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          localizations.loadingApps,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AppListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
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
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AppListLoaded) {
                  final apps = state.apps
                      .where((app) =>
                          _searchQuery.isEmpty ||
                          app.appName.toLowerCase().contains(_searchQuery) ||
                          app.packageName.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: theme.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.noAppsFound,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return BlocBuilder<UsageLimitCubit, UsageLimitState>(
                    bloc: getIt<UsageLimitCubit>(),
                    builder: (context, limitState) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          final usageLimit = limitState is UsageLimitLoaded
                              ? limitState.limits.firstWhere(
                                  (l) => l.packageName == app.packageName,
                                  orElse: () => AppUsageLimit(
                                    packageName: '',
                                    appName: '',
                                    dailyLimitMinutes: 0,
                                  ),
                                )
                              : null;

                          final isSelected = usageLimit != null &&
                                            usageLimit.packageName.isNotEmpty;
                          final limitMinutes = usageLimit?.dailyLimitMinutes ?? 60;

                          return _buildAppCard(
                              app, isSelected, limitMinutes, theme);
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
      bottomNavigationBar: BlocBuilder<UsageLimitCubit, UsageLimitState>(
        bloc: getIt<UsageLimitCubit>(),
        builder: (context, state) {
          if (state is UsageLimitLoaded && state.limits.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Done (${state.limits.length} app${state.limits.length > 1 ? 's' : ''})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAppCard(
      AppInfo app, bool isSelected, int limitMinutes, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLimitDialog(app),
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
                child: app.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          app.icon!,
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
                      app.appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${AppUsageLimit.formatMinutes(limitMinutes)} daily limit',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Tap to set limit',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),

              // Action Button
              if (isSelected)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showLimitDialog(app),
                      icon: const Icon(Icons.edit_outlined),
                      color: theme.primaryColor,
                      tooltip: 'Edit Limit',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Limit'),
                            content: Text(
                              'Remove the daily limit for ${app.appName}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          await getIt<UsageLimitCubit>()
                              .removeUsageLimit(app.packageName);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Limit removed for ${app.appName}'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.red[400],
                      tooltip: 'Remove',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () => _showLimitDialog(app),
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.primaryColor,
                  tooltip: 'Add Limit',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
