import 'package:flutter/material.dart';
import '../../../../data/models/app_usage_stats.dart';
import '../../../../data/models/app_usage_limit.dart';
import 'app_usage_item.dart';

/// Card widget displaying list of top used apps
class TopAppsListCard extends StatelessWidget {
  final List<AppUsageStats> topApps;
  final Map<String, AppUsageLimit> usageLimitsMap;

  const TopAppsListCard({
    super.key,
    required this.topApps,
    required this.usageLimitsMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (topApps.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Apps Today',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // App list
            ...topApps.asMap().entries.map((entry) {
              final index = entry.key;
              final stats = entry.value;
              final limit = usageLimitsMap[stats.packageName];

              return AppUsageItem(
                stats: stats,
                usageLimit: limit,
                index: index,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              'No App Usage Data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start using apps to see statistics here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
