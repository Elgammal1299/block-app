import 'package:flutter/material.dart';
import '../../../../data/models/app_usage_stats.dart';
import '../../../../data/models/app_usage_limit.dart';
import '../../../../data/models/statistics_dashboard_data.dart';

/// List item widget displaying app usage with StayFree-style design
class AppUsageItem extends StatelessWidget {
  final AppUsageStats stats;
  final AppUsageLimit? usageLimit;
  final int index;
  final int
  totalUsageTime; // Total usage time of all apps for percentage calculation

  const AppUsageItem({
    super.key,
    required this.stats,
    this.usageLimit,
    required this.index,
    this.totalUsageTime = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = usageLimit != null;
    final percentage = totalUsageTime > 0
        ? (stats.totalTimeInMillis / totalUsageTime * 100)
        : 0.0;

    // Get app-specific color
    final appColor = PieChartColors.getColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // App Icon (larger)
          _buildAppIcon(appColor),
          const SizedBox(width: 16),

          // App info and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App name and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stats.appName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      stats.formattedTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: appColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(appColor),
                  ),
                ),
                const SizedBox(height: 6),

                // Percentage, open count, and limit info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: Percentage and Open Count
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Percentage badge
                          Text(
                            '${percentage.toStringAsFixed(1)}% من الإجمالي',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // ✨ Open count badge
                          if (stats.openCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: appColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: appColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 12,
                                    color: appColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats.openCount} مرة',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: appColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // ✨ NEW: Block attempts badge (if app was blocked)
                          if (stats.blockAttempts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block_rounded,
                                    size: 12,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats.blockAttempts} محاولة حظر',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right side: Usage limit (if exists)
                    if (hasLimit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getLimitColor(usageLimit!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              usageLimit!.isLimitReached
                                  ? Icons.warning_rounded
                                  : Icons.timer_outlined,
                              size: 12,
                              color: _getLimitColor(usageLimit!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${usageLimit!.usedMinutesToday}/${usageLimit!.dailyLimitMinutes}m',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getLimitColor(usageLimit!),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLimitColor(AppUsageLimit limit) {
    final percentage = limit.usagePercentage;
    if (percentage >= 100) {
      return Colors.red.shade700;
    } else if (percentage >= 80) {
      return Colors.orange.shade700;
    } else {
      return Colors.green.shade600;
    }
  }

  Widget _buildAppIcon(Color appColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: appColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appColor.withOpacity(0.3), width: 2),
      ),
      child: stats.icon != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                stats.icon!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.apps_rounded, color: appColor, size: 28);
                },
              ),
            )
          : Icon(Icons.apps_rounded, color: appColor, size: 28),
    );
  }
}
