import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
  ];

  // Get translations based on current locale
  Map<String, String> get _localizedStrings {
    if (locale.languageCode == 'ar') {
      return _arStrings;
    }
    return _enStrings;
  }

  // Helper method to get translation
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Common
  String get appName => translate('app_name');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get confirm => translate('confirm');
  String get yes => translate('yes');
  String get no => translate('no');

  // Home Screen
  String get homeTitle => translate('home_title');
  String get serviceStatus => translate('service_status');
  String get serviceRunning => translate('service_running');
  String get serviceStopped => translate('service_stopped');
  String get todayStats => translate('today_stats');
  String get blockedApps => translate('blocked_apps');
  String get blockAttempts => translate('block_attempts');
  String get activeSchedules => translate('active_schedules');
  String get quickActions => translate('quick_actions');
  String get blockNewApps => translate('block_new_apps');
  String get manageSchedules => translate('manage_schedules');
  String get viewStatistics => translate('view_statistics');
  String get appSettings => translate('app_settings');

  // App Selection Screen
  String get selectAppsToBlock => translate('select_apps_to_block');
  String get searchApps => translate('search_apps');
  String get showSystemApps => translate('show_system_apps');
  String get selectedApps => translate('selected_apps');
  String get continueButton => translate('continue_button');
  String get noAppsFound => translate('no_apps_found');
  String get loadingApps => translate('loading_apps');

  // Schedule Screen
  String get schedules => translate('schedules');
  String get noSchedulesAvailable => translate('no_schedules_available');
  String get createSchedulePrompt => translate('create_schedule_prompt');
  String get createSchedule => translate('create_schedule');
  String get editSchedule => translate('edit_schedule');
  String get deleteSchedule => translate('delete_schedule');
  String get deleteScheduleConfirm => translate('delete_schedule_confirm');
  String get scheduleDeleted => translate('schedule_deleted');
  String get startTime => translate('start_time');
  String get endTime => translate('end_time');
  String get selectDays => translate('select_days');
  String get everyDay => translate('every_day');
  String get weekdays => translate('weekdays');
  String get weekends => translate('weekends');
  String get scheduleCreated => translate('schedule_created');
  String get scheduleUpdated => translate('schedule_updated');

  // Days of week
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get sunday => translate('sunday');
  String get mon => translate('mon');
  String get tue => translate('tue');
  String get wed => translate('wed');
  String get thu => translate('thu');
  String get fri => translate('fri');
  String get sat => translate('sat');
  String get sun => translate('sun');

  // App Schedule Selection Screen
  String get setBlockingSchedules => translate('set_blocking_schedules');
  String get chooseBlockingMethod => translate('choose_blocking_method');
  String get alwaysBlocked => translate('always_blocked');
  String get alwaysBlockedDesc => translate('always_blocked_desc');
  String get useExistingSchedules => translate('use_existing_schedules');
  String get selectFromCreatedSchedules => translate('select_from_created_schedules');
  String get noSchedulesAvailableCreate => translate('no_schedules_available_create');
  String get createCustomSchedule => translate('create_custom_schedule');
  String get setSpecificTime => translate('set_specific_time');
  String get setSchedule => translate('set_schedule');
  String get editScheduleButton => translate('edit_schedule_button');
  String get saveAndApply => translate('save_and_apply');
  String get appsConfiguredSuccessfully => translate('apps_configured_successfully');
  String get noSchedulesSelected => translate('no_schedules_selected');
  String get noCustomScheduleSet => translate('no_custom_schedule_set');
  String get blockTime => translate('block_time');
  String get quickPresets => translate('quick_presets');

  // Permissions Screen
  String get permissionsRequired => translate('permissions_required');
  String get grantPermissions => translate('grant_permissions');
  String get usageStatsPermission => translate('usage_stats_permission');
  String get overlayPermission => translate('overlay_permission');
  String get accessibilityPermission => translate('accessibility_permission');
  String get permissionGranted => translate('permission_granted');
  String get permissionDenied => translate('permission_denied');
  String get continueToApp => translate('continue_to_app');

  // Theme
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');

  // Language
  String get language => translate('language');
  String get english => translate('english');
  String get arabic => translate('arabic');
  String get changeLanguage => translate('change_language');

  // Statistics
  String get statistics => translate('statistics');
  String get dailyUsage => translate('daily_usage');
  String get weeklyUsage => translate('weekly_usage');
  String get totalScreenTime => translate('total_screen_time');
  String get hours => translate('hours');
  String get minutes => translate('minutes');

  // Messages
  String appsConfigured(int count) => translate('apps_configured').replaceAll('{count}', count.toString());
  String schedulesSelected(int count) => translate('schedules_selected').replaceAll('{count}', count.toString());

  // Focus Mode
  String get focusLists => translate('focus_lists');
  String get createFocusList => translate('create_focus_list');
  String get noFocusLists => translate('no_focus_lists');
  String get createFirstList => translate('create_first_list');
  String get focusListDetail => translate('focus_list_detail');
  String get editList => translate('edit_list');
  String get deleteList => translate('delete_list');
  String appsCount(int count) => translate('apps_count').replaceAll('{count}', count.toString());
  String get selectDuration => translate('select_duration');
  String get minutesShort => translate('minutes_short');
  String get customDuration => translate('custom_duration');
  String get startFocusSession => translate('start_focus_session');
  String get activeSession => translate('active_session');
  String get timeRemaining => translate('time_remaining');
  String get cancelSession => translate('cancel_session');
  String get cancelSessionConfirm => translate('cancel_session_confirm');
  String get keepGoing => translate('keep_going');
  String get sessionCancelled => translate('session_cancelled');
  String get stayFocused => translate('stay_focused');
  String get blockedAppsLabel => translate('blocked_apps_label');
  String get sessionCompleted => translate('session_completed');
  String get greatJob => translate('great_job');
  String sessionSuccessMessage(int duration) => translate('session_success_message').replaceAll('{duration}', duration.toString());
  String get backToLists => translate('back_to_lists');
  String get focusHistory => translate('focus_history');
  String get totalSessions => translate('total_sessions');
  String get completedSessions => translate('completed_sessions');
  String get cancelledSessions => translate('cancelled_sessions');
  String get clearHistory => translate('clear_history');
  String get clearHistoryConfirm => translate('clear_history_confirm');
  String get noHistory => translate('no_history');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get thisWeek => translate('this_week');
  String get focusStreak => translate('focus_streak');
  String daysStreak(int days) => translate('days_streak').replaceAll('{days}', days.toString());
  String get currentStreak => translate('current_streak');
  String get longestStreak => translate('longest_streak');
  String get keepStreak => translate('keep_streak');
  String get presetSocialMedia => translate('preset_social_media');
  String get presetGames => translate('preset_games');
  String get presetCustom => translate('preset_custom');
  String get notificationSessionStarted => translate('notification_session_started');
  String notificationTimeRemaining(int minutes) => translate('notification_time_remaining').replaceAll('{minutes}', minutes.toString());
  String get notificationSessionCompleted => translate('notification_session_completed');
  String get notificationActionCancel => translate('notification_action_cancel');
  String get errorSessionActive => translate('error_session_active');
  String get errorInvalidDuration => translate('error_invalid_duration');
  String get errorNoAppsSelected => translate('error_no_apps_selected');
  String get errorListNameRequired => translate('error_list_name_required');
  String get listName => translate('list_name');
  String get listNameHint => translate('list_name_hint');
  String get addApps => translate('add_apps');
  String get noAppsSelected => translate('no_apps_selected');
  String get selectApps => translate('select_apps');
  String get done => translate('done');
  String get saveList => translate('save_list');
  String get focusListCreated => translate('focus_list_created');
  String get failedToCreateList => translate('failed_to_create_list');
  String get deleteListConfirm => translate('delete_list_confirm');
  String get focusMode => translate('focus_mode');

  // Gamification
  String get dailyGoal => translate('daily_goal');
  String get dailyGoalTitle => translate('daily_goal_title');
  String get dailyGoalAchieved => translate('daily_goal_achieved');
  String get minutesToday => translate('minutes_today');
  String get daysStreakLabel => translate('days_streak_label');
  String get quickBlock => translate('quick_block');
  String get focusTimer => translate('focus_timer');
  String get activeSchedule => translate('active_schedule');
  String get achievements => translate('achievements');
  String level(int levelNum) => translate('level').replaceAll('{level}', levelNum.toString());
  String xpPoints(int xp) => translate('xp_points').replaceAll('{xp}', xp.toString());
  String get smartSuggestions => translate('smart_suggestions');
  String tryFocusMode(String mode) => translate('try_focus_mode').replaceAll('{mode}', mode);
  String get nextSchedule => translate('next_schedule');
  String get noActiveSchedule => translate('no_active_schedule');
  String get editGoal => translate('edit_goal');
  String get setDailyGoal => translate('set_daily_goal');
  String get congratulations => translate('congratulations');
  String get achievementUnlocked => translate('achievement_unlocked');
  String get totalFocusTime => translate('total_focus_time');
  String get sessionsCompleted => translate('sessions_completed');
  String get focusModes => translate('focus_modes');
  String get viewMore => translate('view_more');
  String get topAppsToday => translate('top_apps_today');
  String get blockAttemptsToday => translate('block_attempts_today');
  String get noDataYet => translate('no_data_yet');
  String get startFirstSession => translate('start_first_session');
  String get activeNow => translate('active_now');
  String get noSchedules => translate('no_schedules');
  String get viewAllSchedules => translate('view_all_schedules');
  String get achievementsUnlocked => translate('achievements_unlocked');
}

// English translations
const Map<String, String> _enStrings = {
  // Common
  'app_name': 'App Blocker',
  'ok': 'OK',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'search': 'Search',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'confirm': 'Confirm',
  'yes': 'Yes',
  'no': 'No',

  // Home Screen
  'home_title': 'App Blocker',
  'service_status': 'Service Status',
  'service_running': 'Running',
  'service_stopped': 'Stopped',
  'today_stats': 'Today\'s Stats',
  'blocked_apps': 'Blocked Apps',
  'block_attempts': 'Block Attempts',
  'active_schedules': 'Active Schedules',
  'quick_actions': 'Quick Actions',
  'block_new_apps': 'Block New Apps',
  'manage_schedules': 'Manage Schedules',
  'view_statistics': 'View Statistics',
  'app_settings': 'Settings',

  // App Selection Screen
  'select_apps_to_block': 'Select Apps to Block',
  'search_apps': 'Search apps...',
  'show_system_apps': 'Show System Apps',
  'selected_apps': 'Selected',
  'continue_button': 'Continue',
  'no_apps_found': 'No apps found',
  'loading_apps': 'Loading apps...',

  // Schedule Screen
  'schedules': 'Schedules',
  'no_schedules_available': 'No schedules available',
  'create_schedule_prompt': 'Create schedules to control when apps are blocked',
  'create_schedule': 'Create Schedule',
  'edit_schedule': 'Edit Schedule',
  'delete_schedule': 'Delete Schedule',
  'delete_schedule_confirm': 'Are you sure you want to delete this schedule?',
  'schedule_deleted': 'Schedule deleted successfully',
  'start_time': 'Start Time',
  'end_time': 'End Time',
  'select_days': 'Select Days:',
  'every_day': 'Every Day',
  'weekdays': 'Weekdays',
  'weekends': 'Weekends',
  'schedule_created': 'Schedule created successfully',
  'schedule_updated': 'Schedule updated successfully',

  // Days of week
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',
  'mon': 'Mon',
  'tue': 'Tue',
  'wed': 'Wed',
  'thu': 'Thu',
  'fri': 'Fri',
  'sat': 'Sat',
  'sun': 'Sun',

  // App Schedule Selection Screen
  'set_blocking_schedules': 'Set Blocking Schedules',
  'choose_blocking_method': 'Choose blocking method:',
  'always_blocked': 'Always Blocked (24/7)',
  'always_blocked_desc': 'Block this app at all times',
  'use_existing_schedules': 'Use Existing Schedules',
  'select_from_created_schedules': 'Select from created schedules',
  'no_schedules_available_create': 'No schedules available - create one first',
  'create_custom_schedule': 'Create Custom Schedule',
  'set_specific_time': 'Set specific time for this app only',
  'set_schedule': 'Set Schedule',
  'edit_schedule_button': 'Edit Schedule',
  'save_and_apply': 'Save & Apply',
  'apps_configured_successfully': '{count} apps configured successfully!',
  'no_schedules_selected': 'No schedules selected',
  'no_custom_schedule_set': 'No custom schedule set',
  'block_time': 'Block Time:',
  'quick_presets': 'Quick Presets:',
  'schedules_selected': '{count} schedule(s) selected',

  // Permissions Screen
  'permissions_required': 'Permissions Required',
  'grant_permissions': 'Grant Permissions',
  'usage_stats_permission': 'Usage Stats Permission',
  'overlay_permission': 'Overlay Permission',
  'accessibility_permission': 'Accessibility Permission',
  'permission_granted': 'Granted',
  'permission_denied': 'Not Granted',
  'continue_to_app': 'Continue to App',

  // Theme
  'dark_mode': 'Dark Mode',
  'light_mode': 'Light Mode',

  // Language
  'language': 'Language',
  'english': 'English',
  'arabic': 'العربية',
  'change_language': 'Change Language',

  // Statistics
  'statistics': 'Statistics',
  'daily_usage': 'Daily Usage',
  'weekly_usage': 'Weekly Usage',
  'total_screen_time': 'Total Screen Time',
  'hours': 'h',
  'minutes': 'm',

  // Messages
  'apps_configured': '{count} apps configured',

  // Focus Mode
  'focus_lists': 'Focus Lists',
  'create_focus_list': 'Create List',
  'no_focus_lists': 'No lists yet',
  'create_first_list': 'Create your first focus list',
  'focus_list_detail': 'List Details',
  'edit_list': 'Edit List',
  'delete_list': 'Delete List',
  'apps_count': '{count} apps',
  'select_duration': 'Select Duration',
  'minutes_short': 'min',
  'custom_duration': 'Custom Duration',
  'start_focus_session': 'Start Focus Session',
  'active_session': 'Focus Session',
  'time_remaining': 'Time Remaining',
  'cancel_session': 'Cancel Session',
  'cancel_session_confirm': 'Are you sure you want to cancel?',
  'keep_going': 'Keep Going',
  'session_cancelled': 'Session Cancelled',
  'stay_focused': 'Stay Focused!',
  'blocked_apps_label': 'Blocked Apps',
  'session_completed': 'Session Completed!',
  'great_job': 'Great job!',
  'session_success_message': 'You stayed focused for {duration} minutes',
  'back_to_lists': 'Back to Lists',
  'focus_history': 'Focus History',
  'total_sessions': 'Total Sessions',
  'completed_sessions': 'Completed',
  'cancelled_sessions': 'Cancelled',
  'clear_history': 'Clear History',
  'clear_history_confirm': 'Delete all history?',
  'no_history': 'No sessions yet',
  'today': 'Today',
  'yesterday': 'Yesterday',
  'this_week': 'This Week',
  'focus_streak': 'Focus Streak',
  'days_streak': '{days} days',
  'current_streak': 'Current Streak',
  'longest_streak': 'Longest Streak',
  'keep_streak': 'Keep your streak going!',
  'preset_social_media': 'Social Media',
  'preset_games': 'Games',
  'preset_custom': 'Custom',
  'notification_session_started': 'Focus session started',
  'notification_time_remaining': '{minutes} minutes remaining',
  'notification_session_completed': 'Focus session completed!',
  'notification_action_cancel': 'Cancel',
  'error_session_active': 'A session is already active',
  'error_invalid_duration': 'Invalid duration',
  'error_no_apps_selected': 'No apps selected',
  'error_list_name_required': 'List name is required',
  'list_name': 'List Name',
  'list_name_hint': 'e.g., Work Focus, Study Time',
  'add_apps': 'Add Apps',
  'no_apps_selected': 'No apps selected',
  'select_apps': 'Select Apps',
  'done': 'Done',
  'save_list': 'Save List',
  'focus_list_created': 'Focus list created',
  'failed_to_create_list': 'Failed to create list',
  'delete_list_confirm': 'Are you sure you want to delete this list?',
  'focus_mode': 'Focus Mode',

  // Gamification
  'daily_goal': 'Daily Goal',
  'daily_goal_title': 'Focus Goal',
  'daily_goal_achieved': 'Goal Achieved! 🎉',
  'minutes_today': 'minutes today',
  'days_streak_label': '{days} days',
  'quick_block': 'Quick Block',
  'focus_timer': 'Focus Timer',
  'active_schedule': 'Active Schedule',
  'achievements': 'Achievements',
  'level': 'Level {level}',
  'xp_points': '{xp} XP',
  'smart_suggestions': 'Smart Suggestions',
  'try_focus_mode': 'Try {mode} mode now',
  'next_schedule': 'Next Schedule',
  'no_active_schedule': 'No active schedule',
  'edit_goal': 'Edit Goal',
  'set_daily_goal': 'Set Daily Goal',
  'congratulations': 'Congratulations!',
  'achievement_unlocked': 'Achievement Unlocked',
  'total_focus_time': 'Total Focus Time',
  'sessions_completed': 'Sessions Completed',
  'focus_modes': 'Focus Modes',
  'view_more': 'View More',
  'top_apps_today': 'Most Used Apps',
  'block_attempts_today': 'Block attempts today',
  'no_data_yet': 'No data yet',
  'start_first_session': 'Start your first focus session',
  'active_now': 'Active Now',
  'no_schedules': 'No schedules',
  'view_all_schedules': 'View All Schedules',
  'achievements_unlocked': 'unlocked',
};

// Arabic translations
const Map<String, String> _arStrings = {
  // Common
  'app_name': 'حاجب التطبيقات',
  'ok': 'موافق',
  'cancel': 'إلغاء',
  'save': 'حفظ',
  'delete': 'حذف',
  'edit': 'تعديل',
  'add': 'إضافة',
  'search': 'بحث',
  'loading': 'جاري التحميل...',
  'error': 'خطأ',
  'success': 'نجح',
  'confirm': 'تأكيد',
  'yes': 'نعم',
  'no': 'لا',

  // Home Screen
  'home_title': 'حاجب التطبيقات',
  'service_status': 'حالة الخدمة',
  'service_running': 'قيد التشغيل',
  'service_stopped': 'متوقف',
  'today_stats': 'إحصائيات اليوم',
  'blocked_apps': 'التطبيقات المحظورة',
  'block_attempts': 'محاولات الحظر',
  'active_schedules': 'الجداول النشطة',
  'quick_actions': 'إجراءات سريعة',
  'block_new_apps': 'حظر تطبيقات جديدة',
  'manage_schedules': 'إدارة الجداول',
  'view_statistics': 'عرض الإحصائيات',
  'app_settings': 'الإعدادات',

  // App Selection Screen
  'select_apps_to_block': 'اختر التطبيقات للحظر',
  'search_apps': 'البحث عن تطبيقات...',
  'show_system_apps': 'إظهار تطبيقات النظام',
  'selected_apps': 'المحددة',
  'continue_button': 'متابعة',
  'no_apps_found': 'لم يتم العثور على تطبيقات',
  'loading_apps': 'جاري تحميل التطبيقات...',

  // Schedule Screen
  'schedules': 'الجداول الزمنية',
  'no_schedules_available': 'لا توجد جداول متاحة',
  'create_schedule_prompt': 'أنشئ جداول للتحكم في وقت حظر التطبيقات',
  'create_schedule': 'إنشاء جدول',
  'edit_schedule': 'تعديل الجدول',
  'delete_schedule': 'حذف الجدول',
  'delete_schedule_confirm': 'هل أنت متأكد من حذف هذا الجدول؟',
  'schedule_deleted': 'تم حذف الجدول بنجاح',
  'start_time': 'وقت البداية',
  'end_time': 'وقت النهاية',
  'select_days': 'اختر الأيام:',
  'every_day': 'كل يوم',
  'weekdays': 'أيام الأسبوع',
  'weekends': 'عطلة نهاية الأسبوع',
  'schedule_created': 'تم إنشاء الجدول بنجاح',
  'schedule_updated': 'تم تحديث الجدول بنجاح',

  // Days of week
  'monday': 'الإثنين',
  'tuesday': 'الثلاثاء',
  'wednesday': 'الأربعاء',
  'thursday': 'الخميس',
  'friday': 'الجمعة',
  'saturday': 'السبت',
  'sunday': 'الأحد',
  'mon': 'إثنين',
  'tue': 'ثلاثاء',
  'wed': 'أربعاء',
  'thu': 'خميس',
  'fri': 'جمعة',
  'sat': 'سبت',
  'sun': 'أحد',

  // App Schedule Selection Screen
  'set_blocking_schedules': 'تحديد جداول الحظر',
  'choose_blocking_method': 'اختر طريقة الحظر:',
  'always_blocked': 'محظور دائماً (24/7)',
  'always_blocked_desc': 'حظر هذا التطبيق في جميع الأوقات',
  'use_existing_schedules': 'استخدام جداول موجودة',
  'select_from_created_schedules': 'اختر من الجداول المُنشأة',
  'no_schedules_available_create': 'لا توجد جداول متاحة - أنشئ واحداً أولاً',
  'create_custom_schedule': 'إنشاء جدول مخصص',
  'set_specific_time': 'تحديد وقت خاص لهذا التطبيق فقط',
  'set_schedule': 'تحديد الجدول',
  'edit_schedule_button': 'تعديل الجدول',
  'save_and_apply': 'حفظ وتطبيق',
  'apps_configured_successfully': 'تم تكوين {count} تطبيق بنجاح!',
  'no_schedules_selected': 'لم يتم تحديد جداول',
  'no_custom_schedule_set': 'لم يتم تعيين جدول مخصص',
  'block_time': 'وقت الحظر:',
  'quick_presets': 'إعدادات سريعة:',
  'schedules_selected': '{count} جدول محدد',

  // Permissions Screen
  'permissions_required': 'الأذونات المطلوبة',
  'grant_permissions': 'منح الأذونات',
  'usage_stats_permission': 'إذن إحصائيات الاستخدام',
  'overlay_permission': 'إذن التراكب',
  'accessibility_permission': 'إذن إمكانية الوصول',
  'permission_granted': 'ممنوح',
  'permission_denied': 'غير ممنوح',
  'continue_to_app': 'الاستمرار للتطبيق',

  // Theme
  'dark_mode': 'الوضع الداكن',
  'light_mode': 'الوضع الفاتح',

  // Language
  'language': 'اللغة',
  'english': 'English',
  'arabic': 'العربية',
  'change_language': 'تغيير اللغة',

  // Statistics
  'statistics': 'الإحصائيات',
  'daily_usage': 'الاستخدام اليومي',
  'weekly_usage': 'الاستخدام الأسبوعي',
  'total_screen_time': 'إجمالي وقت الشاشة',
  'hours': 'س',
  'minutes': 'د',

  // Messages
  'apps_configured': 'تم تكوين {count} تطبيق',

  // Focus Mode
  'focus_lists': 'قوائم التركيز',
  'create_focus_list': 'إنشاء قائمة',
  'no_focus_lists': 'لا توجد قوائم بعد',
  'create_first_list': 'أنشئ قائمة التركيز الأولى',
  'focus_list_detail': 'تفاصيل القائمة',
  'edit_list': 'تعديل القائمة',
  'delete_list': 'حذف القائمة',
  'apps_count': '{count} تطبيقات',
  'select_duration': 'اختر المدة',
  'minutes_short': 'دقيقة',
  'custom_duration': 'مدة مخصصة',
  'start_focus_session': 'بدء جلسة التركيز',
  'active_session': 'جلسة التركيز',
  'time_remaining': 'الوقت المتبقي',
  'cancel_session': 'إلغاء الجلسة',
  'cancel_session_confirm': 'هل أنت متأكد من الإلغاء؟',
  'keep_going': 'المتابعة',
  'session_cancelled': 'تم إلغاء الجلسة',
  'stay_focused': 'ابقَ مركزاً!',
  'blocked_apps_label': 'التطبيقات المحظورة',
  'session_completed': 'اكتملت الجلسة!',
  'great_job': 'أحسنت!',
  'session_success_message': 'حافظت على تركيزك لمدة {duration} دقيقة',
  'back_to_lists': 'العودة للقوائم',
  'focus_history': 'سجل التركيز',
  'total_sessions': 'مجموع الجلسات',
  'completed_sessions': 'المكتملة',
  'cancelled_sessions': 'الملغاة',
  'clear_history': 'مسح السجل',
  'clear_history_confirm': 'حذف جميع السجلات؟',
  'no_history': 'لا توجد جلسات بعد',
  'today': 'اليوم',
  'yesterday': 'أمس',
  'this_week': 'هذا الأسبوع',
  'focus_streak': 'سلسلة التركيز',
  'days_streak': '{days} يوم',
  'current_streak': 'السلسلة الحالية',
  'longest_streak': 'أطول سلسلة',
  'keep_streak': 'حافظ على سلسلتك!',
  'preset_social_media': 'وسائل التواصل',
  'preset_games': 'الألعاب',
  'preset_custom': 'مخصص',
  'notification_session_started': 'بدأت جلسة التركيز',
  'notification_time_remaining': 'متبقي {minutes} دقيقة',
  'notification_session_completed': 'اكتملت جلسة التركيز!',
  'notification_action_cancel': 'إلغاء',
  'error_session_active': 'جلسة قيد التنفيذ بالفعل',
  'error_invalid_duration': 'مدة غير صالحة',
  'error_no_apps_selected': 'لم يتم اختيار تطبيقات',
  'error_list_name_required': 'اسم القائمة مطلوب',
  'list_name': 'اسم القائمة',
  'list_name_hint': 'مثلاً: تركيز العمل، وقت الدراسة',
  'add_apps': 'إضافة تطبيقات',
  'no_apps_selected': 'لم يتم اختيار تطبيقات',
  'select_apps': 'اختيار التطبيقات',
  'done': 'تم',
  'save_list': 'حفظ القائمة',
  'focus_list_created': 'تم إنشاء القائمة',
  'failed_to_create_list': 'فشل إنشاء القائمة',
  'delete_list_confirm': 'هل أنت متأكد من حذف هذه القائمة؟',
  'focus_mode': 'وضع التركيز',

  // Gamification
  'daily_goal': 'الهدف اليومي',
  'daily_goal_title': 'هدف التركيز',
  'daily_goal_achieved': 'تحقق الهدف! 🎉',
  'minutes_today': 'دقيقة اليوم',
  'days_streak_label': '{days} يوم',
  'quick_block': 'حظر سريع',
  'focus_timer': 'مؤقت التركيز',
  'active_schedule': 'الجدول النشط',
  'achievements': 'الإنجازات',
  'level': 'المستوى {level}',
  'xp_points': '{xp} نقطة',
  'smart_suggestions': 'اقتراحات ذكية',
  'try_focus_mode': 'جرب وضع {mode} الآن',
  'next_schedule': 'الجدول القادم',
  'no_active_schedule': 'لا يوجد جدول نشط',
  'edit_goal': 'تعديل الهدف',
  'set_daily_goal': 'تحديد هدف يومي',
  'congratulations': 'تهانينا!',
  'achievement_unlocked': 'إنجاز جديد',
  'total_focus_time': 'إجمالي وقت التركيز',
  'sessions_completed': 'الجلسات المكتملة',
  'focus_modes': 'أوضاع التركيز',
  'view_more': 'عرض المزيد',
  'top_apps_today': 'أكثر التطبيقات استخداماً',
  'block_attempts_today': 'محاولات الحظر اليوم',
  'no_data_yet': 'لا توجد بيانات بعد',
  'start_first_session': 'ابدأ أول جلسة تركيز',
  'active_now': 'نشط الآن',
  'no_schedules': 'لا توجد جداول',
  'view_all_schedules': 'عرض كل الجداول',
  'achievements_unlocked': 'مفتوحة',
};

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
