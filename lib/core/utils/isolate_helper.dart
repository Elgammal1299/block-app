/// Helper class for running heavy computations in isolates
class IsolateHelper {
  /// Filter apps list in isolate (top-level function for compute)
  static List<Map<String, dynamic>> filterAppsInIsolate(
    Map<String, dynamic> params,
  ) {
    final List<Map<String, dynamic>> apps =
        List<Map<String, dynamic>>.from(params['apps'] as List);
    final String searchQuery = params['searchQuery'] as String;
    final bool showSystemApps = params['showSystemApps'] as bool;

    return apps.where((app) {
      // Filter by system apps
      if (!showSystemApps && (app['isSystemApp'] as bool? ?? false)) {
        return false;
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final appName = (app['appName'] as String? ?? '').toLowerCase();
        final packageName = (app['packageName'] as String? ?? '').toLowerCase();
        return appName.contains(query) || packageName.contains(query);
      }

      return true;
    }).toList();
  }

  /// Sort apps list in isolate
  static List<Map<String, dynamic>> sortAppsInIsolate(
    List<Map<String, dynamic>> apps,
  ) {
    final sortedApps = List<Map<String, dynamic>>.from(apps);
    sortedApps.sort((a, b) {
      final aName = (a['appName'] as String? ?? '').toLowerCase();
      final bName = (b['appName'] as String? ?? '').toLowerCase();
      return aName.compareTo(bName);
    });
    return sortedApps;
  }
}
