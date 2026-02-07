import 'dart:convert';
import 'package:flutter/material.dart';

class FocusModeSchedule {
  final String id;
  final bool isEnabled;
  final TimeOfDay startTime;
  final List<int> daysOfWeek; // 1=الاثنين، 7=الأحد
  final bool autoStart; // بدء تلقائي أم إشعار فقط

  FocusModeSchedule({
    required this.id,
    this.isEnabled = true,
    required this.startTime,
    required this.daysOfWeek,
    this.autoStart = true,
  });

  // Copy with
  FocusModeSchedule copyWith({
    String? id,
    bool? isEnabled,
    TimeOfDay? startTime,
    List<int>? daysOfWeek,
    bool? autoStart,
  }) {
    return FocusModeSchedule(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      autoStart: autoStart ?? this.autoStart,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isEnabled': isEnabled,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'daysOfWeek': daysOfWeek,
      'autoStart': autoStart,
    };
  }

  // From JSON
  factory FocusModeSchedule.fromJson(Map<String, dynamic> json) {
    return FocusModeSchedule(
      id: json['id'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      startTime: TimeOfDay(
        hour: json['startTimeHour'] as int,
        minute: json['startTimeMinute'] as int,
      ),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>).cast<int>(),
      autoStart: json['autoStart'] as bool? ?? true,
    );
  }

  // Encode to String
  String encode() => jsonEncode(toJson());

  // Decode from String
  static FocusModeSchedule decode(String encoded) =>
      FocusModeSchedule.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}
