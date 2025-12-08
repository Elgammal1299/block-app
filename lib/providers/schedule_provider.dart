import 'package:flutter/material.dart';
import '../data/models/schedule.dart';
import '../data/repositories/settings_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  List<Schedule> _schedules = [];
  bool _isLoading = false;

  ScheduleProvider(this._settingsRepository) {
    loadSchedules();
  }

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  List<Schedule> get enabledSchedules =>
      _schedules.where((s) => s.isEnabled).toList();

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();

    _schedules = await _settingsRepository.getSchedules();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSchedule(Schedule schedule) async {
    final result = await _settingsRepository.addSchedule(schedule);
    if (result) {
      _schedules.add(schedule);
      notifyListeners();
    }
    return result;
  }

  Future<bool> updateSchedule(Schedule schedule) async {
    final result = await _settingsRepository.updateSchedule(schedule);
    if (result) {
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
        notifyListeners();
      }
    }
    return result;
  }

  Future<bool> removeSchedule(String scheduleId) async {
    final result = await _settingsRepository.removeSchedule(scheduleId);
    if (result) {
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
    }
    return result;
  }

  Future<bool> toggleSchedule(String scheduleId) async {
    final result = await _settingsRepository.toggleSchedule(scheduleId);
    if (result) {
      final index = _schedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        _schedules[index] =
            _schedules[index].copyWith(isEnabled: !_schedules[index].isEnabled);
        notifyListeners();
      }
    }
    return result;
  }

  bool isCurrentlyInSchedule() {
    final now = DateTime.now();
    return _schedules.any((schedule) => schedule.isActiveAt(now));
  }
}
