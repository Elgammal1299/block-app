class FocusSessionHistory {
  final String id;
  final String focusListName;
  final int durationMinutes;
  final DateTime completedAt;
  final bool wasCompleted;

  FocusSessionHistory({
    required this.id,
    required this.focusListName,
    required this.durationMinutes,
    required this.completedAt,
    required this.wasCompleted,
  });

  // Create from JSON
  factory FocusSessionHistory.fromJson(Map<String, dynamic> json) {
    return FocusSessionHistory(
      id: json['id'] as String,
      focusListName: json['focusListName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      wasCompleted: json['wasCompleted'] as bool,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'focusListName': focusListName,
      'durationMinutes': durationMinutes,
      'completedAt': completedAt.toIso8601String(),
      'wasCompleted': wasCompleted,
    };
  }

  // Helper to get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate =
        DateTime(completedAt.year, completedAt.month, completedAt.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(completedAt).inDays < 7) {
      return 'This Week';
    } else {
      return '${completedAt.day}/${completedAt.month}/${completedAt.year}';
    }
  }

  // Helper to get formatted time
  String get formattedTime {
    final hour = completedAt.hour.toString().padLeft(2, '0');
    final minute = completedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FocusSessionHistory{id: $id, name: $focusListName, duration: $durationMinutes min, completed: $wasCompleted}';
  }
}
