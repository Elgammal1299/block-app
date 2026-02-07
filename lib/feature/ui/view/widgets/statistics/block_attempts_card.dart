import 'package:flutter/material.dart';

/// Card widget displaying total block attempts
class BlockAttemptsCard extends StatelessWidget {
  final int totalAttempts;
  final EdgeInsetsGeometry margin;
  final String? periodLabel; // Optional label for the period

  const BlockAttemptsCard({
    super.key,
    required this.totalAttempts,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade700,
              Colors.deepOrange.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.block,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodLabel ?? 'محاولات الدخول للمحظور',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalAttempts.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Badge icon
            Icon(
              totalAttempts > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
