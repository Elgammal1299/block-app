/// Model for app daily usage limit
/// Used to limit daily usage time for specific apps
class AppUsageLimit {
  final String packageName;
  final String appName;
  final int dailyLimitMinutes; // Daily usage limit in minutes
  final int usedMinutesToday; // Minutes used today
  final DateTime? lastResetDate; // Last reset date (for daily reset)
  final bool isEnabled; // Whether the limit is active

  AppUsageLimit({
    required this.packageName,
    required this.appName,
    required this.dailyLimitMinutes,
    this.usedMinutesToday = 0,
    this.lastResetDate,
    this.isEnabled = true,
  });

  /// Check if the limit has been reached
  bool get isLimitReached => usedMinutesToday >= dailyLimitMinutes;

  /// Get remaining minutes
  int get remainingMinutes => dailyLimitMinutes - usedMinutesToday;

  /// Get usage percentage (0-100)
  double get usagePercentage {
    if (dailyLimitMinutes == 0) return 0;
    return (usedMinutesToday / dailyLimitMinutes * 100).clamp(0, 100);
  }

  /// Check if needs reset (new day)
  bool needsReset() {
    if (lastResetDate == null) return true;
    final now = DateTime.now();
    final lastReset = lastResetDate!;
    return now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;
  }

  /// Create from JSON
  factory AppUsageLimit.fromJson(Map<String, dynamic> json) {
    return AppUsageLimit(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      usedMinutesToday: json['usedMinutesToday'] as int? ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'] as String)
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'dailyLimitMinutes': dailyLimitMinutes,
      'usedMinutesToday': usedMinutesToday,
      'lastResetDate': lastResetDate?.toIso8601String(),
      'isEnabled': isEnabled,
    };
  }

  /// Copy with method
  AppUsageLimit copyWith({
    String? packageName,
    String? appName,
    int? dailyLimitMinutes,
    int? usedMinutesToday,
    DateTime? lastResetDate,
    bool? isEnabled,
  }) {
    return AppUsageLimit(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Reset daily usage
  AppUsageLimit reset() {
    return copyWith(
      usedMinutesToday: 0,
      lastResetDate: DateTime.now(),
    );
  }

  /// Add usage time
  AppUsageLimit addUsage(int minutes) {
    return copyWith(
      usedMinutesToday: usedMinutesToday + minutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageLimit &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() {
    return 'AppUsageLimit{packageName: $packageName, appName: $appName, '
        'dailyLimitMinutes: $dailyLimitMinutes, usedMinutesToday: $usedMinutesToday, '
        'isLimitReached: $isLimitReached, isEnabled: $isEnabled}';
  }

  /// Format time for display (e.g., "1h 30m", "45m", "2h")
  static String formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}
