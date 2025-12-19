import 'package:flutter/material.dart';

/// Time period filter options
enum TimePeriod { today, yesterday, last7Days, last14Days, last30Days }

extension TimePeriodExtension on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.today:
        return 'اليوم';
      case TimePeriod.yesterday:
        return 'الأمس';
      case TimePeriod.last7Days:
        return 'آخر 7 أيام';
      case TimePeriod.last14Days:
        return 'آخر 14 يوم';
      case TimePeriod.last30Days:
        return 'آخر 30 يوم';
    }
  }

  IconData get icon {
    switch (this) {
      case TimePeriod.today:
        return Icons.today_rounded;
      case TimePeriod.yesterday:
        return Icons.history_rounded;
      case TimePeriod.last7Days:
        return Icons.calendar_view_week_rounded;
      case TimePeriod.last14Days:
        return Icons.date_range_rounded;
      case TimePeriod.last30Days:
        return Icons.calendar_month_rounded;
    }
  }

  /// Get start and end dates for this period
  DateTimeRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case TimePeriod.today:
        return DateTimeRange(start: today, end: now);
      case TimePeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: yesterday,
          end: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          ),
        );
      case TimePeriod.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: now,
        );
      case TimePeriod.last14Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 13)),
          end: now,
        );
      case TimePeriod.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: now,
        );
    }
  }
}

/// Time period filter dropdown widget
class TimePeriodFilter extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onChanged;
  final EdgeInsetsGeometry margin;

  const TimePeriodFilter({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            'الفترة الزمنية:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TimePeriod>(
                value: selectedPeriod,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.primary,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(12),
                items: TimePeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Row(
                      children: [
                        Icon(
                          period.icon,
                          size: 18,
                          color: selectedPeriod == period
                              ? colorScheme.primary
                              : theme.iconTheme.color?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 10),
                        Text(period.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
