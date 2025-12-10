import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/cubit/schedule/schedule_cubit.dart';
import '../../presentation/cubit/schedule/schedule_state.dart';
import '../../presentation/cubit/blocked_apps/blocked_apps_cubit.dart';
import '../../data/models/blocked_app.dart';
import '../../data/models/schedule.dart';

enum BlockingMode {
  alwaysBlocked,    // حظر دائم
  useSchedules,     // استخدام جداول موجودة
  customSchedule,   // جدول مخصص
}

class AppScheduleSelectionScreen extends StatefulWidget {
  final List<BlockedApp> selectedApps;

  const AppScheduleSelectionScreen({
    super.key,
    required this.selectedApps,
  });

  @override
  State<AppScheduleSelectionScreen> createState() =>
      _AppScheduleSelectionScreenState();
}

class _AppScheduleSelectionScreenState
    extends State<AppScheduleSelectionScreen> {
  final Map<String, Set<String>> _appSchedules = {};
  final Map<String, BlockingMode> _appBlockingModes = {};
  final Map<String, Schedule?> _appCustomSchedules = {};

  @override
  void initState() {
    super.initState();
    // Initialize with existing schedules for each app
    for (var app in widget.selectedApps) {
      _appSchedules[app.packageName] = Set.from(app.scheduleIds);

      // Determine initial blocking mode
      if (app.scheduleIds.isEmpty) {
        _appBlockingModes[app.packageName] = BlockingMode.alwaysBlocked;
      } else {
        _appBlockingModes[app.packageName] = BlockingMode.useSchedules;
      }

      _appCustomSchedules[app.packageName] = null;
    }
  }

  void _toggleSchedule(String packageName, String scheduleId) {
    setState(() {
      if (_appSchedules[packageName]!.contains(scheduleId)) {
        _appSchedules[packageName]!.remove(scheduleId);
      } else {
        _appSchedules[packageName]!.add(scheduleId);
      }
    });
  }

  Future<void> _saveSelections() async {
    final blockedAppsCubit = context.read<BlockedAppsCubit>();
    final scheduleCubit = context.read<ScheduleCubit>();

    // Update each app with its selected schedules
    final updatedApps = <BlockedApp>[];

    for (var app in widget.selectedApps) {
      final mode = _appBlockingModes[app.packageName]!;
      List<String> scheduleIds = [];

      if (mode == BlockingMode.alwaysBlocked) {
        // No schedules - always blocked
        scheduleIds = [];
      } else if (mode == BlockingMode.useSchedules) {
        // Use existing schedules
        scheduleIds = _appSchedules[app.packageName]!.toList();
      } else if (mode == BlockingMode.customSchedule) {
        // Create and use custom schedule
        final customSchedule = _appCustomSchedules[app.packageName];
        if (customSchedule != null) {
          await scheduleCubit.addSchedule(customSchedule);
          scheduleIds = [customSchedule.id];
        }
      }

      updatedApps.add(app.copyWith(scheduleIds: scheduleIds));
    }

    await blockedAppsCubit.saveBlockedApps(updatedApps);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updatedApps.length} apps configured successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // Go back to home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Blocking Schedules'),
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.selectedApps.length,
            itemBuilder: (context, index) {
              final app = widget.selectedApps[index];
              return _buildAppScheduleCard(app, state);
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveSelections,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Save & Apply',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildAppScheduleCard(
      BlockedApp app, ScheduleState scheduleState) {
    final mode = _appBlockingModes[app.packageName] ?? BlockingMode.alwaysBlocked;
    final selectedSchedules = _appSchedules[app.packageName] ?? {};
    final customSchedule = _appCustomSchedules[app.packageName];

    // Get schedules from state
    final schedules = scheduleState is ScheduleLoaded ? scheduleState.schedules : <Schedule>[];

    String subtitle = '';
    Color subtitleColor = Colors.grey;

    switch (mode) {
      case BlockingMode.alwaysBlocked:
        subtitle = 'Always blocked (24/7)';
        subtitleColor = Colors.red;
        break;
      case BlockingMode.useSchedules:
        subtitle = selectedSchedules.isEmpty
            ? 'No schedules selected'
            : '${selectedSchedules.length} schedule(s) selected';
        subtitleColor = selectedSchedules.isEmpty ? Colors.orange : Colors.blue;
        break;
      case BlockingMode.customSchedule:
        subtitle = customSchedule != null
            ? 'Custom: ${_formatTime(customSchedule.startTime)} - ${_formatTime(customSchedule.endTime)}'
            : 'No custom schedule set';
        subtitleColor = customSchedule != null ? Colors.green : Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Choose blocking method:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),

          // Option 1: Always Blocked
          RadioListTile<BlockingMode>(
            title: const Text('Always Blocked (24/7)'),
            subtitle: const Text('Block this app at all times'),
            value: BlockingMode.alwaysBlocked,
            groupValue: mode,
            onChanged: (value) {
              setState(() {
                _appBlockingModes[app.packageName] = value!;
              });
            },
            secondary: const Icon(Icons.block, color: Colors.red),
          ),

          const Divider(height: 1),

          // Option 2: Use Existing Schedules
          RadioListTile<BlockingMode>(
            title: const Text('Use Existing Schedules'),
            subtitle: Text(
              schedules.isEmpty
                  ? 'No schedules available - create one first'
                  : 'Select from created schedules',
            ),
            value: BlockingMode.useSchedules,
            groupValue: mode,
            onChanged: schedules.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _appBlockingModes[app.packageName] = value!;
                    });
                  },
            secondary: Icon(
              Icons.list_alt,
              color: schedules.isEmpty ? Colors.grey : Colors.blue,
            ),
          ),

          // Show schedule list if this mode is selected
          if (mode == BlockingMode.useSchedules && schedules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                children: schedules.map((schedule) {
                  final isSelected = selectedSchedules.contains(schedule.id);
                  return CheckboxListTile(
                    title: Text(
                      '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _formatDays(schedule.daysOfWeek),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      _toggleSchedule(app.packageName, schedule.id);
                    },
                    dense: true,
                    secondary: Icon(
                      Icons.schedule,
                      size: 20,
                      color: schedule.isEnabled ? Colors.blue : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // Option 3: Create Custom Schedule
          RadioListTile<BlockingMode>(
            title: const Text('Create Custom Schedule'),
            subtitle: Text(
              customSchedule != null
                  ? '${_formatTime(customSchedule.startTime)} - ${_formatTime(customSchedule.endTime)} | ${_formatDays(customSchedule.daysOfWeek)}'
                  : 'Set specific time for this app only',
            ),
            value: BlockingMode.customSchedule,
            groupValue: mode,
            onChanged: (value) {
              setState(() {
                _appBlockingModes[app.packageName] = value!;
              });
            },
            secondary: const Icon(Icons.add_alarm, color: Colors.green),
          ),

          // Show custom schedule button if this mode is selected
          if (mode == BlockingMode.customSchedule)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showCustomScheduleDialog(app.packageName),
                icon: Icon(customSchedule != null ? Icons.edit : Icons.add),
                label: Text(customSchedule != null ? 'Edit Schedule' : 'Set Schedule'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showCustomScheduleDialog(String packageName) async {
    final currentSchedule = _appCustomSchedules[packageName];

    TimeOfDay startTime = currentSchedule?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = currentSchedule?.endTime ?? const TimeOfDay(hour: 17, minute: 0);
    Set<int> selectedDays = currentSchedule != null
        ? Set.from(currentSchedule.daysOfWeek)
        : {1, 2, 3, 4, 5}; // Default: weekdays

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Custom Schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time selection
                  const Text(
                    'Block Time:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Start time
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Start Time'),
                    subtitle: Text(_formatTime(startTime)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),

                  // End time
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('End Time'),
                    subtitle: Text(_formatTime(endTime)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endTime = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Days selection
                  const Text(
                    'Select Days:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDayChip('Mon', 1, selectedDays, setDialogState),
                      _buildDayChip('Tue', 2, selectedDays, setDialogState),
                      _buildDayChip('Wed', 3, selectedDays, setDialogState),
                      _buildDayChip('Thu', 4, selectedDays, setDialogState),
                      _buildDayChip('Fri', 5, selectedDays, setDialogState),
                      _buildDayChip('Sat', 6, selectedDays, setDialogState),
                      _buildDayChip('Sun', 7, selectedDays, setDialogState),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick presets
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedDays = {1, 2, 3, 4, 5};
                          });
                        },
                        child: const Text('Weekdays'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedDays = {6, 7};
                          });
                        },
                        child: const Text('Weekends'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedDays = {1, 2, 3, 4, 5, 6, 7};
                          });
                        },
                        child: const Text('Every Day'),
                      ),
                    ],
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
                onPressed: selectedDays.isEmpty
                    ? null
                    : () {
                        // Create custom schedule
                        final schedule = Schedule(
                          id: 'custom_${packageName}_${DateTime.now().millisecondsSinceEpoch}',
                          startTime: startTime,
                          endTime: endTime,
                          daysOfWeek: selectedDays.toList()..sort(),
                          isEnabled: true,
                        );

                        setState(() {
                          _appCustomSchedules[packageName] = schedule;
                        });

                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayChip(String label, int day, Set<int> selectedDays, StateSetter setDialogState) {
    final isSelected = selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setDialogState(() {
          if (selected) {
            selectedDays.add(day);
          } else {
            selectedDays.remove(day);
          }
        });
      },
      selectedColor: Colors.blue.withOpacity(0.3),
      checkmarkColor: Colors.blue,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDays(List<int> days) {
    final dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    if (days.length == 7) {
      return 'Every day';
    } else if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    } else if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    } else {
      final sortedDays = List<int>.from(days)..sort();
      return sortedDays.map((d) => dayNames[d]).join(', ');
    }
  }
}
