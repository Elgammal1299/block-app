import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../../core/utils/app_logger.dart';
import '../../view_model/app_list_cubit/app_list_cubit.dart';
import '../../view_model/app_list_cubit/app_list_state.dart';
import '../../view_model/focus_mode_config_cubit/focus_mode_config_cubit.dart';
import '../widgets/focus_mode_card.dart';
import '../widgets/app_category_filter.dart';
import '../../../data/models/app_info.dart';
import '../../../data/repositories/focus_mode_config_repository.dart';

class FocusModeAppSelectionScreen extends StatefulWidget {
  final FocusModeType focusMode;

  const FocusModeAppSelectionScreen({
    Key? key,
    required this.focusMode,
  }) : super(key: key);

  @override
  State<FocusModeAppSelectionScreen> createState() =>
      _FocusModeAppSelectionScreenState();
}

class _FocusModeAppSelectionScreenState
    extends State<FocusModeAppSelectionScreen> {
  final Set<String> _selectedPackages = {};
  AppCategory _selectedCategory = AppCategory.all;
  bool _showSystemApps = false;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  Future<void> _loadCurrentSelection() async {
    setState(() => _isLoading = true);

    try {
      // تحميل التطبيقات المحددة حالياً لهذا الوضع
      final configRepo = getIt<FocusModeConfigRepository>();
      final focusList = await configRepo.getFocusListForMode(widget.focusMode);

      if (focusList != null) {
        setState(() {
          _selectedPackages.addAll(focusList.packageNames);
        });
      }
    } catch (e) {
      AppLogger.e('Error loading current selection', e);
    } finally {
      setState(() => _isLoading = false);
    }

    // تحميل قائمة التطبيقات
    final appListCubit = getIt<AppListCubit>();
    if (appListCubit.state is! AppListLoaded) {
      await appListCubit.loadInstalledApps();
    }
  }

  void _toggleApp(AppInfo app) {
    setState(() {
      if (_selectedPackages.contains(app.packageName)) {
        _selectedPackages.remove(app.packageName);
      } else {
        _selectedPackages.add(app.packageName);
      }
    });
  }

  Future<void> _saveSelection() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تطبيق واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final configCubit = getIt<FocusModeConfigCubit>();
      await configCubit.customizeModeApps(
        widget.focusMode,
        _selectedPackages.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // إرجاع true للإشارة إلى النجاح

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم حفظ ${_selectedPackages.length} تطبيق لوضع ${widget.focusMode.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AppInfo> _filterApps(List<AppInfo> apps) {
    var filtered = apps;

    // Filter by system apps
    if (!_showSystemApps) {
      filtered = filtered.where((app) => !app.isSystemApp).toList();
    }

    // Filter by category
    if (_selectedCategory != AppCategory.all) {
      filtered = AppCategoryHelper.filterAppsByCategory(
        filtered,
        _selectedCategory,
      );
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((app) =>
              app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.packageName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('تخصيص ${widget.focusMode.displayName}'),
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (_selectedPackages.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedPackages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: primaryColor.withValues(alpha: 0.05),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'البحث عن تطبيق...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AppCategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                ),

                // System Apps Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'عرض تطبيقات النظام',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _showSystemApps,
                        onChanged: (value) {
                          setState(() {
                            _showSystemApps = value;
                          });
                        },
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Apps List
                Expanded(
                  child: BlocBuilder<AppListCubit, AppListState>(
                    bloc: getIt<AppListCubit>(),
                    builder: (context, state) {
                      if (state is AppListLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is AppListError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'خطأ في تحميل التطبيقات',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is AppListLoaded) {
                        final filteredApps = _filterApps(state.apps);

                        if (filteredApps.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد تطبيقات',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final isSelected =
                                _selectedPackages.contains(app.packageName);
                            final category = AppCategoryHelper.getAppCategory(app);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (checked) => _toggleApp(app),
                              title: Text(app.appName),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 14,
                                    color: category.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    category.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: category.color,
                                    ),
                                  ),
                                ],
                              ),
                              secondary: app.icon != null
                                  ? Image.memory(
                                      app.icon!,
                                      width: 40,
                                      height: 40,
                                    )
                                  : const Icon(Icons.android, size: 40),
                              activeColor: primaryColor,
                              checkColor: Colors.white,
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedPackages.isEmpty ? null : _saveSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              'حفظ (${_selectedPackages.length} تطبيق)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
