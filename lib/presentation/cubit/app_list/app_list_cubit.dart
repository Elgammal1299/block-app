import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_info.dart';
import '../../../data/repositories/app_repository.dart';
import 'app_list_state.dart';

class AppListCubit extends Cubit<AppListState> {
  final AppRepository _appRepository;
  List<AppInfo> _allApps = [];

  AppListCubit(this._appRepository) : super(AppListInitial());

  Future<void> loadInstalledApps() async {
    emit(AppListLoading());
    try {
      _allApps = await _appRepository.getInstalledApps();
      final filteredApps = _filterApps(_allApps, '', false);
      emit(AppListLoaded(apps: filteredApps));
    } catch (e) {
      emit(AppListError(e.toString()));
    }
  }

  void setSearchQuery(String query) {
    if (state is AppListLoaded) {
      final currentState = state as AppListLoaded;
      final filteredApps = _filterApps(
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

  void toggleShowSystemApps() {
    if (state is AppListLoaded) {
      final currentState = state as AppListLoaded;
      final newValue = !currentState.showSystemApps;
      final filteredApps = _filterApps(
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

  List<AppInfo> _filterApps(
    List<AppInfo> apps,
    String searchQuery,
    bool showSystemApps,
  ) {
    return apps.where((app) {
      // Filter by system apps
      if (!showSystemApps && app.isSystemApp) {
        return false;
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return app.appName.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void refresh() {
    loadInstalledApps();
  }
}
