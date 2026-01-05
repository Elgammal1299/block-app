import 'dart:convert';
import '../local/shared_prefs_service.dart';
import '../models/daily_goal.dart';

class DailyGoalRepository {
  final SharedPrefsService _prefsService;

  DailyGoalRepository(this._prefsService);

  static const String _keyPrefix = 'daily_goal_';
  static const String _keyCurrentTarget = 'daily_goal_target';

  String _getTodayKey() {
    final today = DateTime.now();
    return '$_keyPrefix${today.year}_${today.month}_${today.day}';
  }

  Future<DailyGoal> getTodayGoal() async {
    final today = DateTime.now();
    final todayKey = _getTodayKey();

    final goalJson = _prefsService.getString(todayKey);

    if (goalJson != null) {
      try {
        final goalData = jsonDecode(goalJson) as Map<String, dynamic>;
        return DailyGoal.fromJson(goalData);
      } catch (e) {
        print('Error parsing daily goal: $e');
      }
    }

    // إنشاء هدف جديد للي وم الحالي
    final defaultTarget = _prefsService.getInt(_keyCurrentTarget) ?? 60;
    final newGoal = DailyGoal(
      id: todayKey,
      date: DateTime(today.year, today.month, today.day),
      targetMinutes: defaultTarget,
      achievedMinutes: 0,
      isCompleted: false,
    );

    await _saveDailyGoal(newGoal);
    return newGoal;
  }

  Future<void> setDailyGoal(int targetMinutes) async {
    if (targetMinutes <= 0) {
      throw ArgumentError('Target minutes must be greater than 0');
    }

    // حفظ الهدف الافتراضي للأيام القادمة
    await _prefsService.setInt(_keyCurrentTarget, targetMinutes);

    // تحديث هدف اليوم
    final currentGoal = await getTodayGoal();
    final updatedGoal = currentGoal.copyWith(targetMinutes: targetMinutes);
    await _saveDailyGoal(updatedGoal);
  }

  Future<void> updateProgress(int additionalMinutes) async {
    final currentGoal = await getTodayGoal();

    final newAchievedMinutes = currentGoal.achievedMinutes + additionalMinutes;
    final isCompleted = newAchievedMinutes >= currentGoal.targetMinutes;

    final updatedGoal = currentGoal.copyWith(
      achievedMinutes: newAchievedMinutes,
      isCompleted: isCompleted,
    );

    await _saveDailyGoal(updatedGoal);
  }

  Future<bool> checkGoalAchieved() async {
    final goal = await getTodayGoal();
    return goal.isCompleted;
  }

  Future<List<DailyGoal>> getWeeklyGoals() async {
    final goals = <DailyGoal>[];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final key = '$_keyPrefix${date.year}_${date.month}_${date.day}';
      final goalJson = _prefsService.getString(key);

      if (goalJson != null) {
        try {
          final goalData = jsonDecode(goalJson) as Map<String, dynamic>;
          goals.add(DailyGoal.fromJson(goalData));
        } catch (e) {
          print('Error parsing goal for $key: $e');
        }
      }
    }

    return goals;
  }

  Future<int> getConsecutiveDaysAchieved() async {
    int consecutiveDays = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      // فحص حتى سنة كاملة
      final date = today.subtract(Duration(days: i));
      final key = '$_keyPrefix${date.year}_${date.month}_${date.day}';
      final goalJson = _prefsService.getString(key);

      if (goalJson != null) {
        try {
          final goalData = jsonDecode(goalJson) as Map<String, dynamic>;
          final goal = DailyGoal.fromJson(goalData);

          if (goal.isCompleted) {
            consecutiveDays++;
          } else {
            break;
          }
        } catch (e) {
          break;
        }
      } else {
        break;
      }
    }

    return consecutiveDays;
  }

  Future<void> _saveDailyGoal(DailyGoal goal) async {
    final goalJson = jsonEncode(goal.toJson());
    await _prefsService.setString(_getTodayKey(), goalJson);
  }

  Future<void> clearOldGoals({int daysToKeep = 30}) async {
    final allKeys = _prefsService.getKeys();
    final today = DateTime.now();
    final cutoffDate = today.subtract(Duration(days: daysToKeep));

    for (final key in allKeys) {
      if (key.startsWith(_keyPrefix) && key != _keyCurrentTarget) {
        try {
          final parts = key.substring(_keyPrefix.length).split('_');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            final goalDate = DateTime(year, month, day);

            if (goalDate.isBefore(cutoffDate)) {
              await _prefsService.remove(key);
            }
          }
        } catch (e) {
          print('Error parsing date from key $key: $e');
        }
      }
    }
  }
}
