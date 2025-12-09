import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/blocked_apps_provider.dart';
import '../../data/models/blocked_app.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize with existing schedules for each app
    for (var app in widget.selectedApps) {
      _appSchedules[app.packageName] = Set.from(app.scheduleIds);
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
    final blockedAppsProvider = context.read<BlockedAppsProvider>();

    // Update each app with its selected schedules
    final updatedApps = widget.selectedApps.map((app) {
      return app.copyWith(
        scheduleIds: _appSchedules[app.packageName]!.toList(),
      );
    }).toList();

    await blockedAppsProvider.saveBlockedApps(updatedApps);

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
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Blocking Schedules'),
      ),
      body: scheduleProvider.schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No schedules available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create schedules first to assign them to apps',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/schedules');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Schedule'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.selectedApps.length,
              itemBuilder: (context, index) {
                final app = widget.selectedApps[index];
                return _buildAppScheduleCard(app, scheduleProvider);
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
      BlockedApp app, ScheduleProvider scheduleProvider) {
    final selectedSchedules = _appSchedules[app.packageName] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          selectedSchedules.isEmpty
              ? 'Always blocked (24/7)'
              : '${selectedSchedules.length} schedule(s) selected',
          style: TextStyle(
            fontSize: 12,
            color: selectedSchedules.isEmpty ? Colors.red : Colors.blue,
          ),
        ),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Select when to block this app:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Option: Always blocked
          CheckboxListTile(
            title: const Text('Always Blocked (24/7)'),
            subtitle: const Text('Block this app at all times'),
            value: selectedSchedules.isEmpty,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _appSchedules[app.packageName]!.clear();
                }
              });
            },
            secondary: const Icon(Icons.block, color: Colors.red),
          ),
          const Divider(),
          // Schedules list
          ...scheduleProvider.schedules.map((schedule) {
            final isSelected = selectedSchedules.contains(schedule.id);
            return CheckboxListTile(
              title: Text(
                '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
              ),
              subtitle: Text(_formatDays(schedule.daysOfWeek)),
              value: isSelected,
              onChanged: (value) {
                _toggleSchedule(app.packageName, schedule.id);
              },
              secondary: Icon(
                Icons.schedule,
                color: schedule.isEnabled ? Colors.blue : Colors.grey,
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
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
