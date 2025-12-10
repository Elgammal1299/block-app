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
