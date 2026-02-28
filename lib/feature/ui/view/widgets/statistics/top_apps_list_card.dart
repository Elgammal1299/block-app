import 'package:flutter/material.dart';
import '../../../../data/models/app_usage_stats.dart';
import '../../../../data/models/app_usage_limit.dart';
import 'app_usage_item.dart';

/// Card widget displaying list of top used apps
class TopAppsListCard extends StatelessWidget {
  final List<AppUsageStats> topApps;
  final Map<String, AppUsageLimit> usageLimitsMap;
  final EdgeInsetsGeometry margin;

  const TopAppsListCard({
    super.key,
    required this.topApps,
    required this.usageLimitsMap,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (topApps.isEmpty) {
      return _buildEmptyState(context);
    }

    // Calculate total usage time for percentage calculation
    final totalUsageTime = topApps.fold<int>(
      0,
      (sum, app) => sum + app.totalTimeInMillis,
    );

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'أكثر التطبيقات استخدامًا',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // App list
          ...topApps.asMap().entries.map((entry) {
            final index = entry.key;
            final stats = entry.value;
            final limit = usageLimitsMap[stats.packageName];

            return AppUsageItem(
              stats: stats,
              usageLimit: limit,
              index: index,
              totalUsageTime: totalUsageTime,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات لاستخدام التطبيقات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ استخدام التطبيقات علشان تشوف الإحصائيات هنا',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
