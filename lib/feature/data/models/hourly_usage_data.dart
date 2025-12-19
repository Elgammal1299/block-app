import 'package:equatable/equatable.dart';

/// Model representing app usage data for a specific hour of the day
class HourlyUsageData extends Equatable {
  /// Hour of the day (0-23)
  final int hour;

  /// Total usage time in milliseconds for this hour
  final int totalTimeInMillis;

  /// Breakdown of usage by app package name
  /// Map of packageName -> usage time in milliseconds
  final Map<String, int> appBreakdown;

  const HourlyUsageData({
    required this.hour,
    required this.totalTimeInMillis,
    required this.appBreakdown,
  });

  /// Get total time in minutes
  int get totalTimeInMinutes => (totalTimeInMillis / 60000).round();

  /// Get total time in hours (decimal)
  double get totalTimeInHours => totalTimeInMillis / 3600000;

  /// Get formatted time string (e.g., "2h 30m" or "45m")
  String get formattedTime {
    if (totalTimeInMillis == 0) return '0m';

    final hours = (totalTimeInMillis / 3600000).floor();
    final minutes = ((totalTimeInMillis % 3600000) / 60000).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  /// Get hour label for display (e.g., "00:00", "13:00")
  String get hourLabel {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// Get 12-hour format label (e.g., "12 AM", "1 PM")
  String get hour12Label {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Create from platform channel data
  factory HourlyUsageData.fromMap(Map<String, dynamic> map) {
    final appBreakdownRaw = map['appBreakdown'] as Map<dynamic, dynamic>? ?? {};
    final appBreakdown = appBreakdownRaw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value is int) ? value : (value as num).toInt(),
      ),
    );

    return HourlyUsageData(
      hour: map['hour'] as int,
      totalTimeInMillis: (map['totalTimeInMillis'] is int)
          ? map['totalTimeInMillis'] as int
          : (map['totalTimeInMillis'] as num).toInt(),
      appBreakdown: appBreakdown,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'totalTimeInMillis': totalTimeInMillis,
      'appBreakdown': appBreakdown,
    };
  }

  /// Create from JSON
  factory HourlyUsageData.fromJson(Map<String, dynamic> json) {
    final appBreakdownRaw = json['appBreakdown'] as Map<String, dynamic>? ?? {};
    final appBreakdown = appBreakdownRaw.map(
      (key, value) => MapEntry(key, value as int),
    );

    return HourlyUsageData(
      hour: json['hour'] as int,
      totalTimeInMillis: json['totalTimeInMillis'] as int,
      appBreakdown: appBreakdown,
    );
  }

  /// Create empty hourly data for a specific hour
  factory HourlyUsageData.empty(int hour) {
    return HourlyUsageData(
      hour: hour,
      totalTimeInMillis: 0,
      appBreakdown: const {},
    );
  }

  @override
  List<Object?> get props => [hour, totalTimeInMillis, appBreakdown];

  @override
  String toString() {
    return 'HourlyUsageData(hour: $hour, time: $formattedTime, apps: ${appBreakdown.length})';
  }
}
