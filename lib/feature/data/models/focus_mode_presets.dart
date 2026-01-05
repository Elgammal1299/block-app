import '../../ui/view/widgets/app_category_filter.dart';
import '../../ui/view/widgets/focus_mode_card.dart';
import 'app_info.dart';

class FocusModePresets {
  // وضع العمل: حظر الألعاب والترفيه والسوشيال ميديا
  static const workModeBlockedCategories = [
    AppCategory.games,
    AppCategory.entertainment,
    AppCategory.social,
  ];

  // وضع النوم: السماح فقط بالمنبه والهاتف والطوارئ
  static const sleepModeAllowlist = [
    'com.google.android.deskclock', // Clock/Alarm
    'com.android.phone', // Phone
    'com.android.contacts', // Contacts
    'com.android.dialer', // Dialer
    'com.samsung.android.incallui', // Samsung Phone
    'com.samsung.android.app.clockpackage', // Samsung Clock
  ];

  /// توليد قائمة التطبيقات المحظورة لوضع معين
  static List<String> generatePresetAppList(
    FocusModeType modeType,
    List<AppInfo> installedApps,
  ) {
    switch (modeType) {
      case FocusModeType.work:
        return _filterAppsByCategories(
          installedApps,
          workModeBlockedCategories,
        );

      case FocusModeType.sleep:
        return _filterAppsForSleepMode(installedApps);
        
      case FocusModeType.study:
        return _filterAppsByCategories(
          installedApps,
          workModeBlockedCategories,
        );
    }
  }

  /// تصفية التطبيقات بناءً على الفئات
  static List<String> _filterAppsByCategories(
    List<AppInfo> apps,
    List<AppCategory> blockedCategories,
  ) {
    return apps
        .where((app) {
          final category = AppCategoryHelper.getAppCategory(app);
          return blockedCategories.contains(category);
        })
        .map((app) => app.packageName)
        .toList();
  }

  /// تصفية خاصة لوضع النوم (عكسية - نحظر كل شيء ما عدا القائمة البيضاء)
  static List<String> _filterAppsForSleepMode(List<AppInfo> apps) {
    return apps
        .where((app) => !sleepModeAllowlist.contains(app.packageName))
        .map((app) => app.packageName)
        .toList();
  }

  /// الحصول على وصف القائمة المسبقة
  static String getPresetDescription(FocusModeType modeType) {
    switch (modeType) {
      case FocusModeType.work:
        return 'يحظر: الألعاب، الترفيه، السوشيال ميديا';
      case FocusModeType.sleep:
        return 'يحظر: جميع التطبيقات ما عدا المنبه والهاتف';
      case FocusModeType.study:
        return 'يحظر: الألعاب، الترفيه، السوشيال ميديا';
    }
  }
}
