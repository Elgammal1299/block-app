import 'package:equatable/equatable.dart';
import 'app_usage_stats.dart';

/// Enum for different comparison modes
enum ComparisonMode {
  todayVsYesterday,
  thisWeekVsLastWeek,
  peakDay,
}

/// Extension for ComparisonMode display labels
extension ComparisonModeExtension on ComparisonMode {
  String get label {
    switch (this) {
      case ComparisonMode.todayVsYesterday:
        return 'Today vs Yesterday';
      case ComparisonMode.thisWeekVsLastWeek:
        return 'Week Comparison';
      case ComparisonMode.peakDay:
        return 'Peak Day';
    }
  }

  String get shortLabel {
    switch (this) {
      case ComparisonMode.todayVsYesterday:
        return 'Daily';
      case ComparisonMode.thisWeekVsLastWeek:
        return 'Weekly';
      case ComparisonMode.peakDay:
        return 'Peak';
    }
  }
}

/// Model representing statistics for a specific time period
class PeriodStats extends Equatable {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final int totalScreenTimeMillis;
  final List<AppUsageStats> topApps;
  final int totalBlockAttempts;

  const PeriodStats({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.totalScreenTimeMillis,
    required this.topApps,
    required this.totalBlockAttempts,
  });

  /// Get total screen time in minutes
  int get totalScreenTimeMinutes => totalScreenTimeMillis ~/ 60000;

  /// Get total screen time in hours (double)
  double get totalScreenTimeHours => totalScreenTimeMillis / 3600000;

  /// Get formatted total time string (e.g., "2h 30m")
  String get formattedTotalTime {
    if (totalScreenTimeMillis == 0) return '0m';

    final hours = totalScreenTimeMillis ~/ 3600000;
    final minutes = (totalScreenTimeMillis % 3600000) ~/ 60000;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  @override
  List<Object?> get props => [
        label,
        startDate,
        endDate,
        totalScreenTimeMillis,
        topApps,
        totalBlockAttempts,
      ];
}

/// Model representing comparison statistics between two periods
class ComparisonStats extends Equatable {
  final ComparisonMode mode;
  final PeriodStats currentPeriod;
  final PeriodStats? previousPeriod; // For normal comparisons
  final PeriodStats? peakPeriod; // For peak day mode

  const ComparisonStats({
    required this.mode,
    required this.currentPeriod,
    this.previousPeriod,
    this.peakPeriod,
  });

  /// Get the comparison period (previous or peak)
  PeriodStats? get comparisonPeriod {
    if (mode == ComparisonMode.peakDay) {
      return peakPeriod;
    }
    return previousPeriod;
  }

  /// Calculate time difference in milliseconds
  int get timeDifference {
    final comparison = comparisonPeriod;
    if (comparison == null) return 0;
    return currentPeriod.totalScreenTimeMillis - comparison.totalScreenTimeMillis;
  }

  /// Calculate percentage change
  double get percentageChange {
    final comparison = comparisonPeriod;
    if (comparison == null || comparison.totalScreenTimeMillis == 0) return 0;

    return (timeDifference / comparison.totalScreenTimeMillis) * 100;
  }

  /// Check if usage increased
  bool get isIncrease => timeDifference > 0;

  /// Check if usage decreased
  bool get isDecrease => timeDifference < 0;

  /// Check if usage stayed the same
  bool get isSame => timeDifference == 0;

  /// Get formatted comparison label (e.g., "25.5% more", "15.2% less")
  String get comparisonLabel {
    if (isSame) return 'Same usage';

    final absChange = percentageChange.abs().toStringAsFixed(1);
    final direction = isIncrease ? 'more' : 'less';
    return '$absChange% $direction';
  }

  /// Get formatted time difference (e.g., "+1h 30m", "-45m")
  String get formattedTimeDifference {
    if (isSame) return '0m';

    final absDiff = timeDifference.abs();
    final hours = absDiff ~/ 3600000;
    final minutes = (absDiff % 3600000) ~/ 60000;

    final sign = isIncrease ? '+' : '-';

    if (hours > 0 && minutes > 0) {
      return '$sign${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '$sign${hours}h';
    } else if (minutes > 0) {
      return '$sign${minutes}m';
    } else {
      return '$sign<1m';
    }
  }

  /// Get block attempts difference
  int get blockAttemptsDifference {
    final comparison = comparisonPeriod;
    if (comparison == null) return 0;
    return currentPeriod.totalBlockAttempts - comparison.totalBlockAttempts;
  }

  /// Get comparison title based on mode
  String get comparisonTitle {
    switch (mode) {
      case ComparisonMode.todayVsYesterday:
        return 'Today vs Yesterday';
      case ComparisonMode.thisWeekVsLastWeek:
        return 'This Week vs Last Week';
      case ComparisonMode.peakDay:
        return 'Today vs Peak Day';
    }
  }

  @override
  List<Object?> get props => [
        mode,
        currentPeriod,
        previousPeriod,
        peakPeriod,
      ];
}
