import 'package:flutter/material.dart';
import '../../../../../../core/DI/setup_get_it.dart';
import '../../../../data/models/custom_focus_mode.dart';
import '../../../view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';

/// بطاقة لعرض وضع مخصص واحد محفوظ
/// تحتوي على: الاسم، نوع الحظر، عدد التطبيقات، أزرار التعديل/الحذف/التفعيل
class SavedCustomModeCard extends StatelessWidget {
  final CustomFocusMode mode;

  const SavedCustomModeCard({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // تفعيل الوضع مباشرة
          _activateMode(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصف العلوي: الأيقونة والقائمة المنسدلة
              Row(
                children: [
                  // أيقونة الوضع
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      mode.icon,
                      size: 24,
                      color: _getTypeColor(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // الاسم
                  Expanded(
                    child: Text(
                      mode.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // قائمة الخيارات (تعديل/حذف)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMode(context);
                      } else if (value == 'delete') {
                        _deleteMode(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // نوع الحظر
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getTypeColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CustomFocusMode.getIconForBlockType(mode.blockType),
                      size: 14,
                      color: _getTypeColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      CustomFocusMode.getBlockTypeName(mode.blockType),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // الوصف
              Text(
                mode.getDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // الصف السفلي: عدد التطبيقات وزر التفعيل
              Row(
                children: [
                  // عدد التطبيقات
                  Icon(
                    Icons.apps,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${mode.blockedPackages.length} تطبيق',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  const Spacer(),

                  // زر التفعيل
                  ElevatedButton(
                    onPressed: () => _activateMode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 18),
                        SizedBox(width: 4),
                        Text('تفعيل'),
                      ],
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

  /// الحصول على لون حسب نوع الحظر
  Color _getTypeColor() {
    switch (mode.blockType) {
      case CustomModeBlockType.fullBlock:
        return Colors.red.shade600;

      case CustomModeBlockType.timeBased:
        return Colors.blue.shade600;

      case CustomModeBlockType.usageLimit:
        return Colors.orange.shade600;
    }
  }

  /// تفعيل الوضع
  void _activateMode(BuildContext context) {
    // سيتم تطبيق هذا لاحقاً عند ربطه بـ FocusSessionCubit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم تفعيل وضع "${mode.name}" قريباً'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // تحديث آخر استخدام
    getIt<CustomFocusModeCubit>().updateLastUsed(mode.id);
  }

  /// تعديل الوضع
  void _editMode(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/edit-custom-mode',
      arguments: mode,
    );
  }

  /// حذف الوضع مع تأكيد
  void _deleteMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف الوضع'),
        content: Text('هل أنت متأكد من حذف وضع "${mode.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              getIt<CustomFocusModeCubit>().deleteCustomMode(mode.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الوضع بنجاح'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }
}
