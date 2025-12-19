import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import '../ui/view/screens/home_screen.dart';
import '../ui/view/screens/statistics_dashboard_screen.dart';
import 'screens/control_screen.dart';
import 'screens/focus_screen.dart';

class NabBarScreen extends StatefulWidget {
  const NabBarScreen({super.key});

  @override
  State<NabBarScreen> createState() => _NabBarScreenState();
}

class _NabBarScreenState extends State<NabBarScreen> {
  // Controllers
  late final NotchBottomBarController _controller;
  late final PageController _pageController;

  // Screens
  final List<Widget> _screens = const [
    HomeScreen(),
    ControlScreen(),
    FocusScreen(),
    StatisticsDashboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = NotchBottomBarController(index: 0);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors based on theme
    final inactiveColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) {
          // تحديث حالة الـ NotchBottomBar
          _controller.index = index;
        },
      ),

      bottomNavigationBar: AnimatedNotchBottomBar(
        shadowElevation: 0,
        elevation: 0,
        notchBottomBarController: _controller,
        color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.colorScheme.surface,
        notchColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.colorScheme.surface,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.home_rounded, color: inactiveColor),
            activeItem: Icon(Icons.home_rounded, color: primaryColor),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.block, color: inactiveColor),
            activeItem: Icon(Icons.block, color: Colors.red.shade400),
            itemLabel: 'Control',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.self_improvement, color: inactiveColor),
            activeItem: Icon(Icons.self_improvement, color: primaryColor),
            itemLabel: 'Focus',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.bar_chart, color: inactiveColor),
            activeItem: Icon(Icons.bar_chart, color: Colors.purple.shade400),
            itemLabel: 'Stats',
          ),
        ],
        onTap: (index) {
          // تحديث الصفحة المعروضة عند الضغط على أيقونة
          _pageController.jumpToPage(index);
        },
        kIconSize: 24,
        kBottomRadius: 28,
      ),
    );
  }
}
