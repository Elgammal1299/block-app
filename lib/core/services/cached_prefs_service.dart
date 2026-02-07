import 'dart:async';
import 'package:app_block/feature/data/local/shared_prefs_service.dart';
import 'package:app_block/feature/data/models/blocked_app.dart';
import 'package:app_block/feature/data/models/schedule.dart';
import 'package:app_block/feature/data/models/app_usage_limit.dart';
import 'package:app_block/feature/data/models/focus_list.dart';
import '../utils/smart_background_scheduler.dart';
import '../utils/differential_cache_updater.dart';

/// Hybrid Caching Strategy:
/// - Immediate invalidation on critical changes
/// - 200ms debounce on listener to prevent spam
/// - Zero-copy access to cached decoded objects
/// - Phase 3: Smart background scheduling for refresh operations
class CachedPreferencesService {
  final SharedPrefsService _prefsService;
  final SmartBackgroundScheduler _scheduler = SmartBackgroundScheduler();

  // ===== In-Memory Caches =====
  List<BlockedApp>? _cachedBlockedApps;
  List<Schedule>? _cachedSchedules;
  Map<String, AppUsageLimit>? _cachedLimits;
  List<FocusList>? _cachedFocusLists;
  List<dynamic>? _cachedFocusSessions;

  // ===== Debounce Timers =====
  Timer? _blockedAppsDebounceTimer;
  Timer? _schedulesDebounceTimer;
  Timer? _limitsDebounceTimer;
  Timer? _focusListsDebounceTimer;
  Timer? _focusSessionsDebounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 200);

  CachedPreferencesService(this._prefsService) {
    _initializeScheduler();
  }

  /// Initialize smart background scheduler with refresh callbacks
  void _initializeScheduler() {
    _scheduler.registerRefreshCallback('blocked_apps', () async {
      _cachedBlockedApps = null;
      await _loadBlockedApps();
    });

    _scheduler.registerRefreshCallback('schedules', () async {
      _cachedSchedules = null;
      await _loadSchedules();
    });

    _scheduler.registerRefreshCallback('limits', () async {
      _cachedLimits = null;
      await _loadUsageLimits();
    });

    _scheduler.registerRefreshCallback('focus_lists', () async {
      _cachedFocusLists = null;
      await _loadFocusLists();
    });

    _scheduler.registerRefreshCallback('focus_sessions', () async {
      _cachedFocusSessions = null;
      await _loadFocusSessions();
    });
  }

  /// ==================== Blocked Apps Cache ====================

  /// Get blocked apps from cache (zero-copy if cached)
  /// Falls back to loading from SharedPreferences if not cached
  Future<List<BlockedApp>> getBlockedApps() async {
    if (_cachedBlockedApps != null) {
      return _cachedBlockedApps!;
    }
    return await _loadBlockedApps();
  }

  /// Force refresh blocked apps cache
  Future<void> refreshBlockedApps() async {
    _cachedBlockedApps = null;
    await _loadBlockedApps();
  }

  /// Internal: Load from SharedPreferences and cache (with differential updates)
  Future<List<BlockedApp>> _loadBlockedApps() async {
    final newApps = await _prefsService.getBlockedApps();

    // Phase 3: Use differential updates to avoid unnecessary re-parsing
    final oldApps = _cachedBlockedApps;
    if (oldApps != null && oldApps.isNotEmpty) {
      final diff = DifferentialCacheUpdater.computeListDifferences(
        oldList: oldApps,
        newList: newApps,
        getId: (app) => app.packageName,
        isEqual: (a, b) =>
            a.packageName == b.packageName &&
            a.isBlocked == b.isBlocked &&
            a.blockAttempts == b.blockAttempts,
      );

      if (diff.hasChanges) {
        DifferentialCacheUpdater.logDifferences(diff);
        _cachedBlockedApps = diff.mergeChanges(oldApps);
      }
    } else {
      _cachedBlockedApps = newApps;
    }

    return _cachedBlockedApps ?? [];
  }

  /// Save blocked apps and invalidate cache
  /// IMMEDIATE INVALIDATION (no debounce for critical data)
  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final result = await _prefsService.saveBlockedApps(apps);
    if (result) {
      // Immediate invalidation for critical data
      _cachedBlockedApps = null;
    }
    return result;
  }

  /// Add blocked app and invalidate cache
  Future<bool> addBlockedApp(BlockedApp app) async {
    final result = await _prefsService.addBlockedApp(app);
    if (result) {
      _cachedBlockedApps = null; // Immediate invalidation
    }
    return result;
  }

  /// Remove blocked app and invalidate cache
  Future<bool> removeBlockedApp(String packageName) async {
    final result = await _prefsService.removeBlockedApp(packageName);
    if (result) {
      _cachedBlockedApps = null; // Immediate invalidation
    }
    return result;
  }

  /// Update block attempts with debounce invalidation
  Future<bool> updateBlockAttempts(String packageName, int attempts) async {
    final result = await _prefsService.updateBlockAttempts(packageName, attempts);
    if (result) {
      _debouncedInvalidateBlockedApps();
    }
    return result;
  }

  /// Increment block attempts with debounce invalidation
  Future<bool> incrementBlockAttempts(String packageName) async {
    final result = await _prefsService.incrementBlockAttempts(packageName);
    if (result) {
      _debouncedInvalidateBlockedApps();
    }
    return result;
  }

  /// Debounced invalidation for non-critical changes
  void _debouncedInvalidateBlockedApps() {
    _blockedAppsDebounceTimer?.cancel();
    _blockedAppsDebounceTimer = Timer(_debounceDuration, () {
      // Phase 3: Use smart scheduler for background refresh
      _scheduler.scheduleRefresh('blocked_apps');
    });
  }

  /// ==================== Schedules Cache ====================

  /// Get schedules from cache
  Future<List<Schedule>> getSchedules() async {
    if (_cachedSchedules != null) {
      return _cachedSchedules!;
    }
    return await _loadSchedules();
  }

  /// Force refresh schedules cache
  Future<void> refreshSchedules() async {
    _cachedSchedules = null;
    await _loadSchedules();
  }

  Future<List<Schedule>> _loadSchedules() async {
    _cachedSchedules = await _prefsService.getSchedules();
    return _cachedSchedules ?? [];
  }

  /// Save schedules and invalidate cache (immediate for critical data)
  Future<bool> saveSchedules(List<Schedule> schedules) async {
    final result = await _prefsService.saveSchedules(schedules);
    if (result) {
      _cachedSchedules = null;
    }
    return result;
  }

  /// Add schedule
  Future<bool> addSchedule(Schedule schedule) async {
    final result = await _prefsService.addSchedule(schedule);
    if (result) {
      _cachedSchedules = null;
    }
    return result;
  }

  /// Remove schedule
  Future<bool> removeSchedule(String scheduleId) async {
    final result = await _prefsService.removeSchedule(scheduleId);
    if (result) {
      _cachedSchedules = null;
    }
    return result;
  }

  /// ==================== Usage Limits Cache ====================

  /// Get usage limits from cache
  Future<List<AppUsageLimit>> getUsageLimits() async {
    if (_cachedLimits != null) {
      return _cachedLimits!.values.toList();
    }
    return await _loadUsageLimits();
  }

  /// Force refresh usage limits cache
  Future<void> refreshUsageLimits() async {
    _cachedLimits = null;
    await _loadUsageLimits();
  }

  Future<List<AppUsageLimit>> _loadUsageLimits() async {
    final limitsList = await _prefsService.getUsageLimits();
    _cachedLimits = {for (var limit in limitsList) limit.packageName: limit};
    return limitsList;
  }

  /// Save usage limits and invalidate cache
  Future<bool> saveUsageLimits(List<AppUsageLimit> limits) async {
    final result = await _prefsService.saveUsageLimits(limits);
    if (result) {
      _cachedLimits = null;
    }
    return result;
  }

  /// ==================== Focus Lists Cache ====================

  /// Get focus lists from cache
  Future<List<FocusList>> getFocusLists() async {
    if (_cachedFocusLists != null) {
      return _cachedFocusLists!;
    }
    return await _loadFocusLists();
  }

  /// Force refresh focus lists cache
  Future<void> refreshFocusLists() async {
    _cachedFocusLists = null;
    await _loadFocusLists();
  }

  Future<List<FocusList>> _loadFocusLists() async {
    _cachedFocusLists = await _prefsService.getFocusLists();
    return _cachedFocusLists ?? [];
  }

  /// Save focus lists
  Future<bool> saveFocusLists(List<FocusList> lists) async {
    final result = await _prefsService.saveFocusLists(lists);
    if (result) {
      _cachedFocusLists = null;
    }
    return result;
  }

  /// ==================== Focus Sessions Cache ====================

  /// Get focus sessions from cache
  Future<List<dynamic>> getFocusSessions() async {
    if (_cachedFocusSessions != null) {
      return _cachedFocusSessions!;
    }
    return await _loadFocusSessions();
  }

  /// Force refresh focus sessions cache
  Future<void> refreshFocusSessions() async {
    _cachedFocusSessions = null;
    await _loadFocusSessions();
  }

  Future<List<dynamic>> _loadFocusSessions() async {
    _cachedFocusSessions = [];
    return _cachedFocusSessions ?? [];
  }

  /// ==================== Cleanup ====================

  /// Clear all caches (call on app exit or when memory is low)
  void clearAllCaches() {
    _cachedBlockedApps = null;
    _cachedSchedules = null;
    _cachedLimits = null;
    _cachedFocusLists = null;
    _cachedFocusSessions = null;

    _blockedAppsDebounceTimer?.cancel();
    _schedulesDebounceTimer?.cancel();
    _limitsDebounceTimer?.cancel();
    _focusListsDebounceTimer?.cancel();
    _focusSessionsDebounceTimer?.cancel();
  }

  /// Trim caches based on memory pressure
  /// This is called by MemoryPressureListener when system is low on memory
  /// trimRatio: 0.0 = keep all, 1.0 = clear all non-essential
  Future<void> trimMemory(double trimRatio) async {
    // For essential caches (blocked apps, schedules), trim aggressively
    if (trimRatio >= 0.5) {
      _cachedBlockedApps = null;
      _cachedSchedules = null;
      _cachedFocusLists = null;
    } else if (trimRatio >= 0.25) {
      // For moderate pressure, keep essential only
      _cachedFocusLists = null;
      _cachedFocusSessions = null;
    }

    // Always trim limits cache
    if (trimRatio >= 0.1) {
      _cachedLimits = null;
    }

    // Trim non-essential (focus sessions)
    _cachedFocusSessions = null;
  }

  /// Dispose and cancel all timers
  void dispose() {
    clearAllCaches();
    _scheduler.dispose();
  }
}
