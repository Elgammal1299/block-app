import 'package:flutter/material.dart';
import '../../../data/models/app_usage_stats.dart';
import '../../../data/models/app_usage_limit.dart';

/// List item widget displaying app usage with optional limit progress bar
class AppUsageItem extends StatelessWidget {
  final AppUsageStats stats;
  final AppUsageLimit? usageLimit;
  final int index;

  const AppUsageItem({
    super.key,
    required this.stats,
    this.usageLimit,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = usageLimit != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getRankColor(index),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // App Icon
              _buildAppIcon(),
              const SizedBox(width: 12),

              // App name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.appName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasLimit)
                      Text(
                        '${usageLimit!.usedMinutesToday} / ${usageLimit!.dailyLimitMinutes} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getLimitColor(usageLimit!),
                        ),
                      ),
                  ],
                ),
              ),

              // Usage time
              Text(
                stats.formattedTime,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          // Progress bar if has limit
          if (hasLimit) ...[
            const SizedBox(height: 12),
            _buildProgressBar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final limit = usageLimit!;
    final progress = limit.usagePercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(limit),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${limit.usagePercentage.toStringAsFixed(0)}% used',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getLimitColor(limit),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber.shade600; // Gold
      case 1:
        return Colors.grey.shade500; // Silver
      case 2:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue.shade600;
    }
  }

  Color _getProgressColor(AppUsageLimit limit) {
    final percentage = limit.usagePercentage;
    if (percentage >= 100) {
      return Colors.red.shade700;
    } else if (percentage >= 80) {
      return Colors.orange.shade700;
    } else if (percentage >= 60) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green.shade600;
    }
  }

  Color _getLimitColor(AppUsageLimit limit) {
    final percentage = limit.usagePercentage;
    if (percentage >= 100) {
      return Colors.red.shade700;
    } else if (percentage >= 80) {
      return Colors.orange.shade700;
    } else {
      return Colors.grey.shade600;
    }
  }

  Widget _buildAppIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: stats.icon != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                stats.icon!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.apps,
                    color: Colors.grey.shade600,
                    size: 24,
                  );
                },
              ),
            )
          : Icon(
              Icons.apps,
              color: Colors.grey.shade600,
              size: 24,
            ),
    );
  }
}
