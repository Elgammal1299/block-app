import 'package:equatable/equatable.dart';
import '../../../data/models/schedule.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<Schedule> schedules;

  const ScheduleLoaded(this.schedules);

  @override
  List<Object> get props => [schedules];

  List<Schedule> get enabledSchedules =>
      schedules.where((s) => s.isEnabled).toList();

  bool isCurrentlyInSchedule() {
    final now = DateTime.now();
    return schedules.any((schedule) => schedule.isActiveAt(now));
  }
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object> get props => [message];
}
