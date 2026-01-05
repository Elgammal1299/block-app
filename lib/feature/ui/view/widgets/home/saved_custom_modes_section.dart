import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/DI/setup_get_it.dart';
import '../../../view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';
import '../../../view_model/custom_focus_mode_cubit/custom_focus_mode_state.dart';
import 'saved_custom_mode_card.dart';

/// قسم عرض الأوضاع المخصصة المحفوظة في الصفحة الرئيسية
/// يعرض ListView أفقي scrollable للأوضاع المحفوظة
class SavedCustomModesSection extends StatelessWidget {
  const SavedCustomModesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CustomFocusModeCubit, CustomFocusModeState>(
      bloc: getIt<CustomFocusModeCubit>(),
      builder: (context, state) {
        // عرض فقط إذا كانت هناك أوضاع محفوظة
        if (state is! CustomFocusModeLoaded || state.modes.isEmpty) {
          return const SizedBox.shrink();
        }

        // فرز الأوضاع حسب آخر استخدام
        final sortedModes = state.sortedByRecent;

        // عرض أول 5 أوضاع فقط
        final displayModes = sortedModes.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأوضاع المحفوظة',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // زر "عرض الكل" إذا كان هناك أكثر من 5
                  if (sortedModes.length > 5)
                    TextButton(
                      onPressed: () {
                        // سيتم إضافة شاشة لعرض جميع الأوضاع لاحقاً
                        Navigator.of(context).pushNamed('/all-custom-modes');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('عرض الكل (${sortedModes.length})'),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ListView أفقي
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: displayModes.length,
                itemBuilder: (context, index) {
                  final mode = displayModes[index];
                  return SavedCustomModeCard(mode: mode);
                },
              ),
            ),

            const SizedBox(height: 8),

            // معلومة إضافية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'اضغط على البطاقة لتفعيل الوضع',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
