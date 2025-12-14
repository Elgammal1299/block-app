import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/schedule.dart';
import '../../../data/repositories/settings_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final SettingsRepository _settingsRepository;

  ScheduleCubit(this._settingsRepository) : super(ScheduleInitial()) {
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    emit(ScheduleLoading());
    try {
      final schedules = await _settingsRepository.getSchedules();
      emit(ScheduleLoaded(schedules));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }

  Future<bool> addSchedule(Schedule schedule) async {
    if (state is! ScheduleLoaded) return false;

    final currentState = state as ScheduleLoaded;
    final result = await _settingsRepository.addSchedule(schedule);

    if (result) {
      final updatedSchedules = List<Schedule>.from(currentState.schedules)..add(schedule);
      emit(ScheduleLoaded(updatedSchedules));
    }

    return result;
  }

  Future<bool> updateSchedule(Schedule schedule) async {
    if (state is! ScheduleLoaded) return false;

    final currentState = state as ScheduleLoaded;
    final result = await _settingsRepository.updateSchedule(schedule);

    if (result) {
      final updatedSchedules = List<Schedule>.from(currentState.schedules);
      final index = updatedSchedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        updatedSchedules[index] = schedule;
        emit(ScheduleLoaded(updatedSchedules));
      }
    }

    return result;
  }

  Future<bool> removeSchedule(String scheduleId) async {
    if (state is! ScheduleLoaded) return false;

    final currentState = state as ScheduleLoaded;
    final result = await _settingsRepository.removeSchedule(scheduleId);

    if (result) {
      final updatedSchedules = List<Schedule>.from(currentState.schedules)
        ..removeWhere((s) => s.id == scheduleId);
      emit(ScheduleLoaded(updatedSchedules));
    }

    return result;
  }

  Future<bool> toggleSchedule(String scheduleId) async {
    if (state is! ScheduleLoaded) return false;

    final currentState = state as ScheduleLoaded;
    final result = await _settingsRepository.toggleSchedule(scheduleId);

    if (result) {
      final updatedSchedules = List<Schedule>.from(currentState.schedules);
      final index = updatedSchedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        updatedSchedules[index] = updatedSchedules[index].copyWith(
          isEnabled: !updatedSchedules[index].isEnabled,
        );
        emit(ScheduleLoaded(updatedSchedules));
      }
    }

    return result;
  }
}
