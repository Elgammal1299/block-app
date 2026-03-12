import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/DI/setup_get_it.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_state.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_cubit.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_state.dart';
import '../../ui/view/widgets/focus/flip_clock_timer.dart';
import '../../ui/view/widgets/focus/focus_cards.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // Session Settings
  int workMinutes = 25;
  int breakMinutes = 5;
  int longBreakMinutes = 15;

  // Preferences
  int sessionsUntilLong = 4;
  int dailyGoal = 12;

  // Timer Style
  bool isFlipStyle = true;

  bool hasNotificationPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
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
    return BlocBuilder<FocusSessionCubit, FocusSessionState>(
      bloc: getIt<FocusSessionCubit>(),
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

  // --- SETUP VIEW ---
  Widget _buildSetupView() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'مؤقت التركيز',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!hasNotificationPermission)
            IconButton(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentWarning,
              ),
              onPressed: () async {
                await PlatformChannelService()
                    .requestNotificationListenerPermission();
                Future.delayed(const Duration(seconds: 2), _checkPermissions);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasNotificationPermission)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacing20),
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.accentWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppTheme.accentWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.accentWarning,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        'للحظر الفعال للإشعارات، يرجى منح إذن الوصول للإشعارات. قد تحتاج لإعادة تشغيل التطبيق بالكامل بعد إضافة ميزات جديدة.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => PlatformChannelService()
                          .requestNotificationListenerPermission(),
                      child: const Text('منح'),
                    ),
                  ],
                ),
              ),
            _buildSectionHeader('مدة الجلسة'),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: DurationCard(
                    value: '25',
                    label: 'بومودورو',
                    isSelected: workMinutes == 25,
                    onTap: () => setState(() => workMinutes = 25),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: DurationCard(
                    value: '5',
                    label: 'راحة قصيرة',
                    isSelected: breakMinutes == 5,
                    onTap: () => setState(() => breakMinutes = 5),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: DurationCard(
                    value: '15',
                    label: 'راحة طويلة',
                    isSelected: longBreakMinutes == 15,
                    onTap: () => setState(() => longBreakMinutes = 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('تفضيلات أخرى'),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: PreferenceCard(
                    value: sessionsUntilLong.toString(),
                    label: 'جلسات قبل الراحة الطويلة',
                    onIncrement: () => setState(() => sessionsUntilLong++),
                    onDecrement: () => setState(() {
                      if (sessionsUntilLong > 1) sessionsUntilLong--;
                    }),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: PreferenceCard(
                    value: dailyGoal.toString(),
                    label: 'الهدف اليومي',
                    onIncrement: () => setState(() => dailyGoal++),
                    onDecrement: () => setState(() {
                      if (dailyGoal > 1) dailyGoal--;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('نمط المؤقت'),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: StyleCard(
                    time: '23:15',
                    label: 'قياسي',
                    isSelected: !isFlipStyle,
                    onTap: () => setState(() => isFlipStyle = false),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: StyleCard(
                    time: '2 3 : 1 5',
                    label: 'ساعة قلابة',
                    isSelected: isFlipStyle,
                    onTap: () => setState(() => isFlipStyle = true),
                    isFlip: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showStartSessionDialog,
                child: const Text(
                  'بدء الجلسة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- ACTIVE SESSION VIEW ---
  Widget _buildActiveSessionView(dynamic state, bool isPaused) {
    final int remainingSeconds = state.remainingSeconds;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeSession = state.activeSession;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              activeSession.focusListName.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.labelLarge?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value:
                        1 -
                        (remainingSeconds /
                            (activeSession.durationMinutes * 60)),
                    strokeWidth: 8,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaused
                          ? colorScheme.outline.withValues(alpha: 0.5)
                          : colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (isFlipStyle)
                  FlipClockTimer(minutes: minutes, seconds: seconds)
                else
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (isPaused) {
                      getIt<FocusSessionCubit>().resumeSession();
                    } else {
                      getIt<FocusSessionCubit>().pauseSession();
                    }
                  },
                  icon: Icon(
                    isPaused
                        ? Icons.play_circle_filled
                        : Icons.pause_circle_filled,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: () {
                    getIt<FocusSessionCubit>().cancelSession();
                  },
                  icon: Icon(
                    Icons.stop_circle,
                    size: 80,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // UI Helpers
  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: theme.textTheme.labelMedium?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  void _showStartSessionDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) {
        return BlocBuilder<FocusListCubit, FocusListState>(
          bloc: getIt<FocusListCubit>(),
          builder: (context, state) {
            if (state is FocusListLoaded) {
              if (state.focusLists.isEmpty) {
                return const Center(
                  child: Text(
                    'Please create a focus list first',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اختيار قائمة التركيز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.focusLists
                        .map(
                          (list) => ListTile(
                            title: Text(list.name),
                            leading: Icon(
                              Icons.list,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              getIt<FocusSessionCubit>().startSession(
                                list.id,
                                workMinutes,
                              );
                            },
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}
