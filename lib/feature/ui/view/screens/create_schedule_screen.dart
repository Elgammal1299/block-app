import 'package:flutter/material.dart';
import '../../../../core/router/app_routes.dart';
import '../../../data/models/blocked_app.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  List<BlockedApp> _selectedApps = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Default: weekdays

  bool get _canProceed =>
      _selectedApps.isNotEmpty && _startTime != null && _endTime != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جدول جديد',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'خطوات بسيطة لتنظيم وقتك',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildProgressDot(1, _selectedApps.isNotEmpty),
                  _buildProgressLine(_selectedApps.isNotEmpty),
                  _buildProgressDot(2, _startTime != null && _endTime != null),
                  _buildProgressLine(_startTime != null && _endTime != null),
                  _buildProgressDot(3, _selectedDays.isNotEmpty),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Step 1: Apps
                    _buildModernStepCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.apps_rounded,
                      title: 'اختر التطبيقات',
                      description: _selectedApps.isEmpty
                          ? 'حدد التطبيقات التي تريد حظرها'
                          : '${_selectedApps.length} تطبيق محدد ✓',
                      isCompleted: _selectedApps.isNotEmpty,
                      onTap: () async {
                        await Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.appSelection);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Step 2: Time
                    _buildModernStepCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.access_time_rounded,
                      title: 'حدد الوقت',
                      description: _startTime != null && _endTime != null
                          ? '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}'
                          : 'متى تريد تفعيل الحظر؟',
                      isCompleted: _startTime != null && _endTime != null,
                      onTap: _showTimeSelectionDialog,
                    ),

                    const SizedBox(height: 20),

                    // Step 3: Days
                    _buildModernStepCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.calendar_month_rounded,
                      title: 'اختر الأيام',
                      description: _formatDays(_selectedDays.toList()),
                      isCompleted: _selectedDays.isNotEmpty,
                      onTap: _showDaysSelectionDialog,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _createSchedule : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: _canProceed ? 8 : 0,
                      shadowColor: _canProceed
                          ? const Color(0xFF1877F2).withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _canProceed
                              ? Icons.rocket_launch_rounded
                              : Icons.lock_outline_rounded,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _canProceed
                              ? 'إنشاء الجدول الآن!'
                              : 'أكمل الخطوات أولاً',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int step, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              )
            : null,
        color: isCompleted ? null : Colors.grey.shade200,
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: isCompleted
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          color: isCompleted ? null : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildModernStepCard({
    required Gradient gradient,
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted ? 'تعديل' : 'ابدأ الآن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: gradient.colors.first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: gradient.colors.first,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimeSelectionDialog() async {
    TimeOfDay? start = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? end = _endTime ?? const TimeOfDay(hour: 17, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تحديد الوقت',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeSelector(
                label: 'وقت البداية',
                time: start,
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFF093FB),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: start!,
                  );
                  if (picked != null) {
                    setDialogState(() => start = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildTimeSelector(
                label: 'وقت النهاية',
                time: end,
                icon: Icons.nightlight_round,
                color: const Color(0xFFF5576C),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: end!,
                  );
                  if (picked != null) {
                    setDialogState(() => end = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _startTime = start;
                  _endTime = end;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF093FB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null ? _formatTime(time) : '--:--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showDaysSelectionDialog() async {
    Set<int> tempDays = Set.from(_selectedDays);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'اختر الأيام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildModernDayChip('الإثنين', 1, tempDays, setDialogState),
                  _buildModernDayChip('الثلاثاء', 2, tempDays, setDialogState),
                  _buildModernDayChip('الأربعاء', 3, tempDays, setDialogState),
                  _buildModernDayChip('الخميس', 4, tempDays, setDialogState),
                  _buildModernDayChip('الجمعة', 5, tempDays, setDialogState),
                  _buildModernDayChip('السبت', 6, tempDays, setDialogState),
                  _buildModernDayChip('الأحد', 7, tempDays, setDialogState),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton(
                    'أيام العمل',
                    {1, 2, 3, 4, 5},
                    tempDays,
                    setDialogState,
                  ),
                  _buildPresetButton(
                    'عطلة نهاية الأسبوع',
                    {6, 7},
                    tempDays,
                    setDialogState,
                  ),
                  _buildPresetButton(
                    'كل يوم',
                    {1, 2, 3, 4, 5, 6, 7},
                    tempDays,
                    setDialogState,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: tempDays.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _selectedDays = tempDays;
                      });
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FACFE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDayChip(
    String label,
    int day,
    Set<int> selectedDays,
    StateSetter setDialogState,
  ) {
    final isSelected = selectedDays.contains(day);
    return InkWell(
      onTap: () {
        setDialogState(() {
          if (isSelected) {
            selectedDays.remove(day);
          } else {
            selectedDays.add(day);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(
    String label,
    Set<int> days,
    Set<int> selectedDays,
    StateSetter setDialogState,
  ) {
    return OutlinedButton(
      onPressed: () {
        setDialogState(() {
          selectedDays.clear();
          selectedDays.addAll(days);
        });
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF4FACFE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDays(List<int> days) {
    final dayNames = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };

    if (days.length == 7) {
      return 'كل يوم 🎯';
    } else if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'أيام العمل 💼';
    } else if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'عطلة نهاية الأسبوع 🎉';
    } else {
      final sortedDays = List<int>.from(days)..sort();
      return sortedDays.map((d) => dayNames[d]).join('، ');
    }
  }

  void _createSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'تم إنشاء الجدول بنجاح! 🎉',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    Navigator.pop(context);
  }
}
