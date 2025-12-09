import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/blocked_apps_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/platform_channel_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start monitoring service and sync data automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  Future<void> _initializeService() async {
    try {
      // Sync schedules and blocked apps to Native
      await _syncDataToNative();

      // Start monitoring service
      final platformService = PlatformChannelService();
      await platformService.startMonitoringService();
    } catch (e) {
      print('Error initializing service: $e');
    }
  }

  Future<void> _syncDataToNative() async {
    try {
      final scheduleProvider = context.read<ScheduleProvider>();
      final blockedAppsProvider = context.read<BlockedAppsProvider>();

      // Sync schedules
      final schedules = scheduleProvider.schedules;
      final platformService = PlatformChannelService();
      await platformService.updateSchedules(schedules);
      print('Synced ${schedules.length} schedules to Native');

      // Sync blocked apps
      final blockedApps = blockedAppsProvider.blockedApps;
      final appsJson = jsonEncode(blockedApps.map((app) => app.toJson()).toList());
      await platformService.updateBlockedAppsJson(appsJson);
      print('Synced ${blockedApps.length} blocked apps to Native');
    } catch (e) {
      print('Error syncing data to Native: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedAppsProvider = context.watch<BlockedAppsProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocker'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await blockedAppsProvider.loadBlockedApps();
          await scheduleProvider.loadSchedules();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Status Card
              _buildServiceStatusCard(),
              const SizedBox(height: 16),

              // Today's Stats Card
              _buildTodayStatsCard(blockedAppsProvider, scheduleProvider),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/app-selection');
        },
        icon: const Icon(Icons.block),
        label: const Text('Block Apps'),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Running',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'App monitoring is active',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Permissions Screen
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatsCard(
    BlockedAppsProvider blockedAppsProvider,
    ScheduleProvider scheduleProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Blocked Apps',
                    blockedAppsProvider.totalBlockedApps.toString(),
                    Icons.block,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Schedules',
                    scheduleProvider.enabledSchedules.length.toString(),
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Block Attempts',
                    blockedAppsProvider.totalBlockAttempts.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          'Manage Apps',
          Icons.apps,
          Colors.purple,
          () {
            Navigator.of(context).pushNamed('/app-selection');
          },
        ),
        _buildActionCard(
          'Schedules',
          Icons.calendar_today,
          Colors.green,
          () {
            Navigator.of(context).pushNamed('/schedules');
          },
        ),
        _buildActionCard(
          'Statistics',
          Icons.bar_chart,
          Colors.orange,
          () {
            // TODO: Navigate to Statistics
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statistics coming soon!')),
            );
          },
        ),
        _buildActionCard(
          'Focus Mode',
          Icons.self_improvement,
          Colors.blue,
          () {
            // TODO: Navigate to Focus Mode
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Focus Mode coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
