import 'package:app_block/core/utils/app_logger.dart';

/// Phase 3: Differential Cache Updates
/// 
/// Instead of full cache refresh on every change, compute what actually changed
/// and only update those parts. This reduces unnecessary re-parsing and re-computation.
/// 
/// Example: If 1 blocked app out of 50 changed, only update that one instead of
/// re-parsing all 50.
class DifferentialCacheUpdater {
  /// Compute differential updates for lists
  /// Returns only the items that changed
  static DifferentialUpdate<T> computeListDifferences<T>({
    required List<T> oldList,
    required List<T> newList,
    required dynamic Function(T) getId,
    required bool Function(T, T) isEqual,
  }) {
    final oldMap = {for (var item in oldList) getId(item): item};
    final newMap = {for (var item in newList) getId(item): item};

    final added = <T>[];
    final removed = <T>[];
    final updated = <T>[];
    final unchanged = <T>[];

    // Find added and updated items
    for (final newItem in newList) {
      final id = getId(newItem);
      final oldItem = oldMap[id];

      if (oldItem == null) {
        added.add(newItem);
      } else if (!isEqual(oldItem, newItem)) {
        updated.add(newItem);
      } else {
        unchanged.add(newItem);
      }
    }

    // Find removed items
    for (final oldItem in oldList) {
      final id = getId(oldItem);
      if (!newMap.containsKey(id)) {
        removed.add(oldItem);
      }
    }

    return DifferentialUpdate(
      added: added,
      removed: removed,
      updated: updated,
      unchanged: unchanged,
      hasChanges: added.isNotEmpty || removed.isNotEmpty || updated.isNotEmpty,
    );
  }

  /// Compute differential updates for maps
  static DifferentialMapUpdate<K, V> computeMapDifferences<K, V>({
    required Map<K, V> oldMap,
    required Map<K, V> newMap,
    required bool Function(V, V) isEqual,
  }) {
    final added = <K, V>{};
    final removed = <K, V>{};
    final updated = <K, V>{};
    final unchanged = <K, V>{};

    // Find added and updated entries
    for (final entry in newMap.entries) {
      final oldValue = oldMap[entry.key];

      if (oldValue == null) {
        added[entry.key] = entry.value;
      } else if (!isEqual(oldValue, entry.value)) {
        updated[entry.key] = entry.value;
      } else {
        unchanged[entry.key] = entry.value;
      }
    }

    // Find removed entries
    for (final entry in oldMap.entries) {
      if (!newMap.containsKey(entry.key)) {
        removed[entry.key] = entry.value;
      }
    }

    return DifferentialMapUpdate(
      added: added,
      removed: removed,
      updated: updated,
      unchanged: unchanged,
      hasChanges:
          added.isNotEmpty || removed.isNotEmpty || updated.isNotEmpty,
    );
  }

  /// Log differential update for debugging
  static void logDifferences<T>(DifferentialUpdate<T> update) {
    if (update.hasChanges) {
      AppLogger.i(
        'Differential update: '
        '+${update.added.length} '
        '-${update.removed.length} '
        '~${update.updated.length} '
        '=${update.unchanged.length}',
      );
    }
  }

  /// Log differential map update for debugging
  static void logMapDifferences<K, V>(DifferentialMapUpdate<K, V> update) {
    if (update.hasChanges) {
      AppLogger.i(
        'Differential map update: '
        '+${update.added.length} '
        '-${update.removed.length} '
        '~${update.updated.length} '
        '=${update.unchanged.length}',
      );
    }
  }
}

/// Result of list differential computation
class DifferentialUpdate<T> {
  final List<T> added;
  final List<T> removed;
  final List<T> updated;
  final List<T> unchanged;
  final bool hasChanges;

  DifferentialUpdate({
    required this.added,
    required this.removed,
    required this.updated,
    required this.unchanged,
    required this.hasChanges,
  });

  /// Get all changed items (added + removed + updated)
  List<T> getAllChanged() => [...added, ...removed, ...updated];

  /// Merge new items into old list intelligently
  List<T> mergeChanges(List<T> oldList) {
    if (!hasChanges) return oldList;
    return [...unchanged, ...added, ...updated];
  }
}

/// Result of map differential computation
class DifferentialMapUpdate<K, V> {
  final Map<K, V> added;
  final Map<K, V> removed;
  final Map<K, V> updated;
  final Map<K, V> unchanged;
  final bool hasChanges;

  DifferentialMapUpdate({
    required this.added,
    required this.removed,
    required this.updated,
    required this.unchanged,
    required this.hasChanges,
  });

  /// Get all changed entries
  Map<K, V> getAllChanged() => {...added, ...removed, ...updated};

  /// Merge new items into old map intelligently
  Map<K, V> mergeChanges(Map<K, V> oldMap) {
    if (!hasChanges) return oldMap;
    final merged = Map<K, V>.from(unchanged);
    merged.addAll(added);
    merged.addAll(updated);
    return merged;
  }
}
