import 'package:block_app/feature/ui/view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';
import 'package:block_app/feature/ui/view_model/custom_focus_mode_cubit/custom_focus_mode_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/DI/setup_get_it.dart';
import '../../../../../../core/router/app_routes.dart';
// import '../../../../view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';
// import '../../../../view_model/custom_focus_mode_cubit/custom_focus_mode_state.dart';

/// بطاقة "إنشاء وضع مخصص" في الصفحة الرئيسية
/// تسمح للمستخدم بالضغط لإنشاء وضع تركيز مخصص جديد
class CustomModeCard extends StatelessWidget {
  const CustomModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CustomFocusModeCubit, CustomFocusModeState>(
      bloc: getIt<CustomFocusModeCubit>(),
      builder: (context, state) {
        // عرض عدد الأوضاع المخصصة المحفوظة
        final modesCount = state is CustomFocusModeLoaded ? state.modes.length : 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Navigator.of(context).pushNamed(AppRoutes.createCustomMode);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.secondary.withOpacity(0.10),
                        ]
                      : [
                          theme.colorScheme.primary.withOpacity(0.08),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // أيقونة "إضافة"
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // النص والوصف
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وضع مخصص +',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          modesCount > 0
                              ? 'لديك $modesCount ${modesCount == 1 ? 'وضع محفوظ' : 'أوضاع محفوظة'}'
                              : 'أنشئ وضع تركيز خاص بك',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أيقونة السهم
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: theme.colorScheme.primary.withOpacity(0.5),
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
