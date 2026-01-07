import 'dart:convert';
import 'package:flutter/material.dart';

/// Enum for custom mode block types
enum CustomModeBlockType {
  fullBlock, // حظر كامل لمدة معينة
  timeBased, // حظر في أوقات وأيام معينة
  usageLimit, // حد للاستخدام اليومي
}

/// Model for custom focus modes created by users
class CustomFocusMode {
  final String id; // UUID
  final String name; // اسم مخصص من المستخدم
  final IconData icon; // أيقونة
  final CustomModeBlockType blockType; // نوع الحظر
  final List<String> blockedPackages; // قائمة التطبيقات المحظورة

  // للحظر الكامل (Full Block)
  final int? durationMinutes; // مدة الحظر بالدقائق

  // للحظر الزمني (Time-Based)
  final TimeOfDay? startTime; // وقت البداية
  final TimeOfDay? endTime; // وقت النهاية
  final List<int>? daysOfWeek; // أيام الأسبوع (1=الاثنين، 7=الأحد)

  // لحد الاستخدام (Usage Limit)
  final Map<String, int>? usageLimitsMinutes; // {packageName: limitMinutes}

  final DateTime createdAt;
  final DateTime? lastUsedAt;

  CustomFocusMode({
    required this.id,
    required this.name,
    required this.icon,
    required this.blockType,
    required this.blockedPackages,
    this.durationMinutes,
    this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.usageLimitsMinutes,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Copy with method for easy updates
  CustomFocusMode copyWith({
    String? id,
    String? name,
    IconData? icon,
    CustomModeBlockType? blockType,
    List<String>? blockedPackages,
    int? durationMinutes,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    Map<String, int>? usageLimitsMinutes,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return CustomFocusMode(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      blockType: blockType ?? this.blockType,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      usageLimitsMinutes: usageLimitsMinutes ?? this.usageLimitsMinutes,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'blockType': blockType.name,
      'blockedPackages': blockedPackages,
      'durationMinutes': durationMinutes,
      'startTime': startTime != null
          ? {'hour': startTime!.hour, 'minute': startTime!.minute}
          : null,
      'endTime': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'daysOfWeek': daysOfWeek,
      'usageLimitsMinutes': usageLimitsMinutes,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CustomFocusMode.fromJson(Map<String, dynamic> json) {
    return CustomFocusMode(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: _getIconFromStorage(
        json['iconCodePoint'] as int,
        json['iconFontFamily'] as String?,
      ),
      blockType: CustomModeBlockType.values.firstWhere(
        (e) => e.name == json['blockType'],
        orElse: () => CustomModeBlockType.fullBlock,
      ),
      blockedPackages: (json['blockedPackages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      durationMinutes: json['durationMinutes'] as int?,
      startTime: json['startTime'] != null
          ? TimeOfDay(
              hour: json['startTime']['hour'] as int,
              minute: json['startTime']['minute'] as int,
            )
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: json['endTime']['hour'] as int,
              minute: json['endTime']['minute'] as int,
            )
          : null,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      usageLimitsMinutes: json['usageLimitsMinutes'] != null
          ? Map<String, int>.from(json['usageLimitsMinutes'] as Map)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  /// Helper to get IconData without breaking the build.
  /// Flutter's icon tree shaker fails if it sees a non-constant IconData constructor.
  static IconData _getIconFromStorage(int codePoint, String? fontFamily) {
    if (fontFamily == 'MaterialIcons' || fontFamily == null) {
      switch (codePoint) {
        case 0xe1ad:
          return Icons.work;
        case 0xe44e:
          return Icons.nightlight_round;
        case 0xeaf3:
          return Icons.school;
        case 0xe0b8:
          return Icons.block;
        case 0xe03b:
          return Icons.access_time;
        case 0xe51f:
          return Icons.timer;
        case 0xe84f:
          return Icons.category;
        case 0xef71:
          return Icons.star;
      }
    }

    // Default fallback icon - DO NOT use the IconData constructor here
    // to avoid build errors.
    return Icons.star;
  }

  /// Encode to String for SharedPreferences
  String encode() => jsonEncode(toJson());

  /// Decode from String
  static CustomFocusMode decode(String encoded) =>
      CustomFocusMode.fromJson(jsonDecode(encoded) as Map<String, dynamic>);

  /// Get formatted description based on block type
  String getDescription() {
    switch (blockType) {
      case CustomModeBlockType.fullBlock:
        return 'حظر كامل لمدة ${_formatDuration(durationMinutes ?? 0)}';
      case CustomModeBlockType.timeBased:
        return 'حظر من ${_formatTime(startTime)} إلى ${_formatTime(endTime)}';
      case CustomModeBlockType.usageLimit:
        return 'حد للاستخدام اليومي';
    }
  }

  /// Format duration in minutes to readable string
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes دقيقة';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours ساعة';
    }
    return '$hours ساعة $mins دقيقة';
  }

  /// Format TimeOfDay to readable string
  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get icon for block type
  static IconData getIconForBlockType(CustomModeBlockType type) {
    switch (type) {
      case CustomModeBlockType.fullBlock:
        return Icons.block;
      case CustomModeBlockType.timeBased:
        return Icons.access_time;
      case CustomModeBlockType.usageLimit:
        return Icons.timer;
    }
  }

  /// Get display name for block type
  static String getBlockTypeName(CustomModeBlockType type) {
    switch (type) {
      case CustomModeBlockType.fullBlock:
        return 'حظر كامل';
      case CustomModeBlockType.timeBased:
        return 'حظر بوقت معين';
      case CustomModeBlockType.usageLimit:
        return 'حد للاستخدام';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFocusMode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CustomFocusMode{id: $id, name: $name, blockType: $blockType, '
        'blockedPackages: ${blockedPackages.length} apps}';
  }
}
