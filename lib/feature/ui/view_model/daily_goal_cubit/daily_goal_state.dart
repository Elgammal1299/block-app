import '../../../data/models/daily_goal.dart';

abstract class DailyGoalState {
  const DailyGoalState();
}

class DailyGoalInitial extends DailyGoalState {
  const DailyGoalInitial();
}

class DailyGoalLoading extends DailyGoalState {
  const DailyGoalLoading();
}

class DailyGoalLoaded extends DailyGoalState {
  final DailyGoal goal;

  const DailyGoalLoaded(this.goal);
}

class DailyGoalError extends DailyGoalState {
  final String message;

  const DailyGoalError(this.message);
}
