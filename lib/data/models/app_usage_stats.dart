class AppUsageStats {
  final String packageName;
  final String appName;
  final int totalTimeInMillis;
  final DateTime date;

  AppUsageStats({
    required this.packageName,
    required this.appName,
    required this.totalTimeInMillis,
    required this.date,
  });

  // Get total time in minutes
  int get totalTimeInMinutes => (totalTimeInMillis / 60000).round();

  // Get total time in hours
  double get totalTimeInHours => totalTimeInMillis / 3600000;

  // Get formatted time string (e.g., "2h 30m")
  String get formattedTime {
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

  // Create from Map (received from platform channel)
  factory AppUsageStats.fromMap(
    String packageName,
    String appName,
    int timeInMillis,
    DateTime date,
  ) {
    return AppUsageStats(
      packageName: packageName,
      appName: appName,
      totalTimeInMillis: timeInMillis,
      date: date,
    );
  }

  // Create from JSON
  factory AppUsageStats.fromJson(Map<String, dynamic> json) {
    return AppUsageStats(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      totalTimeInMillis: json['totalTimeInMillis'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'totalTimeInMillis': totalTimeInMillis,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppUsageStats{packageName: $packageName, appName: $appName, time: $formattedTime, date: $date}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageStats &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          date.day == other.date.day &&
          date.month == other.date.month &&
          date.year == other.date.year;

  @override
  int get hashCode => packageName.hashCode ^ date.hashCode;
}
