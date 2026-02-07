import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_block/feature/ui/view_model/statistics_cubit/statistics_cubit.dart';
import 'package:app_block/feature/ui/view_model/statistics_cubit/statistics_state.dart';
import 'package:app_block/core/DI/setup_get_it.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _formatWorkHours(int totalMillis) {
    if (totalMillis == 0) return '0 د';

    final hours = totalMillis ~/ 3600000;
    final minutes = (totalMillis % 3600000) ~/ 60000;

    if (hours > 0 && minutes > 0) {
      return '$hours س $minutes د';
    } else if (hours > 0) {
      return '$hours س';
    } else if (minutes > 0) {
      return '$minutes د';
    } else {
      return '< 1 د';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1877F2).withOpacity(0.05),
            const Color(0xFF1877F2).withOpacity(0.02),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Work Hours Display
          BlocBuilder<StatisticsCubit, StatisticsState>(
            bloc: getIt<StatisticsCubit>(),
            builder: (context, state) {
              String displayText = '0 د';
              int totalMillis = 0;

              if (state is StatisticsDashboardLoaded) {
                totalMillis =
                    state.comparisonStats.currentPeriod.totalScreenTimeMillis;
                displayText = _formatWorkHours(totalMillis);
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1877F2), const Color(0xFF0E5FCC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1877F2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'ساعات العمل',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Right: App Logo & Name
          Row(
            children: [
              Text(
                'AppBlock',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.block_rounded,
                    size: 32,
                    color: const Color(0xFF1877F2),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
