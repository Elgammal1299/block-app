import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/daily_goal_repository.dart';
import 'daily_goal_state.dart';

class DailyGoalCubit extends Cubit<DailyGoalState> {
  final DailyGoalRepository _repository;

  DailyGoalCubit(this._repository) : super(const DailyGoalInitial());

  Future<void> loadDailyGoal() async {
    try {
      emit(const DailyGoalLoading());
      final goal = await _repository.getTodayGoal();
      emit(DailyGoalLoaded(goal));
    } catch (e) {
      emit(DailyGoalError('فشل تحميل الهدف اليومي: $e'));
    }
  }

  Future<void> updateDailyGoal(int targetMinutes) async {
    try {
      await _repository.setDailyGoal(targetMinutes);
      await loadDailyGoal();
    } catch (e) {
      emit(DailyGoalError('فشل تحديث الهدف: $e'));
    }
  }

  Future<void> updateProgress(int additionalMinutes) async {
    try {
      await _repository.updateProgress(additionalMinutes);
      await loadDailyGoal();
    } catch (e) {
      emit(DailyGoalError('فشل تحديث التقدم: $e'));
    }
  }

  Future<bool> checkGoalAchieved() async {
    try {
      return await _repository.checkGoalAchieved();
    } catch (e) {
      return false;
    }
  }
}
