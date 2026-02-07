import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../../view_model/focus_session_cubit/focus_session_state.dart';
import '../../../view_model/focus_mode_config_cubit/focus_mode_config_cubit.dart';
import '../../../view_model/focus_mode_config_cubit/focus_mode_config_state.dart';
import '../focus_mode_card.dart';
import '../../../../../core/DI/setup_get_it.dart';

class FocusModesGrid extends StatelessWidget {
  const FocusModesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusSessionCubit, FocusSessionState>(
      builder: (context, sessionState) {
        final activeFocusMode = sessionState is FocusSessionActive
            ? _getActiveFocusModeType(sessionState)
            : null;

        // استخدام BlocBuilder للحصول على حالة التخصيص
        return BlocBuilder<FocusModeConfigCubit, FocusModeConfigState>(
          bloc: getIt<FocusModeConfigCubit>(),
          builder: (context, configState) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: FocusModeType.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mode = FocusModeType.values[index];
                final isActive = mode == activeFocusMode;

                // الحصول على حالة التخصيص
                bool isCustomized = false;
                if (configState is FocusModeConfigLoaded) {
                  final config = configState.getConfig(mode);
                  isCustomized = config?.isCustomized ?? false;
                }

                return FocusModeCard(
                  focusMode: mode,
                  isActive: isActive,
                  isCustomized: isCustomized,
                  onTap: () => _handleFocusModeToggle(context, mode, isActive),
                );
              },
            );
          },
        );
      },
    );
  }

  FocusModeType? _getActiveFocusModeType(FocusSessionActive state) {
    final duration = state.activeSession.durationMinutes;

    // محاولة مطابقة المدة مع الأوضاع الجاهزة
    if (duration == 25) return FocusModeType.study;
    if (duration == 50) return FocusModeType.work;
    if (duration == 480) return FocusModeType.sleep; // 8 hours
    if (duration == 60) return FocusModeType.sleep; // 1 hour
    if (duration == 60) return FocusModeType.sleep; // 1 hour

    return null;
  }

  void _handleFocusModeToggle(
    BuildContext context,
    FocusModeType mode,
    bool isActive,
  ) {
    final cubit = context.read<FocusSessionCubit>();

    if (isActive) {
      // End the active session
      cubit.cancelSession();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنهاء وضع التركيز'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Navigate to quick mode details screen
      Navigator.of(context).pushNamed('/quick-mode-details', arguments: mode);
    }
  }
}
