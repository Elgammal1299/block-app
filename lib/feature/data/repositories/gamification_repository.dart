import 'dart:convert';
import '../local/shared_prefs_service.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../../../core/utils/app_logger.dart';

class GamificationRepository {
  final SharedPrefsService _prefsService;

  GamificationRepository(this._prefsService);

  static const String _keyUserProgress = 'user_progress';
  static const String _keyLastActivityDate = 'last_activity_date';

  Future<UserProgress> getUserProgress() async {
    final progressJson = _prefsService.getString(_keyUserProgress);

    if (progressJson != null) {
      try {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        return UserProgress.fromJson(progressData);
      } catch (e) {
        AppLogger.w('Error parsing user progress: $e');
      }
    }

    // إنشاء تقدم جديد مع جميع الإنجازات غير المفتوحة
    return _createInitialProgress();
  }

  UserProgress _createInitialProgress() {
    final allAchievements = AchievementType.values
        .map((type) => Achievement.fromType(type))
        .toList();

    return UserProgress(
      totalXP: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      totalSessions: 0,
      completedSessions: 0,
      achievements: allAchievements,
      lastActivityDate: DateTime.now(),
    );
  }

  Future<void> addXP(int points) async {
    if (points <= 0) return;

    final currentProgress = await getUserProgress();
    final newTotalXP = currentProgress.totalXP + points;

    // حساب المستوى الجديد
    int newLevel = 1;
    int xpRequired = 0;

    while (xpRequired <= newTotalXP) {
      newLevel++;
      xpRequired += newLevel * 100;
    }
    newLevel--; // التراجع عن المستوى الأخير

    final updatedProgress = currentProgress.copyWith(
      totalXP: newTotalXP,
      level: newLevel,
    );

    await _saveUserProgress(updatedProgress);
  }

  Future<void> unlockAchievement(AchievementType achievementType) async {
    final currentProgress = await getUserProgress();

    final updatedAchievements = currentProgress.achievements.map((achievement) {
      if (achievement.type == achievementType && !achievement.isUnlocked) {
        return achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
      return achievement;
    }).toList();

    final updatedProgress = currentProgress.copyWith(
      achievements: updatedAchievements,
    );

    await _saveUserProgress(updatedProgress);

    // إضافة XP من الإنجاز
    final unlockedAchievement = Achievement.fromType(achievementType);
    await addXP(unlockedAchievement.xpReward);
  }

  Future<void> updateStreak() async {
    final currentProgress = await getUserProgress();
    final today = DateTime.now();
    final lastActivity = currentProgress.lastActivityDate;

    final todayDate = DateTime(today.year, today.month, today.day);
    final lastActivityDate =
        DateTime(lastActivity.year, lastActivity.month, lastActivity.day);

    final daysDifference = todayDate.difference(lastActivityDate).inDays;

    int newStreak;
    if (daysDifference == 0) {
      // نفس اليوم - لا تغيير
      return;
    } else if (daysDifference == 1) {
      // يوم متتالي - زيادة السلسلة
      newStreak = currentProgress.currentStreak + 1;
    } else {
      // انقطاع - إعادة التعيين
      newStreak = 1;
    }

    final newLongestStreak = newStreak > currentProgress.longestStreak
        ? newStreak
        : currentProgress.longestStreak;

    final updatedProgress = currentProgress.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: today,
    );

    await _saveUserProgress(updatedProgress);

    // التحقق من إنجازات السلسلة
    if (newStreak >= 7 &&
        !_isAchievementUnlocked(currentProgress, AchievementType.weekStreak)) {
      await unlockAchievement(AchievementType.weekStreak);
    }
  }

  Future<void> incrementSessionCount({bool isCompleted = false}) async {
    final currentProgress = await getUserProgress();

    final updatedProgress = currentProgress.copyWith(
      totalSessions: currentProgress.totalSessions + 1,
      completedSessions: isCompleted
          ? currentProgress.completedSessions + 1
          : currentProgress.completedSessions,
    );

    await _saveUserProgress(updatedProgress);

    // التحقق من إنجازات الجلسات
    if (updatedProgress.completedSessions == 1 &&
        !_isAchievementUnlocked(
            currentProgress, AchievementType.firstSession)) {
      await unlockAchievement(AchievementType.firstSession);
    } else if (updatedProgress.completedSessions >= 10 &&
        !_isAchievementUnlocked(
            currentProgress, AchievementType.focusWarrior)) {
      await unlockAchievement(AchievementType.focusWarrior);
    } else if (updatedProgress.completedSessions >= 100 &&
        !_isAchievementUnlocked(currentProgress, AchievementType.zenMaster)) {
      await unlockAchievement(AchievementType.zenMaster);
    }
  }

  Future<void> checkTimeBasedAchievements() async {
    final currentProgress = await getUserProgress();
    final now = DateTime.now();

    // الطائر المبكر (قبل 9 صباحاً)
    if (now.hour < 9 &&
        !_isAchievementUnlocked(currentProgress, AchievementType.earlyBird)) {
      await unlockAchievement(AchievementType.earlyBird);
    }

    // بومة الليل (بعد 10 مساءً)
    if (now.hour >= 22 &&
        !_isAchievementUnlocked(currentProgress, AchievementType.nightOwl)) {
      await unlockAchievement(AchievementType.nightOwl);
    }
  }

  Future<List<Achievement>> getAllAchievements() async {
    final progress = await getUserProgress();
    return progress.achievements;
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final progress = await getUserProgress();
    return progress.unlockedAchievements;
  }

  Future<Achievement?> getLatestUnlockedAchievement() async {
    final unlockedAchievements = await getUnlockedAchievements();

    if (unlockedAchievements.isEmpty) return null;

    unlockedAchievements.sort((a, b) {
      if (a.unlockedAt == null) return 1;
      if (b.unlockedAt == null) return -1;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });

    return unlockedAchievements.first;
  }

  bool _isAchievementUnlocked(
      UserProgress progress, AchievementType achievementType) {
    return progress.achievements.any(
      (achievement) =>
          achievement.type == achievementType && achievement.isUnlocked,
    );
  }

  Future<void> _saveUserProgress(UserProgress progress) async {
    final progressJson = jsonEncode(progress.toJson());
    await _prefsService.setString(_keyUserProgress, progressJson);
  }

  Future<void> resetProgress() async {
    await _prefsService.remove(_keyUserProgress);
    await _prefsService.remove(_keyLastActivityDate);
  }
}
