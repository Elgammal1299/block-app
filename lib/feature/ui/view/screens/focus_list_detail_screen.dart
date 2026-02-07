import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../data/models/focus_list.dart';
import '../../../data/models/app_info.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../view_model/focus_session_cubit/focus_session_state.dart';
import '../../view_model/app_list_cubit/app_list_cubit.dart';
import '../../view_model/app_list_cubit/app_list_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/localization/app_localizations.dart';

class FocusListDetailScreen extends StatefulWidget {
  final FocusList focusList;

  const FocusListDetailScreen({
    super.key,
    required this.focusList,
  });

  @override
  State<FocusListDetailScreen> createState() => _FocusListDetailScreenState();
}

class _FocusListDetailScreenState extends State<FocusListDetailScreen> {
  int _selectedDuration = 30; // Default 30 minutes
  final List<int> _quickDurations = [15, 30, 60];

  @override
  void initState() {
    super.initState();
    // Load apps to get icons
    getIt<AppListCubit>().loadInstalledApps();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.focusList.name),
        actions: [
          if (!widget.focusList.isPreset)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${localizations.edit} functionality coming soon')),
                );
              },
            ),
        ],
      ),
      body: BlocListener<FocusSessionCubit, FocusSessionState>(
        listener: (context, state) {
          if (state is FocusSessionActive) {
            // Navigate to active session screen
            Navigator.pushNamed(context, AppRoutes.activeSession);
          } else if (state is FocusSessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blocked Apps Section
              _buildSection(
                title: localizations.blockedApps,
                icon: Icons.block,
                child: _buildAppsList(),
              ),

              const SizedBox(height: 24),

              // Duration Selection
              _buildSection(
                title: localizations.selectDuration,
                icon: Icons.timer,
                child: Column(
                  children: [
                    // Quick duration buttons
                    Row(
                      children: _quickDurations.map((duration) {
                        final isSelected = _selectedDuration == duration;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _DurationButton(
                              duration: duration,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedDuration = duration;
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Custom duration slider
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                localizations.customDuration,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '$_selectedDuration ${localizations.minutesShort}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _selectedDuration.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            label: '$_selectedDuration ${localizations.minutesShort}',
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value.toInt();
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '5 ${localizations.minutesShort}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '120 ${localizations.minutesShort}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<FocusSessionCubit, FocusSessionState>(
                  bloc: getIt<FocusSessionCubit>(),
                  builder: (context, state) {
                    final isLoading = state is FocusSessionLoading;
                    final isActive = state is FocusSessionActive;

                    return ElevatedButton(
                      onPressed: isLoading || isActive
                          ? null
                          : () => _startSession(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow),
                                const SizedBox(width: 8),
                                Text(
                                  localizations.startFocusSession,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAppsList() {
    final localizations = AppLocalizations.of(context);

    if (widget.focusList.packageNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(localizations.noAppsSelected),
        ),
      );
    }

    return BlocBuilder<AppListCubit, AppListState>(
      bloc: getIt<AppListCubit>(),
      builder: (context, state) {
        Map<String, AppInfo> appsMap = {};

        if (state is AppListLoaded) {
          appsMap = {for (var app in state.apps) app.packageName: app};
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.focusList.packageNames.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final packageName = widget.focusList.packageNames[index];
              final app = appsMap[packageName];

              return ListTile(
                dense: true,
                leading: app?.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          app!.icon!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.android, size: 20),
                title: Text(
                  app?.appName ?? _getAppName(packageName),
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  packageName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getAppName(String packageName) {
    // Extract app name from package name
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }

  Future<void> _startSession(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final success = await getIt<FocusSessionCubit>().startSession(
          widget.focusList.id,
          _selectedDuration,
        );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _DurationButton extends StatelessWidget {
  final int duration;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$duration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.primaryColor,
              ),
            ),
            Text(
              AppLocalizations.of(context).minutesShort,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : theme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
