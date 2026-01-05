import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/daily_goal_cubit/daily_goal_cubit.dart';
import '../../../view_model/daily_goal_cubit/daily_goal_state.dart';
import '../../../view_model/gamification_cubit/gamification_cubit.dart';
import '../../../view_model/gamification_cubit/gamification_state.dart';

class HeroStatsCard extends StatelessWidget {
  const HeroStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocBuilder<DailyGoalCubit, DailyGoalState>(
            builder: (context, goalState) {
              return BlocBuilder<GamificationCubit, GamificationState>(
                builder: (context, gamificationState) {
                  return _buildContent(
                    context,
                    goalState,
                    gamificationState,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DailyGoalState goalState,
    GamificationState gamificationState,
  ) {
    if (goalState is DailyGoalLoading ||
        gamificationState is GamificationLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final goal = goalState is DailyGoalLoaded ? goalState.goal : null;
    final progress =
        gamificationState is GamificationLoaded ? gamificationState : null;

    final achievedMinutes = goal?.achievedMinutes ?? 0;
    final targetMinutes = goal?.targetMinutes ?? 60;
    final goalProgress = goal?.progress ?? 0.0;
    final streak = progress?.currentStreak ?? 0;

    return Row(
      children: [
        // Left side - Circular Progress
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: goalProgress,
                        strokeWidth: 12,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(goalProgress),
                        ),
                      ),
                    ),
                    // Center text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$achievedMinutes',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'من $targetMinutes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right side - Stats
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'هدف التركيز اليومي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Progress message
              Text(
                _getProgressMessage(goalProgress, goal?.isCompleted ?? false),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),

              // Streak
              if (streak > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'سلسلة $streak يوم',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

              // Level (if available)
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المستوى ${progress.level}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${progress.totalXP} XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.amber; // ذهبي
    if (progress >= 0.75) return Colors.green; // أخضر
    if (progress >= 0.50) return Colors.yellow; // أصفر
    if (progress >= 0.25) return Colors.orange; // برتقالي
    return Colors.red; // أحمر
  }

  String _getProgressMessage(double progress, bool isCompleted) {
    if (isCompleted) return 'تحقق الهدف! 🎉';
    if (progress >= 0.75) return 'تقريباً!';
    if (progress >= 0.50) return 'نصف الطريق';
    if (progress >= 0.25) return 'استمر!';
    return 'ابدأ رحلتك!';
  }
}
