import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:block_app/feature/ui/view_model/gamification_cubit/gamification_cubit.dart';
import 'package:block_app/feature/ui/view_model/gamification_cubit/gamification_state.dart';
import 'package:block_app/core/DI/setup_get_it.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Points/Rewards Pill
          BlocBuilder<GamificationCubit, GamificationState>(
            bloc:
                getIt<
                  GamificationCubit
                >(), // Ensure we use the singleton if not found in context, though HomeScreen provides it.
            // Better to rely on context if HomeScreen provides it, but getting from GetIt is safe too if consistent.
            builder: (context, state) {
              String displayText = '0';
              if (state is GamificationLoaded) {
                displayText = state.totalXP.toString();
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.blue[400],
                      size: 20,
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.layers, size: 28, color: theme.colorScheme.onSurface),
            ],
          ),
        ],
      ),
    );
  }
}
