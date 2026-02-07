import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_block/core/DI/setup_get_it.dart';
import 'package:app_block/core/router/app_routes.dart';
import '../focus_mode_card.dart'; // For FocusModeType
import 'package:app_block/feature/ui/view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';
import 'package:app_block/feature/ui/view_model/custom_focus_mode_cubit/custom_focus_mode_state.dart';
import 'saved_custom_mode_card.dart';

class ModesRow extends StatelessWidget {
  const ModesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أوضاع التركيز',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Optional: "View All" if list is long
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190, // Sufficient height for cards
          child: BlocBuilder<CustomFocusModeCubit, CustomFocusModeState>(
            bloc: getIt<CustomFocusModeCubit>(),
            builder: (context, state) {
              final savedModes = (state is CustomFocusModeLoaded)
                  ? state.sortedByRecent.take(5).toList()
                  : [];

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount:
                    2 +
                    savedModes.length +
                    1, // Sleep, Work + Saved + Create New
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  // 1. Sleep Mode
                  if (index == 0) {
                    return const _PresetModeCard(modeType: FocusModeType.sleep);
                  }
                  // 2. Work Mode
                  if (index == 1) {
                    return const _PresetModeCard(modeType: FocusModeType.work);
                  }
                  // 3. Saved Modes
                  if (index < 2 + savedModes.length) {
                    final customMode = savedModes[index - 2];
                    return SavedCustomModeCard(mode: customMode);
                  }
                  // 4. Create New
                  return const _CreateCustomModeCard();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PresetModeCard extends StatelessWidget {
  final FocusModeType modeType;

  const _PresetModeCard({required this.modeType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color iconColor;
    Color bgColor;

    if (modeType == FocusModeType.sleep) {
      iconColor = isDark ? Colors.indigo.shade300 : Colors.indigo;
      bgColor = isDark
          ? Colors.indigo.shade900.withValues(alpha: 0.3)
          : Colors.indigo.shade50;
    } else {
      iconColor = isDark ? Colors.blue.shade300 : Colors.blue;
      bgColor = isDark
          ? Colors.blue.shade900.withValues(alpha: 0.3)
          : Colors.blue.shade50;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.quickModeDetails, arguments: modeType);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(modeType.icon, color: iconColor, size: 28),
              ),
              const Spacer(),
              Text(
                modeType.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(modeType.duration),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
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

  String _getDescription() {
    switch (modeType) {
      case FocusModeType.sleep:
        return 'نوم هادئ بدون إزعاج';
      case FocusModeType.work:
        return 'عمل بتركيز عالي';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ساعة';
    } else {
      return '${duration.inMinutes} دقيقة';
    }
  }
}

class _CreateCustomModeCard extends StatelessWidget {
  const _CreateCustomModeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      color: Colors.transparent, // Outline style
      child: InkWell(
        onTap: () {
          // Direct user to create a new custom mode (Placeholder route)
          Navigator.of(context).pushNamed(AppRoutes.usageLimitSelection);
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 120, // Smaller/Distinct width for the "Add" button
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'جديد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
