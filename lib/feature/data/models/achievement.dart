import 'package:flutter/material.dart';

enum AchievementType {
  firstSession,    // أول جلسة (10 XP)
  weekStreak,      // 7 أيام متواصلة (50 XP)
  goalMaster,      // تحقيق الهدف 7 أيام (100 XP)
  earlyBird,       // جلسة قبل 9 صباحاً (25 XP)
  nightOwl,        // جلسة بعد 10 مساءً (25 XP)
  focusWarrior,    // 10 جلسات (75 XP)
  zenMaster        // 100 جلسة (200 XP)
}

class Achievement {
  final String id;
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromType(AchievementType type, {bool isUnlocked = false, DateTime? unlockedAt}) {
    switch (type) {
      case AchievementType.firstSession:
        return Achievement(
          id: 'first_session',
          type: type,
          title: 'البداية',
          description: 'أكمل أول جلسة تركيز',
          icon: Icons.star,
          color: const Color(0xFFFF9800), // accentWarning
          xpReward: 10,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.weekStreak:
        return Achievement(
          id: 'week_streak',
          type: type,
          title: 'المثابر',
          description: 'سلسلة 7 أيام متواصلة',
          icon: Icons.local_fire_department,
          color: const Color(0xFF42B72A), // accentSuccess
          xpReward: 50,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.goalMaster:
        return Achievement(
          id: 'goal_master',
          type: type,
          title: 'سيد الأهداف',
          description: 'حقق هدفك اليومي 7 أيام',
          icon: Icons.emoji_events,
          color: const Color(0xFF2D88FF), // accentInfo
          xpReward: 100,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.earlyBird:
        return Achievement(
          id: 'early_bird',
          type: type,
          title: 'الطائر المبكر',
          description: 'جلسة تركيز قبل 9 صباحاً',
          icon: Icons.wb_sunny,
          color: const Color(0xFFFF9800), // accentWarning
          xpReward: 25,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.nightOwl:
        return Achievement(
          id: 'night_owl',
          type: type,
          title: 'بومة الليل',
          description: 'جلسة تركيز بعد 10 مساءً',
          icon: Icons.nights_stay,
          color: const Color(0xFF2D88FF), // accentInfo
          xpReward: 25,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.focusWarrior:
        return Achievement(
          id: 'focus_warrior',
          type: type,
          title: 'محارب التركيز',
          description: 'أكمل 10 جلسات تركيز',
          icon: Icons.shield,
          color: const Color(0xFF42B72A), // accentSuccess
          xpReward: 75,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
      case AchievementType.zenMaster:
        return Achievement(
          id: 'zen_master',
          type: type,
          title: 'سيد الزن',
          description: 'أكمل 100 جلسة تركيز',
          icon: Icons.psychology,
          color: const Color(0xFF1877F2), // Primary
          xpReward: 200,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt,
        );
    }
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final type = AchievementType.values.firstWhere(
      (e) => e.toString() == 'AchievementType.${json['type']}',
      orElse: () => AchievementType.firstSession,
    );

    return Achievement.fromType(
      type,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      type: type,
      title: title,
      description: description,
      icon: icon,
      color: color,
      xpReward: xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, unlocked: $isUnlocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.type == type &&
        other.isUnlocked == isUnlocked;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ isUnlocked.hashCode;
  }
}
