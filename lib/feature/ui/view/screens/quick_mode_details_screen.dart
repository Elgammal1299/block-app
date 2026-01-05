import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../view_model/focus_mode_config_cubit/focus_mode_config_cubit.dart';
import '../../view_model/focus_mode_config_cubit/focus_mode_config_state.dart';
import '../widgets/focus_mode_card.dart';
import '../../../../core/router/app_routes.dart';
import '../../../data/models/focus_mode_config.dart';
import '../../../data/models/focus_mode_schedule.dart';

class QuickModeDetailsScreen extends StatefulWidget {
  final FocusModeType focusMode;

  const QuickModeDetailsScreen({
    super.key,
    required this.focusMode,
  });

  @override
  State<QuickModeDetailsScreen> createState() => _QuickModeDetailsScreenState();
}

class _QuickModeDetailsScreenState extends State<QuickModeDetailsScreen> {
  bool _addNewlyInstalledApps = false;
  bool _blockUnsupportedBrowsers = false;
  bool _blockAdultSites = false;
  bool _customDuration = false;
  int _customMinutes = 25;
  int _blockedAppsCount = 0;

  // جدولة تلقائية
  bool _scheduleEnabled = false;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 21, minute: 0);
  Set<int> _selectedDays = {1, 2, 3, 4, 5}; // الاثنين-الجمعة

  // Pomodoro
  bool _pomodoroEnabled = false;
  int _pomodoroWorkMinutes = 25;
  int _pomodoroBreakMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _loadBlockedAppsCount();
  }

  Future<void> _loadSavedSettings() async {
    final configCubit = getIt<FocusModeConfigCubit>();
    final config = configCubit.getConfigForMode(widget.focusMode);

    if (config != null) {
      setState(() {
        _addNewlyInstalledApps = config.addNewlyInstalledApps;
        _blockUnsupportedBrowsers = config.blockUnsupportedBrowsers;
        _blockAdultSites = config.blockAdultSites;
        _customDuration = !config.useDefaultDuration;
        _customMinutes = config.customDurationMinutes;

        // تحميل إعدادات الجدولة
        if (config.schedules.isNotEmpty) {
          final schedule = config.schedules.first;
          _scheduleEnabled = schedule.isEnabled;
          _scheduleTime = schedule.startTime;
          _selectedDays = schedule.daysOfWeek.toSet();
        }

        // تحميل إعدادات Pomodoro
        _pomodoroEnabled = config.pomodoroEnabled;
        _pomodoroWorkMinutes = config.pomodoroWorkMinutes;
        _pomodoroBreakMinutes = config.pomodoroBreakMinutes;
      });
    }
  }

  Future<void> _loadBlockedAppsCount() async {
    final configCubit = getIt<FocusModeConfigCubit>();
    final count = await configCubit.getBlockedAppsCount(widget.focusMode);
    setState(() {
      _blockedAppsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Use theme primary color

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.focusMode.displayName),
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          // زر إعادة التعيين (يظهر فقط إذا كان الوضع مخصص)
          BlocBuilder<FocusModeConfigCubit, FocusModeConfigState>(
            bloc: getIt<FocusModeConfigCubit>(),
            builder: (context, state) {
              if (state is FocusModeConfigLoaded) {
                final config = state.getConfig(widget.focusMode);
                if (config?.isCustomized == true) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'إعادة تعيين للإعدادات الأصلية',
                    onPressed: () => _showResetDialog(context),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1), // Solid color instead of gradient
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.focusMode.icon,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.focusMode.displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(widget.focusMode.duration),
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getDescription(widget.focusMode),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration Settings
                  _buildSectionHeader(context, 'المدة'),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'استخدم المدة الافتراضية',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Switch(
                                value: !_customDuration,
                                onChanged: (value) {
                                  setState(() {
                                    _customDuration = !value;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                            ],
                          ),
                          if (_customDuration) ...[
                            const SizedBox(height: 16),
                            Text(
                              'مدة مخصصة (دقائق)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _customMinutes.toDouble(),
                                    min: 5,
                                    max: 180,
                                    divisions: 35,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _customMinutes = value.round();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$_customMinutes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'المدة الافتراضية: ${_formatDuration(widget.focusMode.duration)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Block List Section
                  _buildSectionHeader(context, 'قائمة الحظر'),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.block,
                        color: primaryColor,
                      ),
                      title: const Text('تخصيص التطبيقات المحظورة'),
                      subtitle: Text(
                        _blockedAppsCount > 0
                            ? 'محددة: $_blockedAppsCount تطبيق'
                            : 'اختر التطبيقات التي تريد حظرها في هذا الوضع',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_blockedAppsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_blockedAppsCount',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () async {
                        final result = await Navigator.of(context).pushNamed(
                          AppRoutes.focusModeAppSelection,
                          arguments: widget.focusMode,
                        );

                        // إعادة تحميل عدد التطبيقات بعد الرجوع
                        if (result == true) {
                          await _loadBlockedAppsCount();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Schedule Section
                  _buildSectionHeader(context, 'جدولة تلقائية'),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'بدء تلقائي في وقت محدد',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'سيبدأ هذا الوضع تلقائياً في الوقت المحدد',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _scheduleEnabled,
                                onChanged: (value) {
                                  setState(() => _scheduleEnabled = value);
                                },
                                activeColor: primaryColor,
                              ),
                            ],
                          ),

                          if (_scheduleEnabled) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // وقت البدء
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _scheduleTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: primaryColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setState(() => _scheduleTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, color: primaryColor),
                                    const SizedBox(width: 12),
                                    Text(
                                      'الوقت: ${_scheduleTime.format(context)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.edit, color: primaryColor, size: 20),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // أيام الأسبوع
                            Text(
                              'الأيام',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (int day = 1; day <= 7; day++)
                                  _buildDayChip(day, primaryColor),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pomodoro Section (فقط لأوضاع الدراسة والعمل)
                  if (widget.focusMode == FocusModeType.study ||
                      widget.focusMode == FocusModeType.work) ...[
                    _buildSectionHeader(context, 'البومودورو'),
                    const SizedBox(height: 12),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer, color: primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تفعيل البومودورو',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'استراحات منتظمة لزيادة التركيز والإنتاجية',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _pomodoroEnabled,
                                  onChanged: (value) {
                                    setState(() => _pomodoroEnabled = value);
                                  },
                                  activeColor: primaryColor,
                                ),
                              ],
                            ),

                            if (_pomodoroEnabled) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),

                              // مدة العمل
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'مدة العمل',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<int>(
                                          value: _pomodoroWorkMinutes,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          items: [25, 30, 45, 50, 60]
                                              .map((m) => DropdownMenuItem(
                                                    value: m,
                                                    child: Text('$m دقيقة'),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() => _pomodoroWorkMinutes = value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'مدة الاستراحة',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<int>(
                                          value: _pomodoroBreakMinutes,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          items: [5, 10, 15, 20]
                                              .map((m) => DropdownMenuItem(
                                                    value: m,
                                                    child: Text('$m دقيقة'),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() => _pomodoroBreakMinutes = value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ستظهر إشعارات عند حلول وقت الاستراحة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Additional Options Section
                  _buildSectionHeader(context, 'خيارات إضافية'),
                  const SizedBox(height: 12),
                  
                  // Add newly installed apps
                  _buildOptionCard(
                    context,
                    'إضافة التطبيقات المثبتة حديثا',
                    'في حالة التشغيل، سيتم حظر التطبيقات المثبتة حديثا تلقائيا.',
                    Icons.apps,
                    _addNewlyInstalledApps,
                    (value) => setState(() => _addNewlyInstalledApps = value),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Block unsupported browsers
                  _buildOptionCard(
                    context,
                    'حظر المتصفحات غير المدعومة',
                    'إذا تعذر حظر مواقع الويب في متصفح، سيتم حظر المتصفح بدلاً من ذلك.',
                    Icons.language,
                    _blockUnsupportedBrowsers,
                    (value) => setState(() => _blockUnsupportedBrowsers = value),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Block adult sites
                  _buildOptionCard(
                    context,
                    'حظر المواقع الإباحية',
                    'يتم اكتشاف المواقع الإباحية وحظرها تلقائيا في جميع المتصفحات التي تستخدمها.',
                    Icons.block,
                    _blockAdultSites,
                    (value) => setState(() => _blockAdultSites = value),
                  ),
                ],
              ),
            ),
          ),
          
          // Start Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startFocusMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'بدء ${widget.focusMode.displayName}',
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.diamond,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ساعة${duration.inHours > 1 ? '' : ''}';
    } else {
      return '${duration.inMinutes} دقيقة';
    }
  }

  String _getDescription(FocusModeType mode) {
    switch (mode) {
      case FocusModeType.study:
        return 'حظر جميع التطبيقات المشتتة للتركيز في الدراسة. الأفضل للمذاكرة والقراءة والعمل الأكاديمي.';
      case FocusModeType.work:
        return 'السماح بالتطبيقات الضرورية فقط للعمل. مثالي لزيادة الإنتاجية في مكان العمل.';
      case FocusModeType.sleep:
        return 'تقليل الضوء الأزرق والتنبيهات لتحسين النوم. يساعد على الاسترخاء والنوم العميق.';
      // case FocusModeType.meTime:
      //   return 'وقت للاسترخاء والاهتمام بالنفس بدون مقاطعات. مثالي للتأمل والهوايات.';
      // case FocusModeType.deepWork:
      //   return 'حظر جميع التطبيقات للتركيز العميق. الأفضل للمشاريع التي تتطلب تركيزًا كاملاً.';
    }
  }

  Future<void> _startFocusMode() async {
    // 1. الحصول على الإعدادات
    final configCubit = getIt<FocusModeConfigCubit>();
    final config = configCubit.getConfigForMode(widget.focusMode);

    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم العثور على إعدادات الوضع'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. تحديد المدة
    final duration = _customDuration
        ? Duration(minutes: _customMinutes)
        : widget.focusMode.duration;

    // 3. بدء الجلسة الفعلية
    final focusSessionCubit = getIt<FocusSessionCubit>();
    final success = await focusSessionCubit.startSession(
      config.focusListId,
      duration.inMinutes,
    );

    // 4. معالجة النتيجة
    if (success) {
      // حفظ التخصيصات إذا تم التعديل
      if (_customDuration || _hasSettingsChanged()) {
        await _saveCustomizations(config);
      }

      // تحديث آخر استخدام
      await configCubit.updateLastUsed(widget.focusMode);

      // إغلاق الشاشة
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('بدأ ${widget.focusMode.displayName} بنجاح ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل بدء الوضع. يرجى المحاولة مرة أخرى.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCustomizations(FocusModeConfig config) async {
    // إنشاء schedule إذا كان مفعّل
    final schedules = <FocusModeSchedule>[];
    if (_scheduleEnabled) {
      schedules.add(FocusModeSchedule(
        id: 'schedule_${widget.focusMode.name}_${DateTime.now().millisecondsSinceEpoch}',
        isEnabled: true,
        startTime: _scheduleTime,
        daysOfWeek: _selectedDays.toList()..sort(),
        autoStart: true,
      ));
    }

    final updatedConfig = config.copyWith(
      customDurationMinutes: _customMinutes,
      useDefaultDuration: !_customDuration,
      addNewlyInstalledApps: _addNewlyInstalledApps,
      blockUnsupportedBrowsers: _blockUnsupportedBrowsers,
      blockAdultSites: _blockAdultSites,
      pomodoroEnabled: _pomodoroEnabled,
      pomodoroWorkMinutes: _pomodoroWorkMinutes,
      pomodoroBreakMinutes: _pomodoroBreakMinutes,
      schedules: schedules,
      isCustomized: true,
    );

    await getIt<FocusModeConfigCubit>().updateConfig(updatedConfig);
  }

  bool _hasSettingsChanged() {
    return _addNewlyInstalledApps ||
           _blockUnsupportedBrowsers ||
           _blockAdultSites;
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.refresh, color: primaryColor),
            const SizedBox(width: 8),
            const Text('إعادة تعيين'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل تريد إعادة تعيين هذا الوضع للإعدادات الأصلية؟',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم استرجاع القائمة الذكية الأصلية للتطبيقات والإعدادات الافتراضية',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetToDefaults();
    }
  }

  Future<void> _resetToDefaults() async {
    final configCubit = getIt<FocusModeConfigCubit>();

    // عرض loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // إعادة التعيين
      await configCubit.resetModeToDefault(widget.focusMode);

      // إعادة تحميل عدد التطبيقات
      await _loadBlockedAppsCount();

      // إعادة تعيين الإعدادات المحلية
      setState(() {
        _addNewlyInstalledApps = false;
        _blockUnsupportedBrowsers = false;
        _blockAdultSites = false;
        _customDuration = false;
        _customMinutes = widget.focusMode.duration.inMinutes;
      });

      // إغلاق loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إعادة تعيين ${widget.focusMode.displayName} للإعدادات الأصلية ✓'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // إغلاق loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // عرض رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة التعيين: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildDayChip(int day, Color primaryColor) {
    final isSelected = _selectedDays.contains(day);
    final dayNames = {
      1: 'الاثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };

    return FilterChip(
      label: Text(
        dayNames[day]!,
        style: TextStyle(
          color: isSelected ? Colors.white : primaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            if (_selectedDays.length > 1) {
              // لا نسمح بإلغاء كل الأيام
              _selectedDays.remove(day);
            }
          }
        });
      },
      selectedColor: primaryColor,
      backgroundColor: primaryColor.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? primaryColor
              : primaryColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
