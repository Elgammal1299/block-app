import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/gamification_cubit/gamification_cubit.dart';
import '../../../view_model/gamification_cubit/gamification_state.dart';
import 'level_progress_bar.dart';

class AchievementsBanner extends StatelessWidget {
  const AchievementsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GamificationCubit, GamificationState>(
      builder: (context, state) {
        if (state is GamificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! GamificationLoaded) {
          return const SizedBox.shrink();
        }

        final progress = state.userProgress;
        final latestAchievement = progress.unlockedAchievements.isNotEmpty
            ? progress.unlockedAchievements.last
            : null;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'الإنجازات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${progress.unlockedAchievementsCount}/${progress.achievements.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Latest Achievement or Placeholder
                if (latestAchievement != null)
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: latestAchievement.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          latestAchievement.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestAchievement.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '+${latestAchievement.xpReward} XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'ابدأ رحلتك واحصل على إنجازاتك الأولى!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                const SizedBox(height: 16),

                // Level Progress
                LevelProgressBar(
                  level: progress.level,
                  currentXP: progress.currentLevelXP,
                  targetXP: progress.xpToNextLevel,
                ),

                const SizedBox(height: 12),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.local_fire_department,
                      label: 'السلسلة',
                      value: '${progress.currentStreak}',
                      color: Colors.orange,
                    ),
                    _buildStatItem(
                      icon: Icons.timelapse,
                      label: 'الجلسات',
                      value: '${progress.completedSessions}',
                      color: Colors.blue,
                    ),
                    _buildStatItem(
                      icon: Icons.stars,
                      label: 'XP',
                      value: '${progress.totalXP}',
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
