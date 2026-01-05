import 'package:flutter/material.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/focus_session_cubit/focus_session_cubit.dart';
import '../widgets/focus_mode_card.dart';
import '../../../../core/router/app_routes.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.focusMode.displayName),
        backgroundColor: widget.focusMode.color.withOpacity(0.1),
        foregroundColor: widget.focusMode.color,
        elevation: 0,
        actions: [
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.focusMode.color.withOpacity(0.2),
                  widget.focusMode.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.focusMode.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.focusMode.icon,
                        color: widget.focusMode.color,
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
                              color: widget.focusMode.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(widget.focusMode.duration),
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.focusMode.color.withOpacity(0.8),
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
                                activeColor: widget.focusMode.color,
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
                                    activeColor: widget.focusMode.color,
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
                                    color: widget.focusMode.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.focusMode.color.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$_customMinutes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.focusMode.color,
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
                        color: widget.focusMode.color,
                      ),
                      title: const Text('تخصيص التطبيقات المحظورة'),
                      subtitle: const Text('اختر التطبيقات التي تريد حظرها في هذا الوضع'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.appSelectionForQuickBlock,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                  backgroundColor: widget.focusMode.color,
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
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.focusMode.color,
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
                color: widget.focusMode.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: widget.focusMode.color,
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
              activeColor: widget.focusMode.color,
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
      case FocusModeType.meTime:
        return 'وقت للاسترخاء والاهتمام بالنفس بدون مقاطعات. مثالي للتأمل والهوايات.';
      case FocusModeType.deepWork:
        return 'حظر جميع التطبيقات للتركيز العميق. الأفضل للمشاريع التي تتطلب تركيزًا كاملاً.';
    }
  }

  void _startFocusMode() {
    final duration = _customDuration 
        ? Duration(minutes: _customMinutes)
        : widget.focusMode.duration;
    
    // TODO: Start focus session with settings
    final focusSessionCubit = getIt<FocusSessionCubit>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بدأ ${widget.focusMode.displayName} لمدة ${_formatDuration(duration)}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'إلغاء',
          onPressed: () {
            // TODO: Cancel focus session
            focusSessionCubit.cancelSession();
          },
        ),
      ),
    );
    
    Navigator.of(context).pop();
  }
}
