import 'package:flutter/material.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/focus_session_history.dart';

class FocusHistoryScreen extends StatefulWidget {
  final FocusRepository focusRepository;
  final SettingsRepository settingsRepository;

  const FocusHistoryScreen({
    super.key,
    required this.focusRepository,
    required this.settingsRepository,
  });

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends State<FocusHistoryScreen> {
  late Future<List<FocusSessionHistory>> _historyFuture;
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _historyFuture = widget.focusRepository.getHistory();
      _streakFuture = widget.settingsRepository.getFocusStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Streak Card
          FutureBuilder<int>(
            future: _streakFuture,
            builder: (context, snapshot) {
              final streak = snapshot.data ?? 0;
              return _StreakCard(streak: streak);
            },
          ),

          const Divider(height: 1),

          // History List
          Expanded(
            child: FutureBuilder<List<FocusSessionHistory>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final history = snapshot.data ?? [];

                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sessions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your first focus session!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildHistoryList(history);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<FocusSessionHistory> history) {
    // Group by date
    final grouped = <String, List<FocusSessionHistory>>{};
    for (final session in history) {
      final dateKey = session.formattedDate;
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final sessions = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...sessions.map((session) => _SessionCard(session: session)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all session history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.focusRepository.clearHistory();
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Focus Streak',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$streak days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final FocusSessionHistory session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: session.wasCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            session.wasCompleted
                ? Icons.check_circle
                : Icons.cancel,
            color: session.wasCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          session.focusListName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${session.durationMinutes} minutes • ${session.formattedTime}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: session.wasCompleted
            ? const Icon(Icons.done, color: Colors.green, size: 20)
            : const Icon(Icons.close, color: Colors.orange, size: 20),
      ),
    );
  }
}

// Helper to get repository from context
class RepositoryProvider<T> {
  static T of<T>(BuildContext context) {
    // This is a simple implementation. In production, use Provider or similar.
    throw UnimplementedError('Repository provider not implemented');
  }
}
