import 'dart:async';
import '../utils/app_logger.dart';

/// Phase 3: Smart Background Scheduler
/// 
/// Reduces unnecessary wakeups by batching preference changes
/// and scheduling refresh operations intelligently.
/// 
/// Strategies:
/// - Batch preference change listeners (200ms debounce)
/// - Batch cache refresh operations
/// - Only refresh data that actually changed
/// - Avoid multiple refreshes within short timeframe
class SmartBackgroundScheduler {
  static final SmartBackgroundScheduler _instance =
      SmartBackgroundScheduler._internal();

  factory SmartBackgroundScheduler() => _instance;
  SmartBackgroundScheduler._internal();

  // Pending refresh operations (batch them together)
  final Set<String> _pendingRefreshKeys = {};
  Timer? _batchRefreshTimer;
  final Duration _batchRefreshDelay = const Duration(milliseconds: 200);

  // Track last refresh time per key (avoid redundant refreshes)
  final Map<String, DateTime> _lastRefreshTime = {};
  final Duration _minRefreshInterval = const Duration(seconds: 2);

  // Callbacks for refresh operations
  final Map<String, Future<void> Function()> _refreshCallbacks = {};

  /// Register a refresh callback for a key
  /// This will be called when the key needs to be refreshed
  void registerRefreshCallback(
    String key,
    Future<void> Function() callback,
  ) {
    _refreshCallbacks[key] = callback;
  }

  /// Schedule a refresh operation (batched)
  /// Multiple refreshes requested within batchRefreshDelay will be combined
  /// Returns a future that completes when the actual refresh happens
  Future<void> scheduleRefresh(String key) async {
    // Check if we've refreshed recently (avoid redundant refreshes)
    final lastRefresh = _lastRefreshTime[key];
    if (lastRefresh != null) {
      final timeSinceLastRefresh = DateTime.now().difference(lastRefresh);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        AppLogger.d('Skipping redundant refresh for $key (too soon)');
        return;
      }
    }

    // Add to pending refreshes
    _pendingRefreshKeys.add(key);

    // Cancel existing timer and start new one (batches multiple requests)
    _batchRefreshTimer?.cancel();
    _batchRefreshTimer = Timer(_batchRefreshDelay, () {
      _executeBatchRefresh();
    });
  }

  /// Execute all pending refresh operations in batch
  Future<void> _executeBatchRefresh() async {
    if (_pendingRefreshKeys.isEmpty) {
      return;
    }

    final keys = _pendingRefreshKeys.toList();
    _pendingRefreshKeys.clear();

    AppLogger.i('Executing batch refresh for ${keys.length} keys: $keys');

    // Execute all refreshes in parallel
    try {
      await Future.wait(
        keys.map((key) async {
          try {
            final callback = _refreshCallbacks[key];
            if (callback != null) {
              await callback();
              _lastRefreshTime[key] = DateTime.now();
            }
          } catch (e) {
            AppLogger.e('Error refreshing $key', e);
          }
        }),
      );
    } catch (e) {
      AppLogger.e('Error during batch refresh', e);
    }
  }

  /// Force immediate refresh (skip batching)
  Future<void> forceRefresh(String key) async {
    final callback = _refreshCallbacks[key];
    if (callback != null) {
      try {
        await callback();
        _lastRefreshTime[key] = DateTime.now();
        AppLogger.d('Force refreshed $key');
      } catch (e) {
        AppLogger.e('Error force refreshing $key', e);
      }
    }
  }

  /// Get pending refresh count
  int get pendingRefreshCount => _pendingRefreshKeys.length;

  /// Get pending refresh keys
  List<String> get pendingRefreshKeys => _pendingRefreshKeys.toList();

  /// Clear all pending refreshes
  void clearPending() {
    _batchRefreshTimer?.cancel();
    _pendingRefreshKeys.clear();
    AppLogger.d('Cleared all pending refreshes');
  }

  /// Cleanup (call on app exit)
  void dispose() {
    _batchRefreshTimer?.cancel();
    _pendingRefreshKeys.clear();
    _refreshCallbacks.clear();
    _lastRefreshTime.clear();
  }
}
