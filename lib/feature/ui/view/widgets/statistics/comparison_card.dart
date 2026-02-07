import 'package:flutter/material.dart';
import '../../../../data/models/comparison_stats.dart';

/// Card widget displaying comparison statistics between two periods
class ComparisonCard extends StatelessWidget {
  final ComparisonStats stats;
  final EdgeInsetsGeometry margin;

  const ComparisonCard({
    super.key,
    required this.stats,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = stats.comparisonPeriod;

    return Card(
      elevation: 2,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              stats.comparisonTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Current period
            _buildPeriodSection(
              context,
              label: stats.currentPeriod.label,
              time: stats.currentPeriod.formattedTotalTime,
              isPrimary: true,
            ),

            if (comparison != null) ...[
              const SizedBox(height: 16),

              // Comparison period
              _buildPeriodSection(
                context,
                label: comparison.label,
                time: comparison.formattedTotalTime,
                isPrimary: false,
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Difference indicator
              _buildDifferenceIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection(
    BuildContext context, {
    required String label,
    required String time,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isPrimary
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          time,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDifferenceIndicator(BuildContext context) {
    final theme = Theme.of(context);

    // Determine color based on increase/decrease
    final Color indicatorColor;
    final IconData icon;

    if (stats.isIncrease) {
      indicatorColor = Colors.red.shade700;
      icon = Icons.arrow_upward;
    } else if (stats.isDecrease) {
      indicatorColor = Colors.green.shade700;
      icon = Icons.arrow_downward;
    } else {
      indicatorColor = Colors.grey.shade600;
      icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: indicatorColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            stats.formattedTimeDifference,
            style: theme.textTheme.titleMedium?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '(${stats.comparisonLabel})',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
