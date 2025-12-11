import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/app_info.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../core/utils/isolate_helper.dart';
import 'app_list_state.dart';

class AppListCubit extends Cubit<AppListState> {
  final AppRepository _appRepository;
  List<AppInfo> _allApps = [];
  bool _isAppsLoaded = false;

  AppListCubit(this._appRepository) : super(AppListInitial());

  Future<void> loadInstalledApps() async {
    // If apps are already loaded, just filter and emit
    if (_isAppsLoaded && _allApps.isNotEmpty) {
      emit(AppListLoading());
      final filteredApps = await _filterAppsInIsolate(_allApps, '', false);
      emit(AppListLoaded(apps: filteredApps));
      return;
    }

    // Emit loading immediately so UI shows loading indicator
    emit(AppListLoading());

    try {
      // Get apps from native - this might take time but won't freeze UI
      // because we already emitted loading state
      _allApps = await _appRepository.getInstalledApps();
      _isAppsLoaded = true;

      // Use isolate for filtering to avoid blocking UI
      final filteredApps = await _filterAppsInIsolate(_allApps, '', false);

      emit(AppListLoaded(apps: filteredApps));
    } catch (e) {
      emit(AppListError(e.toString()));
    }
  }

  Future<void> setSearchQuery(String query) async {
    if (state is AppListLoaded) {
      final currentState = state as AppListLoaded;

      // Use isolate for filtering
      final filteredApps = await _filterAppsInIsolate(
        _allApps,
        query,
        currentState.showSystemApps,
      );

      emit(AppListLoaded(
        apps: filteredApps,
        searchQuery: query,
        showSystemApps: currentState.showSystemApps,
      ));
    }
  }

  Future<void> toggleShowSystemApps() async {
    if (state is AppListLoaded) {
      final currentState = state as AppListLoaded;
      final newValue = !currentState.showSystemApps;

      // Use isolate for filtering
      final filteredApps = await _filterAppsInIsolate(
        _allApps,
        currentState.searchQuery,
        newValue,
      );

      emit(AppListLoaded(
        apps: filteredApps,
        searchQuery: currentState.searchQuery,
        showSystemApps: newValue,
      ));
    }
  }

  /// Filter apps using isolate for better performance
  Future<List<AppInfo>> _filterAppsInIsolate(
    List<AppInfo> apps,
    String searchQuery,
    bool showSystemApps,
  ) async {
    // Convert to Map for isolate
    final appsMap = apps.map((app) => {
      'packageName': app.packageName,
      'appName': app.appName,
      'isSystemApp': app.isSystemApp,
    }).toList();

    final params = {
      'apps': appsMap,
      'searchQuery': searchQuery,
      'showSystemApps': showSystemApps,
    };

    // Run filtering in isolate
    final filteredMaps = await compute(IsolateHelper.filterAppsInIsolate, params);

    // Convert back to AppInfo, keeping original icons
    final packageToApp = {for (var app in apps) app.packageName: app};
    return filteredMaps
        .map((map) => packageToApp[map['packageName']] as AppInfo)
        .toList();
  }

  void refresh() {
    loadInstalledApps();
  }
}
