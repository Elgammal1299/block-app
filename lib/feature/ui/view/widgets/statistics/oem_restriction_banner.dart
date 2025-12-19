import 'package:flutter/material.dart';

/// Banner widget to inform users about potential OEM restrictions
/// that may affect usage statistics accuracy
class OEMRestrictionBanner extends StatelessWidget {
  final String manufacturer;
  final EdgeInsetsGeometry margin;

  const OEMRestrictionBanner({
    super.key,
    required this.manufacturer,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة: قد تتأخر بعض البيانات',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMessageForManufacturer(manufacturer),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageForManufacturer(String manufacturer) {
    if (manufacturer.contains('xiaomi')) {
      return 'أجهزة Xiaomi قد تؤخر تتبع الاستخدام بسبب قيود النظام. البيانات دقيقة لكن قد تظهر متأخرة.';
    } else if (manufacturer.contains('huawei')) {
      return 'أجهزة Huawei قد تحد من تتبع التطبيقات في الخلفية. تأكد من السماح للتطبيق بالعمل في الخلفية.';
    } else if (manufacturer.contains('oppo') || manufacturer.contains('realme')) {
      return 'أجهزة OPPO/Realme قد تقيد الخدمات الخلفية. البيانات تُحدّث كل فترة وليس real-time.';
    } else if (manufacturer.contains('vivo')) {
      return 'أجهزة Vivo قد تؤخر تحديث البيانات بسبب إدارة الطاقة. الإحصائيات دقيقة عند التحديث.';
    } else if (manufacturer.contains('oneplus')) {
      return 'أجهزة OnePlus قد تحد من تتبع الاستخدام. تأكد من تعطيل تحسين البطارية للتطبيق.';
    } else {
      return 'بعض البيانات قد تظهر متأخرة بسبب قيود النظام. الإحصائيات دقيقة عند التحديث.';
    }
  }
}
