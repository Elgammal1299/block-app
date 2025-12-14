import 'package:flutter/material.dart';
import '../../../../core/services/platform_channel_service.dart';

class PermissionsGuideScreen extends StatefulWidget {
  const PermissionsGuideScreen({super.key});

  @override
  State<PermissionsGuideScreen> createState() => _PermissionsGuideScreenState();
}

class _PermissionsGuideScreenState extends State<PermissionsGuideScreen> {
  final PlatformChannelService _platformService = PlatformChannelService();

  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _accessibilityGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final usageStats = await _platformService.checkUsageStatsPermission();
    final overlay = await _platformService.checkOverlayPermission();
    final accessibility = await _platformService.checkAccessibilityPermission();

    setState(() {
      _usageStatsGranted = usageStats;
      _overlayGranted = overlay;
      _accessibilityGranted = accessibility;
    });
  }

  bool get _allPermissionsGranted =>
      _usageStatsGranted && _overlayGranted && _accessibilityGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required Permissions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app needs special permissions to monitor and block apps. Please grant all permissions below.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  _buildPermissionCard(
                    title: 'Usage Stats Access',
                    description:
                        'Required to monitor which apps are currently running and track usage statistics.',
                    icon: Icons.bar_chart,
                    color: Colors.blue,
                    isGranted: _usageStatsGranted,
                    onRequest: () async {
                      await _platformService.requestUsageStatsPermission();
                      await Future.delayed(const Duration(seconds: 2));
                      _checkPermissions();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionCard(
                    title: 'Draw Over Other Apps',
                    description:
                        'Required to show the blocking screen when you try to open a blocked app.',
                    icon: Icons.layers,
                    color: Colors.orange,
                    isGranted: _overlayGranted,
                    onRequest: () async {
                      await _platformService.requestOverlayPermission();
                      await Future.delayed(const Duration(seconds: 2));
                      _checkPermissions();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionCard(
                    title: 'Accessibility Service',
                    description:
                        'Required to detect when blocked apps are opened and prevent access to them. This is the most important permission.',
                    icon: Icons.accessibility_new,
                    color: Colors.red,
                    isGranted: _accessibilityGranted,
                    onRequest: () async {
                      await _platformService.requestAccessibilityPermission();
                      await Future.delayed(const Duration(seconds: 2));
                      _checkPermissions();
                    },
                    isImportant: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allPermissionsGranted
                    ? () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _allPermissionsGranted
                      ? 'Continue to App'
                      : 'Grant All Permissions First',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isGranted,
    required VoidCallback onRequest,
    bool isImportant = false,
  }) {
    return Card(
      elevation: isImportant ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            isGranted ? Icons.check_circle : Icons.cancel,
                            color: isGranted ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      if (isImportant)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'IMPORTANT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isGranted ? null : onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGranted ? Colors.green : color,
                ),
                child: Text(
                  isGranted ? 'Granted ✓' : 'Grant Permission',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
