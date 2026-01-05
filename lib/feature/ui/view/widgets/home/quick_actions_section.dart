import 'package:flutter/material.dart';
import 'quick_action_button.dart';
import '../../../../../core/router/app_routes.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.flash_on,
            label: 'حظر سريع',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.appSelection);
            },
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.timer,
            label: 'مؤقت التركيز',
            onTap: () {
              _showFocusTimerDialog(context);
            },
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.schedule,
            label: 'الجداول',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.schedules);
            },
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  void _showFocusTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مؤقت التركيز'),
        content: const Text('اختر مدة جلسة التركيز'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Start 25-minute focus session
            },
            child: const Text('25 دقيقة'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Start 50-minute focus session
            },
            child: const Text('50 دقيقة'),
          ),
        ],
      ),
    );
  }
}
