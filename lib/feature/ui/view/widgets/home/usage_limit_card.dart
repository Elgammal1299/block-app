import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/DI/setup_get_it.dart';
import '../../../view_model/usage_limit_cubit/usage_limit_cubit.dart';
import '../../../view_model/usage_limit_cubit/usage_limit_state.dart';

/// بطاقة "حد الاستخدام اليومي" المستقلة في الصفحة الرئيسية
/// تعرض عدد التطبيقات المحددة وتسمح بالانتقال لإدارة الحدود
class UsageLimitCard extends StatelessWidget {
  const UsageLimitCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<UsageLimitCubit, UsageLimitState>(
      bloc: getIt<UsageLimitCubit>(),
      builder: (context, state) {
        // عد التطبيقات التي لها حدود
        final limitsCount = state is UsageLimitLoaded
            ? state.limits.length
            : 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              // سيتم تحديث هذا لاحقاً عند إضافة الـ route
              Navigator.of(context).pushNamed('/usage-limit-selection');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.orange.shade700.withValues(alpha: 0.2),
                          Colors.deepOrange.shade800.withValues(alpha: 0.15),
                        ]
                      : [
                          Colors.orange.shade50,
                          Colors.deepOrange.shade50,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // أيقونة المؤقت
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 32,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // النص والوصف
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حد الاستخدام اليومي',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          limitsCount > 0
                              ? '$limitsCount ${limitsCount == 1 ? 'تطبيق محدد' : 'تطبيقات محددة'}'
                              : 'حدد وقت استخدام لكل تطبيق',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge مع العدد
                  if (limitsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$limitsCount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.orange.shade700.withValues(alpha: 0.5),
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
