import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../../../core/router/app_routes.dart';

class QuickBlockSettingsScreen extends StatefulWidget {
  const QuickBlockSettingsScreen({super.key});

  @override
  State<QuickBlockSettingsScreen> createState() => _QuickBlockSettingsScreenState();
}

class _QuickBlockSettingsScreenState extends State<QuickBlockSettingsScreen> {
  bool _addNewlyInstalledApps = false;
  bool _blockUnsupportedBrowsers = false;
  bool _blockAdultSites = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ضبط الحظر السريع'),
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
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
          // Header description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue[50],
            child: Text(
              'هذه الإعدادات تنطبق في كل مرة تبدأ فيها حظرًا سريعًا أو مؤقتًا أو جلسة بومودورو.',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Block List Section
                  _buildSectionHeader(context, 'قائمة الحظر'),
                  const SizedBox(height: 12),
                  
                  // Add something to block card
                  BlocBuilder<BlockedAppsCubit, BlockedAppsState>(
                    bloc: getIt<BlockedAppsCubit>(),
                    builder: (context, state) {
                      final blockedAppsCount = state is BlockedAppsLoaded 
                          ? state.blockedApps.length 
                          : 0;
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أضف شيء لحظره',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                blockedAppsCount > 0
                                    ? 'تم تحديد $blockedAppsCount تطبيق'
                                    : 'لم يتم تحديد أي تطبيقات أو مواقع',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.appSelectionForQuickBlock,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('أضف'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Copy from section
                  _buildSectionHeader(context, 'نسخ من'),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.copy,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('نسخ الإعدادات من جدول موجود'),
                      subtitle: const Text('اختر جدول لنسخ إعدادات الحظر منه'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to schedule selection
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('قريباً')),
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
          
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
            color: theme.colorScheme.primary,
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
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
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
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
}
