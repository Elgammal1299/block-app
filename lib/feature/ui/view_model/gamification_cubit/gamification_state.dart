import '../../../data/models/user_progress.dart';
import '../../../data/models/achievement.dart';

abstract class GamificationState {
  const GamificationState();
}

class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

class GamificationLoaded extends GamificationState {
  final UserProgress userProgress;

  const GamificationLoaded(this.userProgress);

  int get totalXP => userProgress.totalXP;
  int get level => userProgress.level;
  int get currentStreak => userProgress.currentStreak;
  List<Achievement> get achievements => userProgress.achievements;
  List<Achievement> get unlockedAchievements => userProgress.unlockedAchievements;
}

class GamificationError extends GamificationState {
  final String message;

  const GamificationError(this.message);
}

class AchievementUnlocked extends GamificationState {
  final Achievement achievement;
  final UserProgress userProgress;

  const AchievementUnlocked(this.achievement, this.userProgress);
}

class LeveledUp extends GamificationState {
  final int newLevel;
  final UserProgress userProgress;

  const LeveledUp(this.newLevel, this.userProgress);
}
