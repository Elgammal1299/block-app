import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/cubit/focus_list/focus_list_cubit.dart';
import '../../presentation/cubit/app_list/app_list_cubit.dart';
import '../../presentation/cubit/app_list/app_list_state.dart';
import '../../data/models/app_info.dart';

class CreateFocusListScreen extends StatefulWidget {
  const CreateFocusListScreen({super.key});

  @override
  State<CreateFocusListScreen> createState() => _CreateFocusListScreenState();
}

class _CreateFocusListScreenState extends State<CreateFocusListScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedPackages = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Focus List'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  hintText: 'e.g., Work Focus, Study Time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
            ),

            // Selected apps count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.apps, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedPackages.length} apps selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAppSelectionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Apps'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Selected apps list
            Expanded(
              child: _selectedPackages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apps_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No apps selected',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showAppSelectionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Apps'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _selectedPackages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final package = _selectedPackages.elementAt(index);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.android),
                            title: Text(_getAppName(package)),
                            subtitle: Text(
                              package,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedPackages.remove(package);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPackages.isEmpty ? null : _saveList,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save List',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppName(String packageName) {
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }

  void _showAppSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _AppSelectionDialog(
        selectedPackages: _selectedPackages,
        onSelectionChanged: (selected) {
          setState(() {
            _selectedPackages.clear();
            _selectedPackages.addAll(selected);
          });
        },
      ),
    );
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one app')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final success = await context.read<FocusListCubit>().createFocusList(
          name,
          _selectedPackages.toList(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus list created')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create list'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AppSelectionDialog extends StatefulWidget {
  final Set<String> selectedPackages;
  final Function(Set<String>) onSelectionChanged;

  const _AppSelectionDialog({
    required this.selectedPackages,
    required this.onSelectionChanged,
  });

  @override
  State<_AppSelectionDialog> createState() => _AppSelectionDialogState();
}

class _AppSelectionDialogState extends State<_AppSelectionDialog> {
  late Set<String> _tempSelection;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelection = Set.from(widget.selectedPackages);
    context.read<AppListCubit>().loadInstalledApps();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Apps'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () {
                    widget.onSelectionChanged(_tempSelection);
                    Navigator.pop(context);
                  },
                  child: const Text('Done',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<AppListCubit, AppListState>(
                builder: (context, state) {
                  if (state is AppListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AppListError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (state is AppListLoaded) {
                    final apps = state.apps.where((app) {
                      if (_searchQuery.isEmpty) return true;
                      return app.appName.toLowerCase().contains(_searchQuery) ||
                          app.packageName.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (apps.isEmpty) {
                      return const Center(child: Text('No apps found'));
                    }

                    return ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        final isSelected =
                            _tempSelection.contains(app.packageName);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _tempSelection.add(app.packageName);
                              } else {
                                _tempSelection.remove(app.packageName);
                              }
                            });
                          },
                          title: Text(app.appName),
                          subtitle: Text(
                            app.packageName,
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: app.icon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    app.icon!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.android),
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
      ),
    );
  }
}
