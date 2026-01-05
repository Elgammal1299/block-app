import 'dart:convert';
import 'package:flutter/material.dart';
import '../local/shared_prefs_service.dart';
import '../models/smart_suggestion.dart';
import 'gamification_repository.dart';
import 'daily_goal_repository.dart';

class SuggestionsRepository {
  final SharedPrefsService _prefsService;
  final GamificationRepository _gamificationRepo;
  final DailyGoalRepository _dailyGoalRepo;

  SuggestionsRepository({
    required SharedPrefsService prefsService,
    required GamificationRepository gamificationRepo,
    required DailyGoalRepository dailyGoalRepo,
  })  : _prefsService = prefsService,
        _gamificationRepo = gamificationRepo,
        _dailyGoalRepo = dailyGoalRepo;

  static const String _keyDismissedSuggestions = 'dismissed_suggestions';

  Future<List<SmartSuggestion>> generateSuggestions() async {
    final suggestions = <SmartSuggestion>[];
    final dismissedIds = await _getDismissedSuggestionIds();
    final now = DateTime.now();

    // 1. تحقق من الإنجازات الجديدة
    final latestAchievement =
        await _gamificationRepo.getLatestUnlockedAchievement();
    if (latestAchievement != null &&
        latestAchievement.unlockedAt != null &&
        now.difference(latestAchievement.unlockedAt!).inMinutes < 30) {
      final achievementSuggestion = SmartSuggestion(
        id: 'achievement_${latestAchievement.id}',
        type: SuggestionType.achievementUnlock,
        title: 'تهانينا!',
        message:
            'حصلت على إنجاز "${latestAchievement.title}" (+${latestAchievement.xpReward} XP)',
        icon: Icons.emoji_events,
        color: Colors.amber,
        actionRoute: null,
      );

      if (!dismissedIds.contains(achievementSuggestion.id)) {
        suggestions.add(achievementSuggestion);
      }
    }

    // 2. تذكير بالهدف اليومي
    final dailyGoal = await _dailyGoalRepo.getTodayGoal();
    if (!dailyGoal.isCompleted && now.hour >= 20) {
      final remainingMinutes = dailyGoal.remainingMinutes;
      final goalSuggestion = SmartSuggestion(
        id: 'goal_reminder_${dailyGoal.id}',
        type: SuggestionType.goalReminder,
        title: 'تذكير الهدف',
        message: 'متبقي $remainingMinutes دقيقة لتحقيق هدفك اليومي',
        icon: Icons.flag,
        color: Colors.orange,
        actionRoute: null,
      );

      if (!dismissedIds.contains(goalSuggestion.id)) {
        suggestions.add(goalSuggestion);
      }
    }

    // 3. اقتراح بدء جلسة تركيز (صباحاً)
    if (now.hour >= 8 && now.hour < 11) {
      final morningSuggestion = SmartSuggestion(
        id: 'morning_focus_${now.day}',
        type: SuggestionType.startFocusMode,
        title: 'صباح الخير!',
        message: 'ابدأ يومك بجلسة تركيز لزيادة إنتاجيتك',
        icon: Icons.wb_sunny,
        color: Colors.blue,
        actionRoute: '/focus',
      );

      if (!dismissedIds.contains(morningSuggestion.id)) {
        suggestions.add(morningSuggestion);
      }
    }

    // 5. مراجعة الإحصائيات (آخر اليوم)
    if (now.hour >= 21 && now.hour < 23) {
      final reviewSuggestion = SmartSuggestion(
        id: 'review_stats_${now.day}',
        type: SuggestionType.reviewStats,
        title: 'راجع تقدمك',
        message: 'شاهد إنجازاتك اليوم وتقدمك الأسبوعي',
        icon: Icons.bar_chart,
        color: Colors.purple,
        actionRoute: '/statistics',
      );

      if (!dismissedIds.contains(reviewSuggestion.id)) {
        suggestions.add(reviewSuggestion);
      }
    }

    // إرجاع أول اقتراح فقط (لتجنب التشتت)
    return suggestions.take(1).toList();
  }

  Future<void> dismissSuggestion(String suggestionId) async {
    final dismissedIds = await _getDismissedSuggestionIds();
    dismissedIds.add(suggestionId);

    // حفظ القائمة المحدثة
    await _prefsService.setString(
      _keyDismissedSuggestions,
      jsonEncode(dismissedIds),
    );
  }

  Future<List<String>> _getDismissedSuggestionIds() async {
    final dismissedJson = _prefsService.getString(_keyDismissedSuggestions);

    if (dismissedJson != null) {
      try {
        final dismissedList = jsonDecode(dismissedJson) as List<dynamic>;
        return dismissedList.cast<String>();
      } catch (e) {
        print('Error parsing dismissed suggestions: $e');
      }
    }

    return [];
  }

  Future<void> clearDismissedSuggestions() async {
    await _prefsService.remove(_keyDismissedSuggestions);
  }

  Future<void> clearOldDismissedSuggestions() async {
    // حذف الاقتراحات القديمة (أكثر من يوم)
    final dismissedIds = await _getDismissedSuggestionIds();
    final now = DateTime.now();

    final filteredIds = dismissedIds.where((id) {
      // التحقق من التاريخ في معرف الاقتراح
      if (id.contains('_${now.day}')) {
        return true; // احتفظ باقتراحات اليوم
      }
      return false; // احذف الباقي
    }).toList();

    await _prefsService.setString(
      _keyDismissedSuggestions,
      jsonEncode(filteredIds),
    );
  }
}
