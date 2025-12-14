class BlockedApp {
  final String packageName;
  final String appName;
  final bool isBlocked;
  final int blockAttempts;
  final List<String> scheduleIds; // IDs of schedules that apply to this app

  BlockedApp({
    required this.packageName,
    required this.appName,
    this.isBlocked = true,
    this.blockAttempts = 0,
    this.scheduleIds = const [],
  });

  // Create from JSON
  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isBlocked: json['isBlocked'] as bool? ?? true,
      blockAttempts: json['blockAttempts'] as int? ?? 0,
      scheduleIds: (json['scheduleIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isBlocked': isBlocked,
      'blockAttempts': blockAttempts,
      'scheduleIds': scheduleIds,
    };
  }

  // Copy with method
  BlockedApp copyWith({
    String? packageName,
    String? appName,
    bool? isBlocked,
    int? blockAttempts,
    List<String>? scheduleIds,
  }) {
    return BlockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
      blockAttempts: blockAttempts ?? this.blockAttempts,
      scheduleIds: scheduleIds ?? this.scheduleIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() {
    return 'BlockedApp{packageName: $packageName, appName: $appName, isBlocked: $isBlocked, blockAttempts: $blockAttempts, scheduleIds: $scheduleIds}';
  }
}
