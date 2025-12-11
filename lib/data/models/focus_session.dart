import 'focus_session_status.dart';

class FocusSession {
  final String id;
  final String focusListId;
  final String focusListName;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final FocusSessionStatus status;
  final List<String> blockedPackages;

  FocusSession({
    required this.id,
    required this.focusListId,
    required this.focusListName,
    required this.durationMinutes,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.blockedPackages,
  });

  // Computed properties
  DateTime get plannedEndTime =>
      startTime.add(Duration(minutes: durationMinutes));

  int get remainingMinutes {
    if (status != FocusSessionStatus.active) return 0;
    final now = DateTime.now();
    final remaining = plannedEndTime.difference(now).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  int get remainingSeconds {
    if (status != FocusSessionStatus.active) return 0;
    final now = DateTime.now();
    final remaining = plannedEndTime.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get isActive => status == FocusSessionStatus.active;

  bool get isExpired {
    if (status != FocusSessionStatus.active) return false;
    return DateTime.now().isAfter(plannedEndTime);
  }

  // Create from JSON
  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      focusListId: json['focusListId'] as String,
      focusListName: json['focusListName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: FocusSessionStatus.fromJson(json['status'] as String),
      blockedPackages: (json['blockedPackages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'focusListId': focusListId,
      'focusListName': focusListName,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.toJson(),
      'blockedPackages': blockedPackages,
    };
  }

  // Copy with method
  FocusSession copyWith({
    String? id,
    String? focusListId,
    String? focusListName,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    FocusSessionStatus? status,
    List<String>? blockedPackages,
  }) {
    return FocusSession(
      id: id ?? this.id,
      focusListId: focusListId ?? this.focusListId,
      focusListName: focusListName ?? this.focusListName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      blockedPackages: blockedPackages ?? this.blockedPackages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FocusSession{id: $id, name: $focusListName, duration: $durationMinutes min, status: $status}';
  }
}
