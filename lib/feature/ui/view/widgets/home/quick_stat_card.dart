import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSolid;
  final VoidCallback? onTap;

  const QuickStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isSolid = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSolid ? color : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: isSolid
              ? null
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSolid ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: isSolid ? Colors.white : color, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: isSolid
                    ? Colors.white.withValues(alpha: 0.9)
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
