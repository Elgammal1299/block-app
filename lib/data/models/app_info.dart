import 'dart:typed_data';

class AppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final bool isSystemApp;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isSystemApp = false,
  });

  // Create from Map (received from platform channel)
  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      icon: map['icon'] != null ? Uint8List.fromList(List<int>.from(map['icon'])) : null,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'icon': icon?.toList(),
      'isSystemApp': isSystemApp,
    };
  }

  // Create from JSON (for local storage)
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      icon: null, // Icons not stored in JSON
      isSystemApp: json['isSystemApp'] as bool? ?? false,
    );
  }

  // Convert to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isSystemApp': isSystemApp,
      // Icon is not stored in JSON to save space
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() {
    return 'AppInfo{packageName: $packageName, appName: $appName, isSystemApp: $isSystemApp}';
  }
}
