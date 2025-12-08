import 'package:flutter/material.dart';
import '../data/models/app_info.dart';
import '../data/repositories/app_repository.dart';

class AppListProvider extends ChangeNotifier {
  final AppRepository _appRepository;
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showSystemApps = false;

  AppListProvider(this._appRepository);

  List<AppInfo> get apps => _filteredApps;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get showSystemApps => _showSystemApps;

  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    _allApps = await _appRepository.getInstalledApps();
    _filterApps();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterApps();
    notifyListeners();
  }

  void toggleShowSystemApps() {
    _showSystemApps = !_showSystemApps;
    _filterApps();
    notifyListeners();
  }

  void _filterApps() {
    _filteredApps = _allApps.where((app) {
      // Filter by system apps
      if (!_showSystemApps && app.isSystemApp) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
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
