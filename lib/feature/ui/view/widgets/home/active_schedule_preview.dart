import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/schedule_cubit/schedule_cubit.dart';
import '../../../view_model/schedule_cubit/schedule_state.dart';
import '../../../../../core/router/app_routes.dart';

class ActiveSchedulePreview extends StatelessWidget {
  const ActiveSchedulePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded || state.schedules.isEmpty) {
          return const SizedBox.shrink();
        }

        // البحث عن جدول نشط الآن
        final now = DateTime.now();
        final activeSchedule = state.schedules.firstWhere(
          (schedule) => schedule.isEnabled && schedule.isActiveAt(now),
          orElse: () => state.schedules.first, // عرض أول جدول كبديل
        );

        final isCurrentlyActive = activeSchedule.isActiveAt(now);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.schedules);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCurrentlyActive ? 'الجدول النشط' : 'الجدول القادم',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.schedules);
                        },
                        child: const Text('عرض الكل'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (isCurrentlyActive
                                  ? theme.colorScheme.primary
                                  : Colors.grey)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: isCurrentlyActive
                              ? theme.colorScheme.primary
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeSchedule.getDaysString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeSchedule.startTimeFormatted} - ${activeSchedule.endTimeFormatted}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentlyActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'نشط الآن',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
