import 'package:equatable/equatable.dart';
import '../../../data/models/focus_session.dart';

abstract class FocusSessionState extends Equatable {
  const FocusSessionState();

  @override
  List<Object?> get props => [];
}

class FocusSessionInitial extends FocusSessionState {}

class FocusSessionLoading extends FocusSessionState {}

class FocusSessionIdle extends FocusSessionState {}

class FocusSessionActive extends FocusSessionState {
  final FocusSession activeSession;
  final int remainingSeconds;

  const FocusSessionActive(this.activeSession, this.remainingSeconds);

  @override
  List<Object?> get props => [activeSession, remainingSeconds];
}

class FocusSessionCompleted extends FocusSessionState {
  final FocusSession completedSession;

  const FocusSessionCompleted(this.completedSession);

  @override
  List<Object?> get props => [completedSession];
}

class FocusSessionError extends FocusSessionState {
  final String message;

  const FocusSessionError(this.message);

  @override
  List<Object?> get props => [message];
}
