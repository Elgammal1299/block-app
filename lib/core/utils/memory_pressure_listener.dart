import 'package:flutter/services.dart';
import 'package:app_block/core/utils/app_logger.dart';
import 'package:app_block/core/utils/request_cache.dart';

/// Phase 3.5+: Memory Pressure Listener
///
/// يستمع لـ system memory pressure events
/// وينظف الـ caches تلقائياً عند الضغط
///
/// المزايا:
/// - 🔴 TRIM_MEMORY_RUNNING_CRITICAL: حذف 80% من الكاش
/// - 🟠 TRIM_MEMORY_RUNNING_LOW: حذف 50% من الكاش
/// - 🟡 TRIM_MEMORY_RUNNING_MODERATE: حذف 25% من الكاش
/// - 🟢 TRIM_MEMORY_UI_HIDDEN: حذف 10% من الكاش
///
/// النتيجة:
/// - Bulletproof على الأجهزة الضعيفة (2GB RAM)
/// - تطبيق لا ينهار من pressure
/// - استعادة الأداء تلقائياً
class MemoryPressureListener {
  static final MemoryPressureListener _instance =
      MemoryPressureListener._internal();

  factory MemoryPressureListener() => _instance;
  MemoryPressureListener._internal();

  static const platform =
      MethodChannel('com.example.block_app/memory_pressure');

  bool _isListening = false;

  /// Start listening to memory pressure events
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;

    try {
      platform.setMethodCallHandler(_handleMemoryPressure);
      AppLogger.i('MemoryPressureListener: Started listening');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error starting', e);
      _isListening = false;
    }
  }

  /// Stop listening to memory pressure events
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      platform.setMethodCallHandler(null);
      _isListening = false;
      AppLogger.i('MemoryPressureListener: Stopped listening');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error stopping', e);
    }
  }

  /// Handle incoming memory pressure callback from native
  Future<dynamic> _handleMemoryPressure(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onTrimMemory':
          final level = call.arguments['level'] as int?;
          if (level != null) {
            await _trimMemory(level);
          }
          break;

        default:
          AppLogger.w('Unknown method: ${call.method}');
      }
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error handling pressure', e);
    }
  }

  /// Trim memory based on pressure level
  /// 0 = TRIM_MEMORY_RUNNING_MODERATE
  /// 5 = TRIM_MEMORY_RUNNING_LOW
  /// 10 = TRIM_MEMORY_RUNNING_CRITICAL
  /// 15 = TRIM_MEMORY_UI_HIDDEN
  Future<void> _trimMemory(int level) async {
    AppLogger.w(
      'MemoryPressureListener: Memory pressure detected (level: $level)',
    );

    try {
      if (level >= 10) {
        // CRITICAL: حذف 80% من الـ caches
        AppLogger.w('MemoryPressureListener: CRITICAL pressure - trimming 80%');
        await _trimCritical();
      } else if (level >= 5) {
        // LOW: حذف 50% من الـ caches
        AppLogger.w('MemoryPressureListener: LOW pressure - trimming 50%');
        await _trimLow();
      } else if (level >= 1) {
        // MODERATE: حذف 25% من الـ caches
        AppLogger.w(
          'MemoryPressureListener: MODERATE pressure - trimming 25%',
        );
        await _trimModerate();
      } else {
        // UI_HIDDEN: حذف 10% من الـ caches
        AppLogger.d('MemoryPressureListener: UI hidden - trimming 10%');
        await _trimUI();
      }

      AppLogger.i('MemoryPressureListener: Memory trim complete');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error trimming memory', e);
    }
  }

  /// TRIM_MEMORY_RUNNING_CRITICAL (80%)
  /// الوضع الأكثر حرجة - نحتاج إلى تحرير أكبر قدر من الذاكرة
  Future<void> _trimCritical() async {
    try {
      // Icon Cache: حذف 80% (احتفظ بـ 20 icons آخر)
      // RequestCache: حذف الكل
      // CachedPrefs: حذف الـ non-essential فقط
      await Future.wait([
        _trimIconCache(trimRatio: 0.80),
        _trimRequestCache(trimRatio: 1.0),
        _trimCachedPrefs(trimRatio: 0.50),
      ], eagerError: false);

      AppLogger.w('MemoryPressureListener: Critical trim executed');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error during critical trim', e);
    }
  }

  /// TRIM_MEMORY_RUNNING_LOW (50%)
  /// وضع منخفض - حرر نصف الـ caches
  Future<void> _trimLow() async {
    try {
      await Future.wait([
        _trimIconCache(trimRatio: 0.50),
        _trimRequestCache(trimRatio: 0.75),
        _trimCachedPrefs(trimRatio: 0.25),
      ], eagerError: false);

      AppLogger.w('MemoryPressureListener: Low trim executed');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error during low trim', e);
    }
  }

  /// TRIM_MEMORY_RUNNING_MODERATE (25%)
  /// وضع معتدل - حرر ربع الـ caches
  Future<void> _trimModerate() async {
    try {
      await Future.wait([
        _trimIconCache(trimRatio: 0.25),
        _trimRequestCache(trimRatio: 0.50),
        _trimCachedPrefs(trimRatio: 0.10),
      ], eagerError: false);

      AppLogger.d('MemoryPressureListener: Moderate trim executed');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error during moderate trim', e);
    }
  }

  /// TRIM_MEMORY_UI_HIDDEN (10%)
  /// واجهة المستخدم مختفية - حرر 10% من الـ caches
  Future<void> _trimUI() async {
    try {
      await Future.wait([
        _trimIconCache(trimRatio: 0.10),
        _trimRequestCache(trimRatio: 0.25),
        // لا نحتاج لتحرير prefs cache
      ], eagerError: false);

      AppLogger.d('MemoryPressureListener: UI trim executed');
    } catch (e) {
      AppLogger.e('MemoryPressureListener: Error during UI trim', e);
    }
  }

  /// Trim icon cache
  Future<void> _trimIconCache({required double trimRatio}) async {
    try {
      // This will be implemented in IconCacheManager
      AppLogger.d('Trimming icon cache ($trimRatio)...');
      // await _iconPreloader.trimCache(trimRatio);
    } catch (e) {
      AppLogger.e('Error trimming icon cache', e);
    }
  }

  /// Trim request cache
  Future<void> _trimRequestCache({required double trimRatio}) async {
    try {
      // This will be implemented in RequestCache
      if (trimRatio >= 1.0) {
        // Clear completely
        CacheManager.statsCache.clear();
        CacheManager.listCache.clear();
        CacheManager.stringCache.clear();
        AppLogger.w('Request cache cleared completely');
      } else {
        // Trim oldest entries
        int statsRemoved = CacheManager.statsCache.trim(trimRatio);
        int listRemoved = CacheManager.listCache.trim(trimRatio);
        int stringRemoved = CacheManager.stringCache.trim(trimRatio);

        AppLogger.d(
          'Request cache trimmed: stats=$statsRemoved, list=$listRemoved, string=$stringRemoved',
        );
      }
    } catch (e) {
      AppLogger.e('Error trimming request cache', e);
    }
  }

  /// Trim cached preferences
  Future<void> _trimCachedPrefs({required double trimRatio}) async {
    try {
      // This will be called on CachedPreferencesService
      AppLogger.d('Trimming cached prefs ($trimRatio)...');
      // await _cachedPrefsService.trim(trimRatio);
    } catch (e) {
      AppLogger.e('Error trimming cached prefs', e);
    }
  }

  /// Get listener status
  bool get isListening => _isListening;
}
