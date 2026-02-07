import 'package:app_block/core/utils/intelligent_prefetcher.dart';
import 'package:app_block/core/utils/icon_preloader.dart';
import 'package:app_block/core/utils/app_logger.dart';

/// Phase 3.5: App Startup Optimizer
///
/// يدمج:
/// 1. IntelligentPrefetcher (بيانات ذكية)
/// 2. IconPreloader (icons مخزنة مؤقتاً)
/// 3. SmartBackgroundScheduler (خلفية ذكية)
///
/// السلسلة الزمنية للبدء:
/// 1. (T+0ms) Splash screen
/// 2. (T+100ms) Essential data preload (في parallel)
/// 3. (T+500ms) Icon preload (شامل)
/// 4. (T+1000ms) Dashboard data preload (بدون انتظار)
/// 5. (T+3000ms) UI جاهز
class AppStartupOptimizer {
  static final AppStartupOptimizer _instance =
      AppStartupOptimizer._internal();

  factory AppStartupOptimizer() => _instance;
  AppStartupOptimizer._internal();

  final _prefetcher = IntelligentPrefetcher();
  final _iconPreloader = IconPreloader();

  bool _isOptimized = false;

  /// Check if startup optimization is complete
  bool get isOptimized => _isOptimized;

  /// Execute full startup optimization
  /// Call this as early as possible in main()
  Future<void> optimizeStartup() async {
    if (_isOptimized) return;

    AppLogger.i('AppStartupOptimizer: Starting optimization...');

    try {
      // Step 1: Prefetch essential data (blocking with timeout)
      AppLogger.d('AppStartupOptimizer: Step 1 - Prefetch essential data');
      await _prefetcher.prefetchEssentialData();

      // Step 2: Preload app icons (non-blocking after essential data)
      AppLogger.d('AppStartupOptimizer: Step 2 - Preload app icons');
      _iconPreloader.preloadAllAppIcons().ignore();

      // Step 3: Prefetch dashboard data (pure background)
      AppLogger.d('AppStartupOptimizer: Step 3 - Prefetch dashboard data');
      _prefetcher.prefetchDashboardData();

      _isOptimized = true;
      AppLogger.i('AppStartupOptimizer: Optimization complete!');
    } catch (e) {
      AppLogger.e('AppStartupOptimizer: Error during optimization', e);
      // تابع حتى لو حصل خطأ
      _isOptimized = true;
    }
  }

  /// Get optimization status
  Future<Map<String, dynamic>> getStatus() async {
    final iconStats = await _iconPreloader.getCacheStats();

    return {
      'isOptimized': _isOptimized,
      'iconPreloaderIsPreloading': _iconPreloader.isPreloading,
      'iconPreloaderIsPreloaded': _iconPreloader.isPreloaded,
      'preloadedIconCount': _iconPreloader.preloadedCount,
      'iconCacheStats': iconStats,
    };
  }

  /// Reset optimization state (for testing)
  Future<void> reset() async {
    _isOptimized = false;
    await _iconPreloader.clearCache();
    AppLogger.i('AppStartupOptimizer: Reset complete');
  }
}
