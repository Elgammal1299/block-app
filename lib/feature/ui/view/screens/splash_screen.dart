import 'package:flutter/material.dart';
import '../../../../core/services/platform_channel_service.dart';
import '../../../../core/services/cached_prefs_service.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../../core/router/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation and a bit more
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final platformService = getIt<PlatformChannelService>();
    final prefsService = getIt<CachedPreferencesService>();

    final hasUsageStats = await platformService.checkUsageStatsPermission();
    final hasOverlay = await platformService.checkOverlayPermission();
    final hasAccessibility = await platformService.checkAccessibilityPermission();
    final hasNotificationListener =
        await platformService.checkNotificationListenerPermission();
    final allPermissionsGranted = hasUsageStats &&
        hasOverlay &&
        hasAccessibility &&
        hasNotificationListener;

    final onboardingCompleted = await prefsService.getOnboardingCompleted();

    if (onboardingCompleted && allPermissionsGranted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      // If onboarding not completed or permissions missing, show onboarding/permissions
      Navigator.of(context).pushReplacementNamed(AppRoutes.permissions);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A1A), // Premium dark background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.block_flipped,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              const Text(
                'APP BLOCKER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              Text(
                'Control Your Time, Master Your Focus',
                style: TextStyle(
                  color: Colors.white.withAlpha(178), // 0.7 opacity
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              // Loading Indicator
              const SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
