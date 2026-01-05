import 'package:flutter/material.dart';
import '../focus_mode_card.dart';

/// بطاقة مميزة للأوضاع الجاهزة (Sleep & Work)
/// تصميم أكبر وأكثر بروزاً من البطاقات الأخرى
class PresetModeCard extends StatelessWidget {
  final FocusModeType modeType;

  const PresetModeCard({
    super.key,
    required this.modeType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ألوان خاصة لكل وضع
    final colors = _getModeColors(isDark);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // سيتم ربطه بشاشة تفاصيل الوضع لاحقاً
          Navigator.of(context).pushNamed(
            '/quick-mode-details',
            arguments: modeType,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: الأيقونة والعنوان
              Row(
                children: [
                  // أيقونة كبيرة
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getIconColor().withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      modeType.icon,
                      size: 40,
                      color: _getIconColor(),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // العنوان والوصف
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modeType.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDescription(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(isDark).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أيقونة السهم
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 24,
                    color: _getTextColor(isDark).withValues(alpha: 0.5),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // معلومات إضافية
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _getTextColor(isDark).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getDurationText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTextColor(isDark).withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الحصول على ألوان التدرج حسب نوع الوضع
  List<Color> _getModeColors(bool isDark) {
    switch (modeType) {
      case FocusModeType.sleep:
        return isDark
            ? [
                Colors.indigo.shade900.withValues(alpha: 0.6),
                Colors.purple.shade900.withValues(alpha: 0.5),
              ]
            : [
                Colors.indigo.shade100,
                Colors.purple.shade100,
              ];

      case FocusModeType.work:
        return isDark
            ? [
                Colors.blue.shade900.withValues(alpha: 0.6),
                Colors.cyan.shade900.withValues(alpha: 0.5),
              ]
            : [
                Colors.blue.shade100,
                Colors.cyan.shade100,
              ];
      case FocusModeType.study:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// لون خلفية الأيقونة
  Color _getIconBackgroundColor(bool isDark) {
    switch (modeType) {
      case FocusModeType.sleep:
        return isDark
            ? Colors.indigo.shade800.withValues(alpha: 0.4)
            : Colors.white;

      case FocusModeType.work:
        return isDark
            ? Colors.blue.shade800.withValues(alpha: 0.4)
            : Colors.white;
      case FocusModeType.study:

        return isDark
            ? Colors.green.shade800.withValues(alpha: 0.4)
            : Colors.white;
    }
  }

  /// لون الأيقونة
  Color _getIconColor() {
    switch (modeType) {
      case FocusModeType.sleep:
        return Colors.indigo.shade400;

      case FocusModeType.work:
        return Colors.blue.shade600;
      case FocusModeType.study:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// لون النص
  Color _getTextColor(bool isDark) {
    switch (modeType) {
      case FocusModeType.sleep:
        return isDark ? Colors.indigo.shade200 : Colors.indigo.shade900;

      case FocusModeType.work:
        return isDark ? Colors.blue.shade200 : Colors.blue.shade900;
      case FocusModeType.study:
        return isDark ? Colors.green.shade200 : Colors.green.shade900;
    }
  }

  /// الوصف التفصيلي للوضع
  String _getDescription() {
    switch (modeType) {
      case FocusModeType.sleep:
        return 'حظر جميع التطبيقات ما عدا الأساسيات';

      case FocusModeType.work:
        return 'حظر الألعاب والترفيه للتركيز';
        
      case FocusModeType.study:
        return 'حظر الألعاب والترفيه للتركيز';
    }
  }

  /// نص المدة الزمنية
  String _getDurationText() {
    final duration = modeType.duration;
    if (duration.inHours > 0) {
      return '${duration.inHours} ساعة افتراضي';
    } else {
      return '${duration.inMinutes} دقيقة افتراضي';
    }
  }
}
