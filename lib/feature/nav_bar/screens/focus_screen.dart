import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/DI/setup_get_it.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_cubit.dart';
import '../../ui/view_model/focus_session_cubit/focus_session_state.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_cubit.dart';
import '../../ui/view_model/focus_list_cubit/focus_list_state.dart';
import '../../ui/view/widgets/focus/flip_clock_timer.dart';

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
          return _buildActiveSessionView(state);
        }
        return _buildSetupView();
      },
    );
  }

  // --- SETUP VIEW ---
  Widget _buildSetupView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        title: const Text(
          'مؤقت التركيز',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (!hasNotificationPermission)
            IconButton(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              onPressed: () async {
                await PlatformChannelService()
                    .requestNotificationListenerPermission();
                // Check again after returning
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
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'للحظر الفعال للإشعارات، يرجى منح إذن الوصول للإشعارات. قد تحتاج لإعادة تشغيل التطبيق بالكامل بعد إضافة ميزات جديدة.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDurationCard(
                    '25',
                    'بومودورو',
                    isSelected: workMinutes == 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationCard(
                    '5',
                    'راحة قصيرة',
                    isSelected: breakMinutes == 5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationCard(
                    '15',
                    'راحة طويلة',
                    isSelected: longBreakMinutes == 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('تفضيلات أخرى'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPreferenceCard(
                    sessionsUntilLong.toString(),
                    'جلسات قبل الراحة الطويلة',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPreferenceCard(
                    dailyGoal.toString(),
                    'الهدف اليومي',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('نمط المؤقت'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStyleCard(
                    '23:15',
                    'قياسي',
                    isSelected: !isFlipStyle,
                    onTap: () => setState(() => isFlipStyle = false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyleCard(
                    '2 3 : 1 5',
                    'ساعة قلابة',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'بدء الجلسة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
  Widget _buildActiveSessionView(FocusSessionActive state) {
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              state.activeSession.focusListName.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isFlipStyle)
              FlipClockTimer(minutes: minutes, seconds: seconds)
            else
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Implement Pause
                  },
                  icon: const Icon(
                    Icons.pause_circle_filled,
                    size: 70,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: () {
                    getIt<FocusSessionCubit>().cancelSession();
                  },
                  icon: const Icon(
                    Icons.stop_circle,
                    size: 70,
                    color: Colors.redAccent,
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
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDurationCard(
    String value,
    String label, {
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: isSelected
            ? Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(
    String time,
    String label, {
    bool isSelected = false,
    bool isFlip = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            if (isFlip)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: time.split(' ').map((char) {
                  if (char == ':')
                    return const Text(
                      ':',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    );
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showStartSessionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
