import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/app_list_cubit/app_list_cubit.dart';
import '../../view_model/app_list_cubit/app_list_state.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_cubit.dart';
import '../../view_model/blocked_apps_cubit/blocked_apps_state.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/blocked_app.dart';
import '../widgets/app_category_filter.dart';

class AppSelectionQuickBlockScreen extends StatefulWidget {
  const AppSelectionQuickBlockScreen({super.key});

  @override
  State<AppSelectionQuickBlockScreen> createState() => _AppSelectionQuickBlockScreenState();
}

class _AppSelectionQuickBlockScreenState extends State<AppSelectionQuickBlockScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedPackages = {};
  late TabController _tabController;
  final Map<AppCategory, bool> _expandedCategories = {};

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize all categories as collapsed
    for (var category in AppCategory.values) {
      if (category != AppCategory.all) {
        _expandedCategories[category] = false;
      }
    }
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final appListCubit = getIt<AppListCubit>();
    final blockedAppsCubit = getIt<BlockedAppsCubit>();

    // Start loading apps (don't await - let it load in background)
    appListCubit.loadInstalledApps();

    // Load currently blocked apps and add to selection
    await blockedAppsCubit.loadBlockedApps();

    if (mounted) {
      final blockedAppsState = blockedAppsCubit.state;
      if (blockedAppsState is BlockedAppsLoaded) {
        setState(() {
          _selectedPackages.addAll(
            blockedAppsState.blockedApps.map((app) => app.packageName),
          );
        });
      }
    }
  }

  Future<void> _saveSelection() async {
    final appListCubit = getIt<AppListCubit>();
    final appListState = appListCubit.state;

    // Create BlockedApp objects for selected packages
    final blockedApps = _selectedPackages.map((packageName) {
      List<AppInfo> apps = [];
      if (appListState is AppListLoaded) {
        apps = appListState.apps;
      }

      final appInfo = apps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      return BlockedApp(
        packageName: packageName,
        appName: appInfo.appName,
        isBlocked: true,
        blockAttempts: 0,
        scheduleIds: [], // No schedule for quick block
      );
    }).toList();

    // Save to blocked apps
    final blockedAppsCubit = getIt<BlockedAppsCubit>();
    await blockedAppsCubit.saveBlockedApps(blockedApps);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حظر ${blockedApps.length} تطبيق بنجاح'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر التطبيقات للحظر'),
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          if (_selectedPackages.isNotEmpty)
            TextButton.icon(
              onPressed: _saveSelection,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'حفظ (${_selectedPackages.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: BlocBuilder<AppListCubit, AppListState>(
        bloc: getIt<AppListCubit>(),
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث عن تطبيقات...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    getIt<AppListCubit>().setSearchQuery(value);
                  },
                ),
              ),

              // Show System Apps Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.settings_applications, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'عرض تطبيقات النظام',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Switch(
                      value: state is AppListLoaded ? state.showSystemApps : false,
                      onChanged: (value) {
                        getIt<AppListCubit>().toggleShowSystemApps();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.apps),
                      text: 'جميع التطبيقات',
                    ),
                    Tab(
                      icon: Icon(Icons.category),
                      text: 'الفئات',
                    ),
                  ],
                ),
              ),

              // Selected Count Badge
              if (_selectedPackages.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedPackages.length} تطبيق محدد',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllAppsTab(state),
                    _buildCategoriesTab(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedPackages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveSelection,
              icon: const Icon(Icons.check),
              label: Text(
                'حظر ${_selectedPackages.length} تطبيق',
              ),
              backgroundColor: Colors.blue[600],
            )
          : null,
    );
  }

  // Tab 1: All Apps
  Widget _buildAllAppsTab(AppListState state) {
    return _buildAppsList(state);
  }

  // Tab 2: Categories
  Widget _buildCategoriesTab(AppListState state) {
    return _buildExpandableCategoriesList(state);
  }

  Widget _buildAppsList(AppListState state) {
    if (state is AppListLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AppListLoaded) {
      if (state.apps.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apps_outlined,
                size: 80,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'لم يتم العثور على تطبيقات',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.apps.length,
        itemBuilder: (context, index) {
          final app = state.apps[index];
          final isSelected = _selectedPackages.contains(app.packageName);
          return _buildAppItem(app, isSelected);
        },
      );
    } else if (state is AppListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ: ${state.message}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildExpandableCategoriesList(AppListState state) {
    if (state is AppListLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AppListLoaded) {
      if (state.apps.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apps_outlined,
                size: 80,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'لم يتم العثور على تطبيقات',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      }

      // Group apps by their categories
      final Map<AppCategory, List<AppInfo>> groupedApps = {};
      for (final app in state.apps) {
        final category = AppCategoryHelper.getAppCategory(app);
        if (category != AppCategory.all) {
          if (!groupedApps.containsKey(category)) {
            groupedApps[category] = [];
          }
          groupedApps[category]!.add(app);
        }
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groupedApps.length,
        itemBuilder: (context, index) {
          final category = groupedApps.keys.elementAt(index);
          final categoryApps = groupedApps[category]!;
          final isExpanded = _expandedCategories[category] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Category Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCategories[category] = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            category.icon,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${categoryApps.length} تطبيق',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${categoryApps.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Apps (Expandable)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: categoryApps.map((app) {
                        final isSelected = _selectedPackages.contains(app.packageName);
                        return _buildAppItem(app, isSelected);
                      }).toList(),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          );
        },
      );
    } else if (state is AppListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ: ${state.message}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAppItem(AppInfo app, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedPackages.add(app.packageName);
            } else {
              _selectedPackages.remove(app.packageName);
            }
          });
        },
        title: Text(
          app.appName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          app.packageName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.withValues(alpha: 0.8),
          ),
        ),
        secondary: app.icon != null && app.icon!.isNotEmpty
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    app.icon!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.apps,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.apps,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
