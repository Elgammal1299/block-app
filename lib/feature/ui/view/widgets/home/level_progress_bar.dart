import 'package:flutter/material.dart';

class LevelProgressBar extends StatelessWidget {
  final int level;
  final int currentXP;
  final int targetXP;

  const LevelProgressBar({
    super.key,
    required this.level,
    required this.currentXP,
    required this.targetXP,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetXP > 0 ? (currentXP / targetXP).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المستوى $level',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$currentXP / $targetXP XP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
      ],
    );
  }
}
