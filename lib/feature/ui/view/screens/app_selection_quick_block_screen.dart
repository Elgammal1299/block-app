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
  State<AppSelectionQuickBlockScreen> createState() =>
      _AppSelectionQuickBlockScreenState();
}

class _AppSelectionQuickBlockScreenState
    extends State<AppSelectionQuickBlockScreen>
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'قائمة الحظر',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.blue),
              onPressed: () {
                // Implementation of search toggle
              },
            ),
          ],
        ),
        body: BlocBuilder<AppListCubit, AppListState>(
          bloc: getIt<AppListCubit>(),
          builder: (context, state) {
            return Column(
              children: [
                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  indicatorWeight: 3,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'التطبيقات'),
                    Tab(text: 'الفئات'),
                  ],
                ),

                // Search Bar
                if (state is AppListLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'البحث عن تطبيقات...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
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

                // Bottom Save Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
        return _buildEmptyState();
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
      return _buildErrorState(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لم يتم العثور على تطبيقات',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text('خطأ: $message', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildExpandableCategoriesList(AppListState state) {
    if (state is AppListLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AppListLoaded) {
      if (state.apps.isEmpty) {
        return _buildEmptyState();
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

      // Sort categories: "Others" at the end, then alphabetically by name
      final sortedCategories = groupedApps.keys.toList()
        ..sort((a, b) {
          if (a == AppCategory.others) return 1;
          if (b == AppCategory.others) return -1;
          return a.displayName.compareTo(b.displayName);
        });

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedCategories.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final categoryApps = groupedApps[category]!;
          final isExpanded = _expandedCategories[category] ?? false;

          final bool allSelected =
              categoryApps.isNotEmpty &&
              categoryApps.every(
                (app) => _selectedPackages.contains(app.packageName),
              );
          final bool someSelected =
              categoryApps.any(
                (app) => _selectedPackages.contains(app.packageName),
              ) &&
              !allSelected;

          return Column(
            children: [
              // Category Header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategories[category] = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      // Checkbox for category (left)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: allSelected,
                          tristate: someSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                for (var app in categoryApps) {
                                  _selectedPackages.add(app.packageName);
                                }
                              } else {
                                for (var app in categoryApps) {
                                  _selectedPackages.remove(app.packageName);
                                }
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          activeColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text in the middle
                      Expanded(
                        child: Text(
                          category.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Icon to the right of text
                      Icon(category.icon, size: 24, color: category.color),
                      const SizedBox(width: 12),
                      // Arrow icon (far right)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Category Apps
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(right: 32.0),
                  child: Column(
                    children: categoryApps.map((app) {
                      final isSelected = _selectedPackages.contains(
                        app.packageName,
                      );
                      return _buildAppItem(app, isSelected);
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      );
    } else if (state is AppListError) {
      return _buildErrorState(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAppItem(AppInfo app, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        activeColor: Colors.blue,
      ),
      title: Text(
        app.appName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        textAlign: TextAlign.right,
      ),
      subtitle: Text(
        app.packageName,
        style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.8)),
        textAlign: TextAlign.right,
      ),
      trailing: app.icon != null && app.icon!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                app.icon!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apps, color: Colors.blue, size: 18),
            ),
    );
  }
}
