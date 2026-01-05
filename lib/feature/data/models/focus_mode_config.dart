import 'dart:convert';
import 'focus_mode_schedule.dart';
import '../../ui/view/widgets/focus_mode_card.dart';

class FocusModeConfig {
  final String id;
  final FocusModeType modeType;
  final String focusListId;
  final int customDurationMinutes;
  final bool useDefaultDuration;

  // الإعدادات الإضافية
  final bool addNewlyInstalledApps;
  final bool blockUnsupportedBrowsers;
  final bool blockAdultSites;

  // إعدادات Pomodoro (للمراحل المتقدمة)
  final bool pomodoroEnabled;
  final int pomodoroWorkMinutes;
  final int pomodoroBreakMinutes;
  final int pomodoroLongBreakMinutes;
  final int pomodoroSessionsBeforeLongBreak;

  // الجدولة (للمراحل المتقدمة)
  final List<FocusModeSchedule> schedules;

  // تتبع التخصيص
  final bool isCustomized;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  FocusModeConfig({
    required this.id,
    required this.modeType,
    required this.focusListId,
    required this.customDurationMinutes,
    this.useDefaultDuration = true,
    this.addNewlyInstalledApps = false,
    this.blockUnsupportedBrowsers = false,
    this.blockAdultSites = false,
    this.pomodoroEnabled = false,
    this.pomodoroWorkMinutes = 25,
    this.pomodoroBreakMinutes = 5,
    this.pomodoroLongBreakMinutes = 15,
    this.pomodoroSessionsBeforeLongBreak = 4,
    this.schedules = const [],
    this.isCustomized = false,
    this.lastUsedAt,
    required this.createdAt,
  });

  // Copy with
  FocusModeConfig copyWith({
    String? id,
    FocusModeType? modeType,
    String? focusListId,
    int? customDurationMinutes,
    bool? useDefaultDuration,
    bool? addNewlyInstalledApps,
    bool? blockUnsupportedBrowsers,
    bool? blockAdultSites,
    bool? pomodoroEnabled,
    int? pomodoroWorkMinutes,
    int? pomodoroBreakMinutes,
    int? pomodoroLongBreakMinutes,
    int? pomodoroSessionsBeforeLongBreak,
    List<FocusModeSchedule>? schedules,
    bool? isCustomized,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return FocusModeConfig(
      id: id ?? this.id,
      modeType: modeType ?? this.modeType,
      focusListId: focusListId ?? this.focusListId,
      customDurationMinutes: customDurationMinutes ?? this.customDurationMinutes,
      useDefaultDuration: useDefaultDuration ?? this.useDefaultDuration,
      addNewlyInstalledApps: addNewlyInstalledApps ?? this.addNewlyInstalledApps,
      blockUnsupportedBrowsers: blockUnsupportedBrowsers ?? this.blockUnsupportedBrowsers,
      blockAdultSites: blockAdultSites ?? this.blockAdultSites,
      pomodoroEnabled: pomodoroEnabled ?? this.pomodoroEnabled,
      pomodoroWorkMinutes: pomodoroWorkMinutes ?? this.pomodoroWorkMinutes,
      pomodoroBreakMinutes: pomodoroBreakMinutes ?? this.pomodoroBreakMinutes,
      pomodoroLongBreakMinutes: pomodoroLongBreakMinutes ?? this.pomodoroLongBreakMinutes,
      pomodoroSessionsBeforeLongBreak: pomodoroSessionsBeforeLongBreak ?? this.pomodoroSessionsBeforeLongBreak,
      schedules: schedules ?? this.schedules,
      isCustomized: isCustomized ?? this.isCustomized,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modeType': modeType.name,
      'focusListId': focusListId,
      'customDurationMinutes': customDurationMinutes,
      'useDefaultDuration': useDefaultDuration,
      'addNewlyInstalledApps': addNewlyInstalledApps,
      'blockUnsupportedBrowsers': blockUnsupportedBrowsers,
      'blockAdultSites': blockAdultSites,
      'pomodoroEnabled': pomodoroEnabled,
      'pomodoroWorkMinutes': pomodoroWorkMinutes,
      'pomodoroBreakMinutes': pomodoroBreakMinutes,
      'pomodoroLongBreakMinutes': pomodoroLongBreakMinutes,
      'pomodoroSessionsBeforeLongBreak': pomodoroSessionsBeforeLongBreak,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'isCustomized': isCustomized,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // From JSON
  factory FocusModeConfig.fromJson(Map<String, dynamic> json) {
    return FocusModeConfig(
      id: json['id'] as String,
      modeType: FocusModeType.values.firstWhere(
        (e) => e.name == json['modeType'],
      ),
      focusListId: json['focusListId'] as String,
      customDurationMinutes: json['customDurationMinutes'] as int,
      useDefaultDuration: json['useDefaultDuration'] as bool? ?? true,
      addNewlyInstalledApps: json['addNewlyInstalledApps'] as bool? ?? false,
      blockUnsupportedBrowsers: json['blockUnsupportedBrowsers'] as bool? ?? false,
      blockAdultSites: json['blockAdultSites'] as bool? ?? false,
      pomodoroEnabled: json['pomodoroEnabled'] as bool? ?? false,
      pomodoroWorkMinutes: json['pomodoroWorkMinutes'] as int? ?? 25,
      pomodoroBreakMinutes: json['pomodoroBreakMinutes'] as int? ?? 5,
      pomodoroLongBreakMinutes: json['pomodoroLongBreakMinutes'] as int? ?? 15,
      pomodoroSessionsBeforeLongBreak: json['pomodoroSessionsBeforeLongBreak'] as int? ?? 4,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((s) => FocusModeSchedule.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isCustomized: json['isCustomized'] as bool? ?? false,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Encode to String (للحفظ في SharedPreferences)
  String encode() => jsonEncode(toJson());

  // Decode from String
  static FocusModeConfig decode(String encoded) =>
      FocusModeConfig.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}
