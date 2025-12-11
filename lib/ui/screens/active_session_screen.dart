import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/cubit/focus_session/focus_session_cubit.dart';
import '../../presentation/cubit/focus_session/focus_session_state.dart';
import 'dart:math' as math;

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus Session'),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: BlocConsumer<FocusSessionCubit, FocusSessionState>(
          listener: (context, state) {
            if (state is FocusSessionCompleted) {
              _showCompletionDialog(context, state);
            } else if (state is FocusSessionIdle) {
              // Session was cancelled or completed, go back
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          builder: (context, state) {
            if (state is FocusSessionActive) {
              return _ActiveSessionContent(
                session: state.activeSession,
                remainingSeconds: state.remainingSeconds,
              );
            }

            if (state is FocusSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // If somehow we ended up here without an active session
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('No active session'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCompletionDialog(
      BuildContext context, FocusSessionCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            const Text('Session Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Great job!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You stayed focused for ${state.completedSession.durationMinutes} minutes',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionContent extends StatelessWidget {
  final dynamic session;
  final int remainingSeconds;

  const _ActiveSessionContent({
    required this.session,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSeconds = session.durationMinutes * 60;
    final progress = 1 - (remainingSeconds / totalSeconds);
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Session Name
            Text(
              session.focusListName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay Focused!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const Spacer(),

            // Circular Timer
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: _TimerPainter(
                      progress: progress,
                      color: theme.primaryColor,
                    ),
                  ),

                  // Time display
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'remaining',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Blocked Apps Section (Collapsible)
            _BlockedAppsSection(
              packages: session.blockedPackages,
            ),

            const SizedBox(height: 24),

            // Cancel Button
            OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancel Session'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Session'),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<FocusSessionCubit>().cancelSession();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session Cancelled')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _BlockedAppsSection extends StatefulWidget {
  final List<String> packages;

  const _BlockedAppsSection({required this.packages});

  @override
  State<_BlockedAppsSection> createState() => _BlockedAppsSectionState();
}

class _BlockedAppsSectionState extends State<_BlockedAppsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.block, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Blocked Apps (${widget.packages.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: widget.packages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final package = widget.packages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _getAppName(package),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getAppName(String packageName) {
    // Extract app name from package name
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
