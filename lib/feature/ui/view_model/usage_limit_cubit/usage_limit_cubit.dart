import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_usage_limit.dart';
import '../../../data/repositories/app_repository.dart';
import 'usage_limit_state.dart';

class UsageLimitCubit extends Cubit<UsageLimitState> {
  final AppRepository _appRepository;

  UsageLimitCubit(this._appRepository) : super(UsageLimitInitial()) {
    loadUsageLimits();
  }

  /// Load all usage limits
  Future<void> loadUsageLimits() async {
    emit(UsageLimitLoading());
    try {
      final limits = await _appRepository.getUsageLimits();

      // Check and reset limits if needed (new day)
      final updatedLimits = <AppUsageLimit>[];
      bool needsSave = false;

      for (var limit in limits) {
        if (limit.needsReset()) {
          updatedLimits.add(limit.reset());
          needsSave = true;
        } else {
          updatedLimits.add(limit);
        }
      }

      // Save if any limits were reset
      if (needsSave) {
        await _appRepository.saveUsageLimits(updatedLimits);
      }

      emit(UsageLimitLoaded(updatedLimits));
    } catch (e) {
      emit(UsageLimitError(e.toString()));
    }
  }

  /// Add or update a usage limit
  Future<bool> setUsageLimit(AppUsageLimit limit) async {
    if (state is! UsageLimitLoaded) return false;

    try {
      final currentState = state as UsageLimitLoaded;
      final limits = List<AppUsageLimit>.from(currentState.limits);

      // Remove existing limit for this app if any
      limits.removeWhere((l) => l.packageName == limit.packageName);

      // Add new limit
      limits.add(limit);

      // Save to repository
      final result = await _appRepository.saveUsageLimits(limits);

      if (result) {
        emit(UsageLimitLoaded(limits));
      }

      return result;
    } catch (e) {
      emit(UsageLimitError(e.toString()));
      return false;
    }
  }

  /// Remove a usage limit
  Future<bool> removeUsageLimit(String packageName) async {
    if (state is! UsageLimitLoaded) return false;

    try {
      final currentState = state as UsageLimitLoaded;
      final limits = List<AppUsageLimit>.from(currentState.limits);

      limits.removeWhere((l) => l.packageName == packageName);

      final result = await _appRepository.saveUsageLimits(limits);

      if (result) {
        emit(UsageLimitLoaded(limits));
      }

      return result;
    } catch (e) {
      emit(UsageLimitError(e.toString()));
      return false;
    }
  }

  /// Add usage time to an app
  Future<void> addUsageTime(String packageName, int minutes) async {
    if (state is! UsageLimitLoaded) return;

    try {
      final currentState = state as UsageLimitLoaded;
      final limits = List<AppUsageLimit>.from(currentState.limits);

      final index = limits.indexWhere((l) => l.packageName == packageName);
      if (index != -1) {
        limits[index] = limits[index].addUsage(minutes);

        await _appRepository.saveUsageLimits(limits);
        emit(UsageLimitLoaded(limits));
      }
    } catch (e) {
      emit(UsageLimitError(e.toString()));
    }
  }

  /// Get a specific usage limit
  AppUsageLimit? getLimit(String packageName) {
    if (state is UsageLimitLoaded) {
      final currentState = state as UsageLimitLoaded;
      try {
        final result = currentState.limits.firstWhere(
          (l) => l.packageName == packageName,
          orElse: () =>
              AppUsageLimit(packageName: '', appName: '', dailyLimitMinutes: 0),
        );
        return result.packageName.isEmpty ? null : result;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if an app has reached its limit
  bool isLimitReached(String packageName) {
    final limit = getLimit(packageName);
    return limit?.isLimitReached ?? false;
  }
}
