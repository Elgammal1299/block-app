import '../utils/app_logger.dart';

/// Phase 3: Intelligent Prefetching
/// 
/// Eager-loads frequently accessed data to prevent loading delays
/// Uses a priority-based approach to prefetch the most important data first
class IntelligentPrefetcher {
  static final IntelligentPrefetcher _instance =
      IntelligentPrefetcher._internal();

  factory IntelligentPrefetcher() => _instance;
  IntelligentPrefetcher._internal();

  // Track prefetch operations
  final Map<String, Future<void> Function()> _prefetchOperations = {};
  final Set<String> _completedPrefetches = {};
  final Map<String, int> _prefetchPriority = {};

  // Prefetch groups (load together)
  static const String _groupEssential = 'essential';
  static const String _groupDashboard = 'dashboard';

  /// Register a prefetch operation
  /// Priority: higher number = higher priority (executed first)
  void registerPrefetch(
    String key,
    Future<void> Function() operation, {
    int priority = 0,
    String group = _groupEssential,
  }) {
    _prefetchPriority[key] = priority;
    _prefetchOperations[key] = () async {
      try {
        AppLogger.d('Prefetching: $key (priority: $priority)');
        await operation();
        _completedPrefetches.add(key);
        AppLogger.d('Prefetch completed: $key');
      } catch (e) {
        AppLogger.e('Error prefetching $key', e);
        rethrow;
      }
    };
  }

  /// Prefetch essential data (blocking on app startup)
  /// Should be as fast as possible
  Future<void> prefetchEssentialData() async {
    final essentialKeys = _prefetchOperations.keys
        .where((key) => (_prefetchPriority[key] ?? 0) >= 10)
        .toList();

    AppLogger.i('Prefetching ${essentialKeys.length} essential items');

    // Sort by priority (descending)
    essentialKeys.sort(
      (a, b) => (_prefetchPriority[b] ?? 0).compareTo(_prefetchPriority[a] ?? 0),
    );

    // Execute in parallel with timeout
    try {
      await Future.wait(
        essentialKeys.map((key) => _prefetchOperations[key]!()),
        eagerError: false,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.w('Essential prefetch timeout - continuing anyway');
          return <dynamic>[];
        },
      );
    } catch (e) {
      AppLogger.e('Error during essential prefetch', e);
    }
  }

  /// Prefetch dashboard data (non-blocking, background)
  /// Should run after UI is visible
  Future<void> prefetchDashboardData() async {
    final dashboardKeys = _prefetchOperations.keys
        .where((key) => (_prefetchPriority[key] ?? 0) >= 5)
        .where((key) => !_completedPrefetches.contains(key))
        .toList();

    if (dashboardKeys.isEmpty) return;

    AppLogger.i('Background prefetch for ${dashboardKeys.length} dashboard items');

    // Execute in background (don't wait)
    Future.wait(
      dashboardKeys.map((key) => _prefetchOperations[key]!()),
      eagerError: false,
    ).then((_) {
      AppLogger.i('Dashboard prefetch completed');
    }).catchError((e) {
      AppLogger.e('Error during dashboard prefetch', e);
    });
  }

  /// Check if a key has been prefetched
  bool isPrefetched(String key) => _completedPrefetches.contains(key);

  /// Get prefetch status
  Map<String, dynamic> getStatus() {
    return {
      'total': _prefetchOperations.length,
      'completed': _completedPrefetches.length,
      'pending': _prefetchOperations.length - _completedPrefetches.length,
      'completedKeys': _completedPrefetches.toList(),
    };
  }

  /// Clear prefetch cache (for testing or memory cleanup)
  void clear() {
    _completedPrefetches.clear();
    AppLogger.d('Cleared prefetch cache');
  }
}

/// Common prefetch operations for statistics data
class StatisticsPrefetcher {
  /// Prefetch app usage statistics
  /// Priority: 15 (highest - essential for dashboard)
  static void registerAppUsageStatsPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<List<dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'app_usage_stats',
      fetchFunction,
      priority: 15,
      group: IntelligentPrefetcher._groupEssential,
    );
  }

  /// Prefetch app icons
  /// Priority: 12 (high - needed for dashboard UI)
  static void registerAppIconsPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<Map<String, dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'app_icons',
      fetchFunction,
      priority: 12,
      group: IntelligentPrefetcher._groupDashboard,
    );
  }

  /// Prefetch comparison statistics
  /// Priority: 8 (medium - nice to have)
  static void registerComparisonStatsPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<Map<String, dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'comparison_stats',
      fetchFunction,
      priority: 8,
      group: IntelligentPrefetcher._groupDashboard,
    );
  }

  /// Prefetch blocked apps list
  /// Priority: 10 (high - needed for all operations)
  static void registerBlockedAppsPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<List<dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'blocked_apps',
      fetchFunction,
      priority: 10,
      group: IntelligentPrefetcher._groupEssential,
    );
  }

  /// Prefetch schedules
  /// Priority: 10 (high - needed for blocking logic)
  static void registerSchedulesPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<List<dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'schedules',
      fetchFunction,
      priority: 10,
      group: IntelligentPrefetcher._groupEssential,
    );
  }

  /// Prefetch usage limits
  /// Priority: 9 (medium-high - needed for blocking)
  static void registerUsageLimitsPrefetch(
    IntelligentPrefetcher prefetcher,
    Future<List<dynamic>> Function() fetchFunction,
  ) {
    prefetcher.registerPrefetch(
      'usage_limits',
      fetchFunction,
      priority: 9,
      group: IntelligentPrefetcher._groupEssential,
    );
  }
}
