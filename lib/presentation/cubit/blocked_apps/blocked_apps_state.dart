import 'package:equatable/equatable.dart';
import '../../../data/models/blocked_app.dart';

abstract class BlockedAppsState extends Equatable {
  const BlockedAppsState();

  @override
  List<Object> get props => [];
}

class BlockedAppsInitial extends BlockedAppsState {}

class BlockedAppsLoading extends BlockedAppsState {}

class BlockedAppsLoaded extends BlockedAppsState {
  final List<BlockedApp> blockedApps;

  const BlockedAppsLoaded(this.blockedApps);

  @override
  List<Object> get props => [blockedApps];

  int get totalBlockedApps => blockedApps.where((app) => app.isBlocked).length;

  int get totalBlockAttempts {
    return blockedApps.fold(0, (sum, app) => sum + app.blockAttempts);
  }
}

class BlockedAppsError extends BlockedAppsState {
  final String message;

  const BlockedAppsError(this.message);

  @override
  List<Object> get props => [message];
}
