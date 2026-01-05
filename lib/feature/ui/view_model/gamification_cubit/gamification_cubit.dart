import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../../data/models/achievement.dart';
import 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;

  GamificationCubit(this._repository) : super(const GamificationInitial());

  Future<void> loadUserProgress() async {
    try {
      emit(const GamificationLoading());
      final progress = await _repository.getUserProgress();
      emit(GamificationLoaded(progress));
    } catch (e) {
      emit(GamificationError('فشل تحميل التقدم: $e'));
    }
  }

  Future<void> addXP(int points) async {
    try {
      final currentState = state;
      if (currentState is! GamificationLoaded) return;

      final oldLevel = currentState.level;

      await _repository.addXP(points);
      final newProgress = await _repository.getUserProgress();

      if (newProgress.level > oldLevel) {
        emit(LeveledUp(newProgress.level, newProgress));
        await Future.delayed(const Duration(seconds: 2));
      }

      emit(GamificationLoaded(newProgress));
    } catch (e) {
      emit(GamificationError('فشل إضافة النقاط: $e'));
    }
  }

  Future<void> unlockAchievement(AchievementType achievementType) async {
    try {
      final currentState = state;
      if (currentState is! GamificationLoaded) return;

      // التحقق من أن الإنجاز غير مفتوح بالفعل
      final isAlreadyUnlocked = currentState.achievements.any(
        (a) => a.type == achievementType && a.isUnlocked,
      );

      if (isAlreadyUnlocked) return;

      await _repository.unlockAchievement(achievementType);
      final newProgress = await _repository.getUserProgress();

      final unlockedAchievement = newProgress.achievements.firstWhere(
        (a) => a.type == achievementType,
      );

      emit(AchievementUnlocked(unlockedAchievement, newProgress));
      await Future.delayed(const Duration(seconds: 2));
      emit(GamificationLoaded(newProgress));
    } catch (e) {
      emit(GamificationError('فشل فتح الإنجاز: $e'));
    }
  }

  Future<void> updateStreak() async {
    try {
      await _repository.updateStreak();
      await loadUserProgress();
    } catch (e) {
      emit(GamificationError('فشل تحديث السلسلة: $e'));
    }
  }

  Future<void> incrementSessionCount({bool isCompleted = false}) async {
    try {
      await _repository.incrementSessionCount(isCompleted: isCompleted);
      await loadUserProgress();
    } catch (e) {
      emit(GamificationError('فشل تحديث عدد الجلسات: $e'));
    }
  }

  Future<void> checkTimeBasedAchievements() async {
    try {
      await _repository.checkTimeBasedAchievements();
      await loadUserProgress();
    } catch (e) {
      emit(GamificationError('فشل التحقق من الإنجازات: $e'));
    }
  }

  Future<void> resetProgress() async {
    try {
      await _repository.resetProgress();
      await loadUserProgress();
    } catch (e) {
      emit(GamificationError('فشل إعادة التعيين: $e'));
    }
  }
}
