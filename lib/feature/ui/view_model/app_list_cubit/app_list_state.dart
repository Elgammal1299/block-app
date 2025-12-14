import 'package:equatable/equatable.dart';
import '../../../data/models/app_info.dart';

abstract class AppListState extends Equatable {
  const AppListState();

  @override
  List<Object> get props => [];
}

class AppListInitial extends AppListState {}

class AppListLoading extends AppListState {}

class AppListLoaded extends AppListState {
  final List<AppInfo> apps;
  final String searchQuery;
  final bool showSystemApps;

  const AppListLoaded({
    required this.apps,
    this.searchQuery = '',
    this.showSystemApps = false,
  });

  @override
  List<Object> get props => [apps, searchQuery, showSystemApps];
}

class AppListError extends AppListState {
  final String message;

  const AppListError(this.message);

  @override
  List<Object> get props => [message];
}
