import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/blocked_app.dart';
import '../../../data/repositories/app_repository.dart';
import 'blocked_apps_state.dart';

class BlockedAppsCubit extends Cubit<BlockedAppsState> {
  final AppRepository _appRepository;

  BlockedAppsCubit(this._appRepository) : super(BlockedAppsInitial()) {
    loadBlockedApps();
  }

  Future<void> loadBlockedApps() async {
    emit(BlockedAppsLoading());
    try {
      final blockedApps = await _appRepository.getBlockedApps();
      emit(BlockedAppsLoaded(blockedApps));
    } catch (e) {
      emit(BlockedAppsError(e.toString()));
    }
  }

  Future<bool> addBlockedApp(BlockedApp app) async {
    if (state is! BlockedAppsLoaded) return false;

    final currentState = state as BlockedAppsLoaded;
    final result = await _appRepository.addBlockedApp(app);

    if (result) {
      final updatedApps = List<BlockedApp>.from(currentState.blockedApps)..add(app);
      emit(BlockedAppsLoaded(updatedApps));
    }

    return result;
  }

  Future<bool> removeBlockedApp(String packageName) async {
    if (state is! BlockedAppsLoaded) return false;

    final currentState = state as BlockedAppsLoaded;
    final result = await _appRepository.removeBlockedApp(packageName);

    if (result) {
      final updatedApps = List<BlockedApp>.from(currentState.blockedApps)
        ..removeWhere((app) => app.packageName == packageName);
      emit(BlockedAppsLoaded(updatedApps));
    }

    return result;
  }

  Future<bool> saveBlockedApps(List<BlockedApp> apps) async {
    final result = await _appRepository.saveBlockedApps(apps);

    if (result) {
      emit(BlockedAppsLoaded(apps));
    }

    return result;
  }

  bool isBlocked(String packageName) {
    if (state is BlockedAppsLoaded) {
      final currentState = state as BlockedAppsLoaded;
      return currentState.blockedApps
          .any((app) => app.packageName == packageName && app.isBlocked);
    }
    return false;
  }

  int getBlockAttempts(String packageName) {
    if (state is BlockedAppsLoaded) {
      final currentState = state as BlockedAppsLoaded;
      final app = currentState.blockedApps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => BlockedApp(packageName: packageName, appName: ''),
      );
      return app.blockAttempts;
    }
    return 0;
  }
}
