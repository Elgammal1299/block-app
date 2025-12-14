import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> daysOfWeek; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final bool isEnabled;

  Schedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  // Create from JSON
  factory Schedule.fromJson(Map<String, dynamic> json) {
    // Parse time - support both string format "HH:mm" and object format {"hour": x, "minute": y}
    TimeOfDay parseTime(dynamic timeData) {
      if (timeData is String) {
        final parts = timeData.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else if (timeData is Map) {
        return TimeOfDay(
          hour: timeData['hour'] as int,
          minute: timeData['minute'] as int,
        );
      }
      throw FormatException('Invalid time format: $timeData');
    }

    return Schedule(
      id: json['id'] as String,
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      daysOfWeek: List<int>.from(json['daysOfWeek'] as List),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  // Helper to convert TimeOfDay to String "HH:mm"
  static String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper to get formatted time string for display
  String get startTimeFormatted => _timeToString(startTime);
  String get endTimeFormatted => _timeToString(endTime);

  // Check if schedule is active for a given DateTime
  bool isActiveAt(DateTime dateTime) {
    if (!isEnabled) return false;

    // Check if current day is in the schedule
    final currentDayOfWeek = dateTime.weekday; // 1=Monday, 7=Sunday
    if (!daysOfWeek.contains(currentDayOfWeek)) return false;

    // Check if current time is within the schedule
    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle schedules that cross midnight
    if (endMinutes < startMinutes) {
      // Example: 22:00 to 02:00
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  // Get days of week as readable string (e.g., "Mon, Tue, Wed")
  String getDaysString() {
    const dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    if (daysOfWeek.length == 7) return 'Every day';
    if (daysOfWeek.length == 5 &&
        daysOfWeek.contains(1) &&
        daysOfWeek.contains(2) &&
        daysOfWeek.contains(3) &&
        daysOfWeek.contains(4) &&
        daysOfWeek.contains(5)) {
      return 'Weekdays';
    }
    if (daysOfWeek.length == 2 &&
        daysOfWeek.contains(6) &&
        daysOfWeek.contains(7)) {
      return 'Weekends';
    }

    return daysOfWeek.map((day) => dayNames[day] ?? '').join(', ');
  }

  // Copy with method
  Schedule copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    bool? isEnabled,
  }) {
    return Schedule(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Schedule{id: $id, startTime: $startTimeFormatted, endTime: $endTimeFormatted, daysOfWeek: $daysOfWeek, isEnabled: $isEnabled}';
  }
}
