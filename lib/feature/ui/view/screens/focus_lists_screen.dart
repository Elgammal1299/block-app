import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../view_model/focus_list_cubit/focus_list_cubit.dart';
import '../../view_model/focus_list_cubit/focus_list_state.dart';
import '../../../data/models/focus_list.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/localization/app_localizations.dart';

class FocusListsScreen extends StatelessWidget {
  const FocusListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.focusLists),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.focusHistory);
            },
            tooltip: localizations.focusHistory,
          ),
        ],
      ),
      body: BlocBuilder<FocusListCubit, FocusListState>(
        bloc: getIt<FocusListCubit>(),
        builder: (context, state) {
          if (state is FocusListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FocusListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${localizations.error}: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      getIt<FocusListCubit>().loadFocusLists();
                    },
                    child: Text(localizations.cancel),
                  ),
                ],
              ),
            );
          }

          if (state is FocusListLoaded) {
            final lists = state.focusLists;

            if (lists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.noFocusLists,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.createFirstList,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final focusList = lists[index];
                return _FocusListCard(
                  focusList: focusList,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.focusListDetail,
                      arguments: focusList,
                    );
                  },
                  onDelete: () => _showDeleteDialog(context, focusList),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createFocusList);
        },
        icon: const Icon(Icons.add),
        label: Text(localizations.createFocusList),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FocusList focusList) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.deleteList),
        content: Text(localizations.deleteListConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await getIt<FocusListCubit>().deleteFocusList(focusList.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? localizations.success
                          : localizations.failedToCreateList,
                    ),
                  ),
                );
              }
            },
            child: Text(localizations.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FocusListCard extends StatelessWidget {
  final FocusList focusList;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FocusListCard({
    required this.focusList,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.list_rounded,
                  color: theme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focusList.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.appsCount(focusList.packageNames.length),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (focusList.lastUsedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(context, focusList.lastUsedAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: onDelete,
                ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return localizations.today;
    } else if (itemDate == yesterday) {
      return localizations.yesterday;
    } else if (now.difference(date).inDays < 7) {
      final days = ['', localizations.mon, localizations.tue, localizations.wed,
                    localizations.thu, localizations.fri, localizations.sat, localizations.sun];
      return days[date.weekday];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
