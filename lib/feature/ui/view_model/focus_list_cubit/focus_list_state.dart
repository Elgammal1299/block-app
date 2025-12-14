import 'package:equatable/equatable.dart';
import '../../../data/models/focus_list.dart';

abstract class FocusListState extends Equatable {
  const FocusListState();

  @override
  List<Object?> get props => [];
}

class FocusListInitial extends FocusListState {}

class FocusListLoading extends FocusListState {}

class FocusListLoaded extends FocusListState {
  final List<FocusList> focusLists;

  const FocusListLoaded(this.focusLists);

  @override
  List<Object?> get props => [focusLists];
}

class FocusListError extends FocusListState {
  final String message;

  const FocusListError(this.message);

  @override
  List<Object?> get props => [message];
}
