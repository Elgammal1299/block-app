import 'dart:async';

/// A simple LRU (Least Recently Used) cache with TTL (Time To Live) support
/// Used to prevent redundant platform channel calls within a time window
/// 
/// Example:
/// ```dart
/// final cache = RequestCache<Map<String, int>>(ttl: Duration(seconds: 1));
/// 
/// // First call - fetches from platform
/// var stats = await cache.get('getDailyStats', () => platformService.getDailyStats());
/// 
/// // Second call within 1s - returns cached result (zero overhead)
/// var statsAgain = await cache.get('getDailyStats', () => platformService.getDailyStats());
/// ```
class RequestCache<T> {
  final Duration ttl;
  final int maxEntries;

  final Map<String, _CacheEntry<T>> _cache = {};

  RequestCache({
    this.ttl = const Duration(seconds: 1),
    this.maxEntries = 50,
  });

  /// Get a value from cache or fetch it using the provided callback
  /// If cache hit and not expired: returns cached value instantly
  /// If cache miss or expired: calls callback and caches result
  Future<T> get(String key, Future<T> Function() fetch) async {
    final now = DateTime.now();

    // Check if we have a cached entry that's still valid
    if (_cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (now.difference(entry.timestamp) < ttl) {
        // Cache hit - return cached value
        return entry.value;
      } else {
        // Cache expired - remove it
        _cache.remove(key);
      }
    }

    // Cache miss or expired - fetch new value
    final value = await fetch();

    // Store in cache (apply LRU if needed)
    if (_cache.length >= maxEntries) {
      // Remove least recently used (oldest entry)
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(value, now);
    return value;
  }

  /// Manually invalidate a cache entry
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics (useful for debugging)
  Map<String, dynamic> getStats() {
    return {
      'entries': _cache.length,
      'maxEntries': maxEntries,
      'ttl': ttl.inMilliseconds,
    };
  }

  /// Trim cache based on memory pressure
  /// trimRatio: 0.0 = keep all, 1.0 = clear all
  int trim(double trimRatio) {
    if (trimRatio >= 1.0) {
      final count = _cache.length;
      _cache.clear();
      return count;
    }

    if (trimRatio <= 0.0) return 0;

    // Remove oldest entries until we've trimmed enough
    final entriesToRemove = (_cache.length * trimRatio).ceil();
    int removed = 0;

    for (int i = 0; i < entriesToRemove && _cache.isNotEmpty; i++) {
      _cache.remove(_cache.keys.first);
      removed++;
    }

    return removed;
  }
}

/// Internal cache entry class
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Typed cache instances for common data types
class CacheManager {
  static final RequestCache<Map<String, int>> statsCache =
      RequestCache<Map<String, int>>(ttl: Duration(seconds: 1));

  static final RequestCache<List<dynamic>> listCache =
      RequestCache<List<dynamic>>(ttl: Duration(seconds: 2));

  static final RequestCache<String> stringCache =
      RequestCache<String>(ttl: Duration(seconds: 1));
}
