import 'package:flutter/material.dart';
import '../data/models/blocked_app.dart';
import '../data/repositories/app_repository.dart';

class BlockedAppsProvider extends ChangeNotifier {
  final AppRepository _appRepository;
  List<BlockedApp> _blockedApps = [];
  bool _isLoading = false;

  BlockedAppsProvider(this._appRepository) {
    loadBlockedApps();
  }

  List<BlockedApp> get blockedApps => _blockedApps;
  bool get isLoading => _isLoading;

  Future<void> loadBlockedApps() async {
    _isLoading = true;
    notifyListeners();

    _blockedApps = await _appRepository.getBlockedApps();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBlockedApp(BlockedApp app) async {
    final result = await _appRepository.addBlockedApp(app);
    if (result) {
      _blockedApps.add(app);
      notifyListeners();
    }
    return result;
  }

  Future<bool> removeBlockedApp(String packageName) async {
    final result = await _appRepository.removeBlockedApp(packageName);
    if (result) {
      _blockedApps.removeWhere((app) => app.packageName == packageName);
      notifyListeners();
    }
    return result;
  }

  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final result = await _appRepository.saveBlockedApps(apps);
    if (result) {
      _blockedApps = apps;
      notifyListeners();
    }
    return result;
  }

  bool isBlocked(String packageName) {
    return _blockedApps.any((app) => app.packageName == packageName && app.isBlocked);
  }

  int getBlockAttempts(String packageName) {
    final app = _blockedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => BlockedApp(packageName: packageName, appName: ''),
    );
    return app.blockAttempts;
  }

  int get totalBlockedApps => _blockedApps.where((app) => app.isBlocked).length;

  int get totalBlockAttempts {
    return _blockedApps.fold(0, (sum, app) => sum + app.blockAttempts);
  }
}
