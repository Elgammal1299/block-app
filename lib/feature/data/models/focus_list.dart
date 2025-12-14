class FocusList {
  final String id;
  final String name;
  final List<String> packageNames;
  final bool isPreset;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  FocusList({
    required this.id,
    required this.name,
    required this.packageNames,
    this.isPreset = false,
    required this.createdAt,
    this.lastUsedAt,
  });

  // Create from JSON
  factory FocusList.fromJson(Map<String, dynamic> json) {
    return FocusList(
      id: json['id'] as String,
      name: json['name'] as String,
      packageNames: (json['packageNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPreset: json['isPreset'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageNames': packageNames,
      'isPreset': isPreset,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  // Copy with method
  FocusList copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    bool? isPreset,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return FocusList(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusList && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FocusList{id: $id, name: $name, packageNames: ${packageNames.length} apps, isPreset: $isPreset}';
  }
}
