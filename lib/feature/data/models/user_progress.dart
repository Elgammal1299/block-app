import 'achievement.dart';

class UserProgress {
  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int completedSessions;
  final List<Achievement> achievements;
  final DateTime lastActivityDate;

  UserProgress({
    this.totalXP = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.achievements = const [],
    DateTime? lastActivityDate,
  }) : lastActivityDate = lastActivityDate ?? DateTime.now();

  int get xpToNextLevel => level * 100;

  int get currentLevelXP {
    int totalXPForPreviousLevels = 0;
    for (int i = 1; i < level; i++) {
      totalXPForPreviousLevels += i * 100;
    }
    return totalXP - totalXPForPreviousLevels;
  }

  double get levelProgress {
    if (xpToNextLevel == 0) return 0.0;
    return (currentLevelXP / xpToNextLevel).clamp(0.0, 1.0);
  }

  List<Achievement> get unlockedAchievements {
    return achievements.where((a) => a.isUnlocked).toList();
  }

  int get unlockedAchievementsCount => unlockedAchievements.length;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final achievementsList = (json['achievements'] as List<dynamic>?)
            ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return UserProgress(
      totalXP: json['totalXP'] ?? 0,
      level: json['level'] ?? 1,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      completedSessions: json['completedSessions'] ?? 0,
      achievements: achievementsList,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'lastActivityDate': lastActivityDate.toIso8601String(),
    };
  }

  UserProgress copyWith({
    int? totalXP,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? totalSessions,
    int? completedSessions,
    List<Achievement>? achievements,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      achievements: achievements ?? this.achievements,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  @override
  String toString() {
    return 'UserProgress(level: $level, XP: $totalXP, streak: $currentStreak, sessions: $completedSessions/$totalSessions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.totalXP == totalXP &&
        other.level == level &&
        other.currentStreak == currentStreak &&
        other.completedSessions == completedSessions;
  }

  @override
  int get hashCode {
    return totalXP.hashCode ^
        level.hashCode ^
        currentStreak.hashCode ^
        completedSessions.hashCode;
  }
}
