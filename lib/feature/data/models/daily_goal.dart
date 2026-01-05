class DailyGoal {
  final String id;
  final DateTime date;
  final int targetMinutes;
  final int achievedMinutes;
  final bool isCompleted;

  DailyGoal({
    required this.id,
    required this.date,
    required this.targetMinutes,
    required this.achievedMinutes,
    required this.isCompleted,
  });

  double get progress {
    if (targetMinutes == 0) return 0.0;
    return (achievedMinutes / targetMinutes).clamp(0.0, 1.0);
  }

  int get remainingMinutes {
    final remaining = targetMinutes - achievedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      id: json['id'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      targetMinutes: json['targetMinutes'] ?? 60,
      achievedMinutes: json['achievedMinutes'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'targetMinutes': targetMinutes,
      'achievedMinutes': achievedMinutes,
      'isCompleted': isCompleted,
    };
  }

  DailyGoal copyWith({
    String? id,
    DateTime? date,
    int? targetMinutes,
    int? achievedMinutes,
    bool? isCompleted,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      date: date ?? this.date,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      achievedMinutes: achievedMinutes ?? this.achievedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'DailyGoal(id: $id, date: $date, target: $targetMinutes, achieved: $achievedMinutes, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyGoal &&
        other.id == id &&
        other.date == date &&
        other.targetMinutes == targetMinutes &&
        other.achievedMinutes == achievedMinutes &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        targetMinutes.hashCode ^
        achievedMinutes.hashCode ^
        isCompleted.hashCode;
  }
}
