class StatisticsModel {
  final int blockedAppsCount;
  final Duration? todayFocusTime;
  final int blockedAttempts;
  final double dailyGoalProgress;
  final int totalFocusSessions;
  final Duration averageSessionDuration;
  final DateTime lastUpdated;

  StatisticsModel({
    required this.blockedAppsCount,
    this.todayFocusTime,
    required this.blockedAttempts,
    this.dailyGoalProgress = 0.0,
    this.totalFocusSessions = 0,
    this.averageSessionDuration = Duration.zero,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      blockedAppsCount: json['blockedAppsCount'] ?? 0,
      todayFocusTime: json['todayFocusTime'] != null 
          ? Duration(minutes: json['todayFocusTime'])
          : null,
      blockedAttempts: json['blockedAttempts'] ?? 0,
      dailyGoalProgress: (json['dailyGoalProgress'] ?? 0.0).toDouble(),
      totalFocusSessions: json['totalFocusSessions'] ?? 0,
      averageSessionDuration: Duration(
        minutes: json['averageSessionDuration'] ?? 0,
      ),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockedAppsCount': blockedAppsCount,
      'todayFocusTime': todayFocusTime?.inMinutes,
      'blockedAttempts': blockedAttempts,
      'dailyGoalProgress': dailyGoalProgress,
      'totalFocusSessions': totalFocusSessions,
      'averageSessionDuration': averageSessionDuration.inMinutes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  StatisticsModel copyWith({
    int? blockedAppsCount,
    Duration? todayFocusTime,
    int? blockedAttempts,
    double? dailyGoalProgress,
    int? totalFocusSessions,
    Duration? averageSessionDuration,
    DateTime? lastUpdated,
  }) {
    return StatisticsModel(
      blockedAppsCount: blockedAppsCount ?? this.blockedAppsCount,
      todayFocusTime: todayFocusTime ?? this.todayFocusTime,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
      totalFocusSessions: totalFocusSessions ?? this.totalFocusSessions,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'StatisticsModel('
        'blockedAppsCount: $blockedAppsCount, '
        'todayFocusTime: $todayFocusTime, '
        'blockedAttempts: $blockedAttempts, '
        'dailyGoalProgress: $dailyGoalProgress, '
        'totalFocusSessions: $totalFocusSessions, '
        'averageSessionDuration: $averageSessionDuration, '
        'lastUpdated: $lastUpdated'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatisticsModel &&
        other.blockedAppsCount == blockedAppsCount &&
        other.todayFocusTime == todayFocusTime &&
        other.blockedAttempts == blockedAttempts &&
        other.dailyGoalProgress == dailyGoalProgress &&
        other.totalFocusSessions == totalFocusSessions &&
        other.averageSessionDuration == averageSessionDuration &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return blockedAppsCount.hashCode ^
        todayFocusTime.hashCode ^
        blockedAttempts.hashCode ^
        dailyGoalProgress.hashCode ^
        totalFocusSessions.hashCode ^
        averageSessionDuration.hashCode ^
        lastUpdated.hashCode;
  }
}
