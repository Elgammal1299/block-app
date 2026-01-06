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
  late final PageController _pageController;
  int _currentIndex = 0;

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
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        // Using a slight elevation and background color for a nice look
        elevation: 3,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.block_outlined),
            selectedIcon: Icon(Icons.block),
            label: 'التحكم',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'التركيز',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'الإحصائيات',
          ),
        ],
      ),
    );
  }
}
