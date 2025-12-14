enum FocusSessionStatus {
  active,      // جلسة نشطة حالياً
  completed,   // اكتملت بنجاح
  cancelled;   // ألغيت مبكراً

  // Convert to string for JSON
  String toJson() => name;

  // Convert from string
  static FocusSessionStatus fromJson(String value) {
    return FocusSessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FocusSessionStatus.cancelled,
    );
  }
}
