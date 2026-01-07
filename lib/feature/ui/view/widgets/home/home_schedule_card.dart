import 'package:flutter/material.dart';
import '../../../../data/models/schedule.dart';

class HomeScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final int appCount;
  final VoidCallback onTap;

  const HomeScheduleCard({
    super.key,
    required this.schedule,
    required this.appCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final isActive = schedule.isActiveAt(now);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu Icon
                  Icon(Icons.more_vert, color: Colors.grey[400]),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'قيد العد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.hourglass_bottom,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),

              const SizedBox(height: 8),

              // Center Icon
              Icon(
                isActive ? Icons.hourglass_full : Icons.access_time,
                size: 56,
                color: isActive ? Colors.orange[300] : Colors.grey[400],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                'جدول معد',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                isActive
                    ? 'نشط الآن'
                    : '${schedule.startTimeFormatted} - ${schedule.endTimeFormatted}',
                style: TextStyle(
                  fontSize: 14,
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Bottom Usage Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apps, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$appCount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone_android, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '0',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
