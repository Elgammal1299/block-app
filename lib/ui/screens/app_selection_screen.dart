import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_list_provider.dart';
import '../../providers/blocked_apps_provider.dart';
import '../../data/models/app_info.dart';
import '../../data/models/blocked_app.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  final Set<String> _selectedPackages = {};
  bool _isLoading = false;

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

    final appListProvider = context.read<AppListProvider>();
    final blockedAppsProvider = context.read<BlockedAppsProvider>();

    setState(() => _isLoading = true);

    // Load installed apps
    await appListProvider.loadInstalledApps();

    // Load currently blocked apps and add to selection
    await blockedAppsProvider.loadBlockedApps();

    if (mounted) {
      setState(() {
        _selectedPackages.addAll(
          blockedAppsProvider.blockedApps.map((app) => app.packageName),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelection() async {
    final blockedAppsProvider = context.read<BlockedAppsProvider>();
    final appListProvider = context.read<AppListProvider>();

    // Create BlockedApp objects for selected packages
    final blockedApps = _selectedPackages.map((packageName) {
      final appInfo = appListProvider.apps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      return BlockedApp(
        packageName: packageName,
        appName: appInfo.appName,
        isBlocked: true,
        blockAttempts: 0,
      );
    }).toList();

    // Save to repository
    await blockedAppsProvider.saveBlockedApps(blockedApps);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${blockedApps.length} apps blocked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appListProvider = context.watch<AppListProvider>();

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
      body: Column(
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
                appListProvider.setSearchQuery(value);
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
                  value: appListProvider.showSystemApps,
                  onChanged: (value) {
                    appListProvider.toggleShowSystemApps();
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : appListProvider.apps.isEmpty
                    ? const Center(
                        child: Text('No apps found'),
                      )
                    : ListView.builder(
                        itemCount: appListProvider.apps.length,
                        itemBuilder: (context, index) {
                          final app = appListProvider.apps[index];
                          final isSelected =
                              _selectedPackages.contains(app.packageName);

                          return _buildAppItem(app, isSelected);
                        },
                      ),
          ),
        ],
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
