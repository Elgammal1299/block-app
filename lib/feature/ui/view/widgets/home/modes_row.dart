import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_block/feature/ui/view_model/focus_session_cubit/focus_session_cubit.dart';
import 'package:app_block/core/DI/setup_get_it.dart';
import 'package:app_block/core/router/app_routes.dart';
import '../focus_mode_card.dart'; // For FocusModeType
import '../../../../../core/theme/app_theme.dart';
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
        Text(
          'أوضاع التركيز',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        BlocBuilder<CustomFocusModeCubit, CustomFocusModeState>(
          bloc: getIt<CustomFocusModeCubit>(),
          builder: (context, state) {
            final savedModes = (state is CustomFocusModeLoaded)
                ? state.sortedByRecent.take(5).toList()
                : [];

            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 1. Create New Card (Vertical style)
                const SizedBox(height: 12),
                const _CreateCustomModeCard(),
                const SizedBox(height: 12),

                // 2. Work Mode
                const _PresetModeCard(modeType: FocusModeType.work),
                const SizedBox(height: 12),

                // 3. Sleep Mode
                const _PresetModeCard(modeType: FocusModeType.sleep),
                const SizedBox(height: 12),

                // 4. Saved Modes (if any)
                ...savedModes.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SavedCustomModeCard(mode: mode),
                  ),
                ),
              ],
            );
          },
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

    final colorScheme = theme.colorScheme;

    Color iconColor;
    Color bgColor;

    if (modeType == FocusModeType.sleep) {
      iconColor = AppTheme.accentInfo;
      bgColor = AppTheme.accentInfo.withValues(alpha: 0.1);
    } else if (modeType == FocusModeType.work) {
      iconColor = colorScheme.primary;
      bgColor = colorScheme.primary.withValues(alpha: 0.1);
    } else {
      iconColor = AppTheme.accentSuccess;
      bgColor = AppTheme.accentSuccess.withValues(alpha: 0.1);
    }

    return SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.quickModeDetails, arguments: modeType);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(modeType.icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        modeType.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getDescription(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final cubit = getIt<FocusSessionCubit>();
                        cubit.startSession(
                          'preset_${modeType.name}',
                          modeType.duration.inMinutes,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

    return SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
            style: BorderStyle.solid,
          ),
      
        ),
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
      
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.createCustomMode);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة وضع تركيز جديد',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
