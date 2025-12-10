import 'package:equatable/equatable.dart';
import '../../../data/models/app_usage_stats.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final List<AppUsageStats> dailyStats;
  final List<AppUsageStats> weeklyStats;

  const StatisticsLoaded({
    required this.dailyStats,
    required this.weeklyStats,
  });

  @override
  List<Object> get props => [dailyStats, weeklyStats];

  int get totalDailyScreenTime {
    return dailyStats.fold(0, (sum, stat) => sum + stat.totalTimeInMillis);
  }

  int get totalWeeklyScreenTime {
    return weeklyStats.fold(0, (sum, stat) => sum + stat.totalTimeInMillis);
  }

  String get totalDailyScreenTimeFormatted {
    final hours = (totalDailyScreenTime / 3600000).floor();
    final minutes = ((totalDailyScreenTime % 3600000) / 60000).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get totalWeeklyScreenTimeFormatted {
    final hours = (totalWeeklyScreenTime / 3600000).floor();
    final minutes = ((totalWeeklyScreenTime % 3600000) / 60000).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
