import 'package:flutter/material.dart';

enum SuggestionType {
  startFocusMode,      // ابدأ وضع تركيز
  breakTime,           // خذ استراحة
  reviewStats,         // راجع إحصائياتك
  updateSchedule,      // حدث جدولك
  achievementUnlock,   // achievement جديد
  goalReminder,        // تذكير بالهدف
}

class SmartSuggestion {
  final String id;
  final SuggestionType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? actionRoute;
  final Map<String, dynamic>? actionData;
  final DateTime createdAt;
  final bool isDismissed;

  SmartSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.actionRoute,
    this.actionData,
    DateTime? createdAt,
    this.isDismissed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    final type = SuggestionType.values.firstWhere(
      (e) => e.toString() == 'SuggestionType.${json['type']}',
      orElse: () => SuggestionType.startFocusMode,
    );

    IconData icon;
    switch (type) {
      case SuggestionType.startFocusMode:
        icon = Icons.timer;
        break;
      case SuggestionType.breakTime:
        icon = Icons.coffee;
        break;
      case SuggestionType.reviewStats:
        icon = Icons.bar_chart;
        break;
      case SuggestionType.updateSchedule:
        icon = Icons.schedule;
        break;
      case SuggestionType.achievementUnlock:
        icon = Icons.emoji_events;
        break;
      case SuggestionType.goalReminder:
        icon = Icons.flag;
        break;
    }

    return SmartSuggestion(
      id: json['id'] ?? '',
      type: type,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      icon: icon,
      color: json['color'] != null ? Color(json['color']) : Colors.blue,
      actionRoute: json['actionRoute'],
      actionData: json['actionData'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isDismissed: json['isDismissed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'color': color.value,
      'actionRoute': actionRoute,
      'actionData': actionData,
      'createdAt': createdAt.toIso8601String(),
      'isDismissed': isDismissed,
    };
  }

  SmartSuggestion copyWith({
    String? id,
    SuggestionType? type,
    String? title,
    String? message,
    IconData? icon,
    Color? color,
    String? actionRoute,
    Map<String, dynamic>? actionData,
    DateTime? createdAt,
    bool? isDismissed,
  }) {
    return SmartSuggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      actionRoute: actionRoute ?? this.actionRoute,
      actionData: actionData ?? this.actionData,
      createdAt: createdAt ?? this.createdAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  @override
  String toString() {
    return 'SmartSuggestion(id: $id, type: $type, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmartSuggestion &&
        other.id == id &&
        other.type == type &&
        other.isDismissed == isDismissed;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ isDismissed.hashCode;
  }
}
