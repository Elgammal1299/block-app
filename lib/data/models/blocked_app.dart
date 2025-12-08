class BlockedApp {
  final String packageName;
  final String appName;
  final bool isBlocked;
  final int blockAttempts;

  BlockedApp({
    required this.packageName,
    required this.appName,
    this.isBlocked = true,
    this.blockAttempts = 0,
  });

  // Create from JSON
  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isBlocked: json['isBlocked'] as bool? ?? true,
      blockAttempts: json['blockAttempts'] as int? ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isBlocked': isBlocked,
      'blockAttempts': blockAttempts,
    };
  }

  // Copy with method
  BlockedApp copyWith({
    String? packageName,
    String? appName,
    bool? isBlocked,
    int? blockAttempts,
  }) {
    return BlockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
      blockAttempts: blockAttempts ?? this.blockAttempts,
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
    return 'BlockedApp{packageName: $packageName, appName: $appName, isBlocked: $isBlocked, blockAttempts: $blockAttempts}';
  }
}
