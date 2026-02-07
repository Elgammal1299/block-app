class AppConstants {
  // Platform Channel Names
  static const String channelName = 'com.example.block_app/app_blocker';

  // SharedPreferences Keys
  static const String keyBlockedApps = 'blocked_apps';
  static const String keySchedules = 'schedules';
  static const String keyUsageLimits = 'usage_limits';
  static const String keyFocusPresets = 'focus_presets';
  static const String keySettingsPin = 'settings_pin';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyUnlockChallengeType = 'unlock_challenge_type';
  static const String keyBlockAttempts = 'block_attempts';
  static const String keyFocusStreak = 'focus_streak';
  static const String keyLastFocusDate = 'last_focus_date';
  static const String keyFocusLists = 'focus_lists';
  static const String keyActiveFocusSession = 'active_focus_session';
  static const String keyFocusSessionHistory = 'focus_session_history';
  static const String keyPresetsInitialized = 'presets_initialized';
  static const String keyBlockScreenStyle = 'block_screen_style';
  static const String keyBlockScreenColor = 'block_screen_color';
  static const String keyBlockScreenQuote = 'block_screen_quote';
  static const String keyBlockScreenThemes = 'block_screen_themes';
  static const String keyFocusModeConfigs = 'focus_mode_configs';
  static const String keyCustomFocusModes = 'custom_focus_modes';
  static const String keyUnlockChallengeConfig = 'unlock_challenge_config';

  // Challenge Types
  static const String challengeNone = 'none';
  static const String challengeMath = 'math';
  static const String challengeQuote = 'quote';
  static const String challengeTimer = 'timer';

  // Platform Channel Methods
  static const String methodGetInstalledApps = 'getInstalledApps';
  static const String methodCheckUsageStatsPermission =
      'checkUsageStatsPermission';
  static const String methodRequestUsageStatsPermission =
      'requestUsageStatsPermission';
  static const String methodCheckOverlayPermission = 'checkOverlayPermission';
  static const String methodRequestOverlayPermission =
      'requestOverlayPermission';
  static const String methodCheckAccessibilityPermission =
      'checkAccessibilityPermission';
  static const String methodRequestAccessibilityPermission =
      'requestAccessibilityPermission';
  static const String methodStartMonitoringService = 'startMonitoringService';
  static const String methodStopMonitoringService = 'stopMonitoringService';
  static const String methodStartUsageTrackingService =
      'startUsageTrackingService';
  static const String methodStopUsageTrackingService =
      'stopUsageTrackingService';
  static const String methodUpdateBlockedApps = 'updateBlockedApps';
  static const String methodUpdateSchedules = 'updateSchedules';
  static const String methodUpdateUsageLimits = 'updateUsageLimits';
  static const String methodGetAppUsageStats = 'getAppUsageStats';
  static const String methodStartFocusSession = 'startFocusSession';
  static const String methodEndFocusSession = 'endFocusSession';
  static const String methodSetBlockScreenStyle = 'setBlockScreenStyle';
  static const String methodSyncBlockScreenCustomization =
      'syncBlockScreenCustomization';
  static const String methodCheckNotificationListenerPermission =
      'checkNotificationListenerPermission';
  static const String methodRequestNotificationListenerPermission =
      'requestNotificationListenerPermission';
  static const String methodIsServiceRunning = 'isServiceRunning';

  // Callback Methods (Native -> Flutter)
  static const String callbackOnAppBlocked = 'onAppBlocked';
  static const String callbackOnServiceStatusChanged = 'onServiceStatusChanged';

  // Focus Mode Presets
  static const List<String> socialMediaPackages = [
    'com.facebook.katana',
    'com.instagram.android',
    'com.twitter.android',
    'com.snapchat.android',
    'com.whatsapp',
    'com.tiktok',
  ];

  static const List<String> gamesPackages = [
    'com.mojang.minecraftpe',
    'com.supercell.clashofclans',
    'com.king.candycrushsaga',
    'com.pubg.krmobile',
    'com.kiloo.subwaysurf',
  ];

  // App Settings
  static const int defaultUnlockTimer = 30; // seconds
  static const int maxPinLength = 4;
  static const int minPinLength = 4;

  // Days of Week (1 = Monday, 7 = Sunday)
  static const Map<int, String> daysOfWeek = {
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  // English days for display
  static const Map<int, String> daysOfWeekEn = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  // Quotes for Unblocking Challenges
  static const List<String> unblockQuotes = [
    'النجاح هو القدرة على الانتقال من فشل إلى فشل دون فقدان الحماس.',
    'الوقت هو أثمن ما يملكه الإنسان، فلا تضعه فيما لا ينفع.',
    'الانضباط هو الجسر بين الأهداف والإنجازات.',
    'لا تؤجل عمل اليوم إلى الغد.',
    'العقل القوي يركز على الأفكار، والعقل المتوسط يركز على الأحداث.',
    'سر النجاح هو الثبات على الهدف.',
    'ما نفعله كل يوم هو ما يحدد من نحن.',
  ];
}
