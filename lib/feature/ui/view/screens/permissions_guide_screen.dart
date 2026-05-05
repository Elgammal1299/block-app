import 'package:flutter/material.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/services/cached_prefs_service.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/localization/app_localizations.dart';
import 'accessibility_disclosure_screen.dart';

class PermissionsGuideScreen extends StatefulWidget {
  const PermissionsGuideScreen({super.key});

  @override
  State<PermissionsGuideScreen> createState() => _PermissionsGuideScreenState();
}

class _PermissionsGuideScreenState extends State<PermissionsGuideScreen> {
  final PageController _pageController = PageController();
  final PlatformChannelService _platformService =
      getIt<PlatformChannelService>();
  final CachedPreferencesService _prefsService =
      getIt<CachedPreferencesService>();

  int _currentPage = 0;
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _accessibilityGranted = false;
  bool _notificationListenerGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final usageStats = await _platformService.checkUsageStatsPermission();
    final overlay = await _platformService.checkOverlayPermission();
    final accessibility = await _platformService.checkAccessibilityPermission();
    final notificationListener =
        await _platformService.checkNotificationListenerPermission();

    if (mounted) {
      setState(() {
        _usageStatsGranted = usageStats;
        _overlayGranted = overlay;
        _accessibilityGranted = accessibility;
        _notificationListenerGranted = notificationListener;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      // Last page - ensure all permissions are double-checked
      await _checkPermissions();
      if (_usageStatsGranted &&
          _overlayGranted &&
          _accessibilityGranted &&
          _notificationListenerGranted) {
        // Save onboarding completion status
        await _prefsService.setOnboardingCompleted(true);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant all permissions to continue'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),
      body: Stack(
        children: [
          // Background Aesthetic Orbs
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.purple.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header with Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'STEP ${_currentPage + 1}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          4,
                          (index) => _buildIndicator(index),
                        ),
                      ),
                    ],
                  ),
                ),

                // Onboarding Pages Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Sequential flow
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildOnboardingStep(
                        title: l10n.onboardingUsageTitle,
                        description: l10n.onboardingUsageDesc,
                        icon: Icons.bar_chart_rounded,
                        color: Colors.blue,
                        isGranted: _usageStatsGranted,
                        l10n: l10n,
                        onRequest: () async {
                          await _platformService.requestUsageStatsPermission();
                          // Polling or delay to check status
                          await Future.delayed(const Duration(seconds: 2));
                          _checkPermissions();
                        },
                      ),
                      _buildOnboardingStep(
                        title: l10n.onboardingOverlayTitle,
                        description: l10n.onboardingOverlayDesc,
                        icon: Icons.layers_rounded,
                        color: Colors.purpleAccent,
                        isGranted: _overlayGranted,
                        l10n: l10n,
                        onRequest: () async {
                          await _platformService.requestOverlayPermission();
                          await Future.delayed(const Duration(seconds: 2));
                          _checkPermissions();
                        },
                      ),
                      _buildOnboardingStep(
                        title: l10n.onboardingAccessibilityTitle,
                        description: l10n.onboardingAccessibilityDesc,
                        icon: Icons.accessibility_new_rounded,
                        color: Colors.orangeAccent,
                        isGranted: _accessibilityGranted,
                        l10n: l10n,
                        onRequest: () async {
                          // ── Google Play Prominent Disclosure Requirement ──
                          // Show disclosure screen BEFORE opening Android settings.
                          // The user must acknowledge what the service does and
                          // does NOT do before being sent to grant the permission.
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.92,
                              minChildSize: 0.70,
                              maxChildSize: 0.95,
                              builder: (_, scrollController) =>
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: AccessibilityDisclosureScreen(
                                      onAccepted: () async {
                                        Navigator.of(context).pop(); // close sheet
                                        await _platformService
                                            .requestAccessibilityPermission();
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        _checkPermissions();
                                      },
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                      _buildOnboardingStep(
                        title: l10n.onboardingNotificationTitle,
                        description: l10n.onboardingNotificationDesc,
                        icon: Icons.notifications_active_rounded,
                        color: Colors.tealAccent,
                        isGranted: _notificationListenerGranted,
                        l10n: l10n,
                        onRequest: () async {
                          await _platformService
                              .requestNotificationListenerPermission();
                          await Future.delayed(const Duration(seconds: 2));
                          _checkPermissions();
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Action Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (_isCurrentPermissionGranted)
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCurrentPermissionGranted ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 3
                            ? l10n.onboardingStart
                            : l10n.onboardingNext,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isCurrentPermissionGranted {
    if (_currentPage == 0) return _usageStatsGranted;
    if (_currentPage == 1) return _overlayGranted;
    if (_currentPage == 2) return _accessibilityGranted;
    if (_currentPage == 3) return _notificationListenerGranted;
    return false;
  }

  Widget _buildIndicator(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(left: 6),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildOnboardingStep({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isGranted,
    required AppLocalizations l10n,
    required VoidCallback onRequest,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual Illustration Area
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGranted
                      ? Colors.green.withOpacity(0.05)
                      : color.withOpacity(0.05),
                ),
              ),
              // Glass Circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: isGranted ? Colors.green : color,
                ),
              ),
              // Status Badge
              if (isGranted)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 60),

          // Narrative
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 50),

          // Action
          if (!isGranted)
            SizedBox(
              width: 220,
              height: 54,
              child: OutlinedButton(
                onPressed: onRequest,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.onboardingEnable,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                l10n.permissionGranted.toUpperCase(),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
