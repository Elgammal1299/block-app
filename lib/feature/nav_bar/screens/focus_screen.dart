import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/DI/setup_get_it.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_state.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_cubit.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_state.dart';
import '../../../core/utils/app_logger.dart';
import '../../data/models/focus_session_history.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/models/focus_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  // Session Settings (Custom Mode)
  int workMinutes = 25;
  int breakMinutes = 5;

  // UI State
  bool isPomodoroMode = true;
  String? studyListId;
  bool hasNotificationPermission = true;
  int sessionsToday = 0;
  int totalMinutesToday = 0;
  bool _showReturnMessage = false;
  bool _isWakelockEnabled = false;

  // Health Tips List
  final List<Map<String, dynamic>> healthTips = [
    {'icon': '💧', 'text': 'اشرب مياه'},
    {'icon': '👀', 'text': 'ارح عينيك'},
    {'icon': '🧍‍♂️', 'text': 'قوم وافرد ضهرك'},
    {'icon': '🚶‍♂️', 'text': 'اتحرك شوية'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _loadStudyList();
    _loadStatistics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toggleWakelock(enable: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final sessionState = getIt<FocusSessionCubit>().state;
      if (sessionState is FocusSessionActive) {
        _showReturnMessage = true;
        AppLogger.i('User left focus screen during active session');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_showReturnMessage) {
        _showReturnMessage = false;
        _showBackToFocusDialog();
      }
      _loadStatistics(); // Refresh stats when returning
    }
  }

  void _showBackToFocusDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text('ارجع للتركيز 🙂 نحن نثق بك!'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _loadStatistics() async {
    try {
      final repository = getIt<FocusRepository>();
      final List<FocusSessionHistory> history = await repository.getHistory();
      
      final today = DateTime.now();
      final todaySessions = history.where((h) => 
        h.completedAt.year == today.year && 
        h.completedAt.month == today.month && 
        h.completedAt.day == today.day &&
        h.wasCompleted
      ).toList();

      if (mounted) {
        setState(() {
          sessionsToday = todaySessions.length;
          totalMinutesToday = todaySessions.fold(0, (sum, item) => sum + item.durationMinutes);
        });
      }
    } catch (e) {
      AppLogger.e('Error loading statistics', e);
    }
  }

  Future<void> _loadStudyList() async {
    final listCubit = getIt<FocusListCubit>();
    if (listCubit.state is FocusListLoaded) {
      final state = listCubit.state as FocusListLoaded;
      _findStudyList(state.focusLists);
    } else {
      await listCubit.loadFocusLists();
      if (listCubit.state is FocusListLoaded) {
        _findStudyList((listCubit.state as FocusListLoaded).focusLists);
      }
    }
  }

  void _findStudyList(List<FocusList> focusLists) {
    try {
      FocusList? studyList;
      
      // Try to find the study list by ID first
      for (final list in focusLists) {
        if (list.id == 'preset_study') {
          studyList = list;
          break;
        }
      }
      
      // If not found by ID, try by name
      if (studyList == null) {
        for (final list in focusLists) {
          if (list.name.contains('دراسة') || list.name.toLowerCase().contains('study')) {
            studyList = list;
            break;
          }
        }
      }
      
      // If still not found, take the first available list as fallback
      studyList ??= focusLists.isNotEmpty ? focusLists.first : null;

      if (studyList != null) {
        setState(() {
          studyListId = studyList!.id;
        });
      }
    } catch (e) {
      AppLogger.e('Error finding study list', e);
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await PlatformChannelService()
        .checkNotificationListenerPermission();
    if (mounted) {
      setState(() {
        hasNotificationPermission = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FocusSessionCubit, FocusSessionState>(
      bloc: getIt<FocusSessionCubit>(),
      listener: (context, state) {
        if (state is FocusSessionCompleted) {
          _handleSessionCompletion();
        }
        
        if (state is FocusSessionIdle) {
          _loadStatistics();
        }
        
        // Handle Wakelock safely
        final shouldEnable = state is FocusSessionActive || state is FocusSessionPaused;
        _toggleWakelock(enable: shouldEnable);
      },
      builder: (context, state) {
        if (state is FocusSessionActive) {
          return _buildActiveSessionView(state, false);
        }
        if (state is FocusSessionPaused) {
          return _buildActiveSessionView(state, true);
        }
        return _buildSetupView();
      },
    );
  }

  void _handleSessionCompletion() {
    _loadStatistics(); // Refresh stats immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('عمل رائع! انتهت جلسة التركيز 👏'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --- SETUP VIEW ---
  Widget _buildSetupView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildSetupContent(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  Widget _buildSetupContent(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'مؤقت التركيز',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!hasNotificationPermission)
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              onPressed: () async {
                await PlatformChannelService().requestNotificationListenerPermission();
                Future.delayed(const Duration(seconds: 2), _checkPermissions);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTimerCircle(
              (isPomodoroMode ? 25 : workMinutes) * 60, 
              (isPomodoroMode ? 25 : workMinutes) * 60, 
              false, 
              "جلسة تركيز"
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _startDefaultSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'بدء الجلسة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('وضع المؤقت'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildModeToggleItem('Pomodoro', isPomodoroMode, () {
                    setState(() => isPomodoroMode = true);
                  }),
                  _buildModeToggleItem('مخصص', !isPomodoroMode, () {
                    setState(() => isPomodoroMode = false);
                  }),
                ],
              ),
            ),
            if (!isPomodoroMode) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('مدة الجلسة'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleButton(
                    onTap: () {
                      if (workMinutes > 1) setState(() => workMinutes--);
                    },
                    icon: Icons.remove,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    iconColor: colorScheme.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          '$workMinutes',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text('دقيقة', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  _buildCircleButton(
                    onTap: () {
                      if (workMinutes < 180) setState(() => workMinutes++);
                    },
                    icon: Icons.add,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    iconColor: colorScheme.onSurface,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildStatCard('جلسات اليوم', '$sessionsToday جلسات', Icons.local_fire_department)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('وقت التركيز', _formatFocusTime(totalMinutesToday), Icons.timer)),
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('نصائح أثناء التركيز'),
            const SizedBox(height: 12),
            _buildTipsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggleItem(String title, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: healthTips.map((tip) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(tip['icon'], style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(tip['text'], style: theme.textTheme.bodyLarge),
            ],
          ),
        )).toList(),
      ),
    );
  }

  void _startDefaultSession() {
    if (studyListId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جارٍ تحميل إعدادات الدراسة...')),
      );
      _loadStudyList();
      return;
    }

    getIt<FocusSessionCubit>().startSession(
      studyListId!,
      isPomodoroMode ? 25 : workMinutes,
    );
  }

  // --- ACTIVE SESSION VIEW ---
  Widget _buildActiveSessionView(dynamic state, bool isPaused) {
    final int remainingSeconds = state.remainingSeconds;
    final activeSession = state.activeSession;

    final Color bgColor = const Color(0xFFF1F8E9);
    final Color primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildSessionHeader(activeSession.focusListName),
            const Spacer(),
            _buildTimerCircle(
              remainingSeconds, 
              activeSession.durationMinutes * 60,
              isPaused,
              "جلسة تركيز",
              customColor: primaryColor,
            ),
            const Spacer(),
            _buildActionButtons(isPaused, primaryColor),
            const SizedBox(height: 60),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '⚠️ عند الخروج، ستظهر رسالة "ارجع للتركيز"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => getIt<FocusSessionCubit>().cancelSession(),
            icon: const Icon(Icons.close),
          ),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(int remainingSeconds, int totalSeconds, bool isPaused, String label, {Color? customColor}) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final theme = Theme.of(context);
    final progress = (totalSeconds > 0) ? (1 - (remainingSeconds / totalSeconds)) : 0.0;
    final activeColor = customColor ?? theme.colorScheme.primary;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: activeColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? Colors.grey.shade400 : activeColor,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: isPaused ? Colors.grey : activeColor,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: (isPaused ? Colors.grey : activeColor).withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isPaused, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          onTap: () => getIt<FocusSessionCubit>().cancelSession(),
          icon: Icons.close,
          color: Colors.red.withOpacity(0.1),
          iconColor: Colors.red,
        ),
        const SizedBox(width: 40),
        _buildCircleButton(
          onTap: () {
            if (isPaused) {
              getIt<FocusSessionCubit>().resumeSession();
            } else {
              getIt<FocusSessionCubit>().pauseSession();
            }
          },
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: primaryColor,
          isLarge: true,
        ),
        const SizedBox(width: 40),
        const SizedBox(width: 60), // Placeholder to balance Row
      ],
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap, 
    required IconData icon, 
    required Color color, 
    Color? iconColor,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 80 : 60,
        height: isLarge ? 80 : 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: isLarge ? 40 : 30),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes دقيقة';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}س ${mins}د';
  }

  Future<void> _toggleWakelock({required bool enable}) async {
    if (_isWakelockEnabled == enable) return; // Skip if already in desired state
    
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
      _isWakelockEnabled = enable;
    } catch (e) {
      // Catch and log silently to prevent crash
      AppLogger.e('Wakelock platform error - possibly needs full app restart', e);
    }
  }
}

