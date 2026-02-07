import '../local/shared_prefs_service.dart';
import '../models/focus_mode_config.dart';
import '../models/focus_mode_presets.dart';
import '../models/focus_list.dart';
import '../models/app_info.dart';
import '../../ui/view/widgets/focus_mode_card.dart';
import 'focus_repository.dart';
import '../../../core/services/platform_channel_service.dart';
import '../../../core/utils/app_logger.dart';

class FocusModeConfigRepository {
  final SharedPrefsService _prefsService;
  final FocusRepository _focusRepository;
  final PlatformChannelService _platformService;

  FocusModeConfigRepository(
    this._prefsService,
    this._focusRepository,
    this._platformService,
  );

  // ========== Configuration Management ==========

  /// الحصول على إعدادات وضع معين
  Future<FocusModeConfig?> getConfigForMode(FocusModeType mode) async {
    final configs = await getAllConfigs();
    try {
      return configs.firstWhere((c) => c.modeType == mode);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على كل الإعدادات
  Future<List<FocusModeConfig>> getAllConfigs() async {
    return await _prefsService.getFocusModeConfigs();
  }

  /// تحديث الإعدادات (بعد التخصيص)
  Future<bool> updateConfig(FocusModeConfig config) async {
    return await _prefsService.updateFocusModeConfig(config);
  }

  /// تحديث آخر استخدام
  Future<bool> updateLastUsed(FocusModeType mode) async {
    final config = await getConfigForMode(mode);
    if (config == null) return false;

    final updatedConfig = config.copyWith(lastUsedAt: DateTime.now());

    return await updateConfig(updatedConfig);
  }

  // ========== Preset Initialization ==========

  /// التحقق من التهيئة
  Future<bool> arePresetsInitialized() async {
    return await _prefsService.getBool('focus_presets_initialized_v2') ?? false;
  }

  /// تهيئة الأوضاع المسبقة عند أول استخدام
  Future<bool> initializePresets() async {
    try {
      // 1. الحصول على كل التطبيقات المثبتة
      final installedApps = await _platformService.getInstalledApps();

      if (installedApps.isEmpty) {
        AppLogger.w(
          'Warning: No installed apps found. Skipping preset initialization.',
        );
        return false;
      }

      // 2. لكل وضع، إنشاء قائمة ذكية
      for (var modeType in FocusModeType.values) {
        await _createPresetForMode(modeType, installedApps);
      }

      // 3. تعليم كمكتمل
      await _prefsService.setBool('focus_presets_initialized_v2', true);
      AppLogger.i('Focus mode presets initialized successfully!');
      return true;
    } catch (e) {
      AppLogger.e('Error initializing presets', e);
      return false;
    }
  }

  /// إنشاء preset لوضع معين
  Future<void> _createPresetForMode(
    FocusModeType modeType,
    List<AppInfo> installedApps,
  ) async {
    // توليد قائمة التطبيقات بناءً على الفئات
    final blockedPackages = FocusModePresets.generatePresetAppList(
      modeType,
      installedApps,
    );

    print(
      'Creating preset for ${modeType.displayName}: ${blockedPackages.length} apps',
    );

    // إنشاء FocusList
    final focusList = FocusList(
      id: 'preset_${modeType.name}',
      name: 'قائمة ${modeType.displayName}',
      packageNames: blockedPackages,
      isPreset: true,
      createdAt: DateTime.now(),
    );

    // حفظ القائمة
    final listCreated = await _focusRepository.createFocusList(
      focusList.name,
      focusList.packageNames,
    );

    if (!listCreated) {
      // إذا فشل الإنشاء، ممكن القائمة موجودة بالفعل
      // نحاول تحديثها
      await _focusRepository.updateFocusList(focusList);
    }

    // إنشاء FocusModeConfig
    final config = FocusModeConfig(
      id: 'config_${modeType.name}',
      modeType: modeType,
      focusListId: focusList.id,
      customDurationMinutes: modeType.duration.inMinutes,
      useDefaultDuration: true,
      isCustomized: false,
      createdAt: DateTime.now(),
    );

    // حفظ الإعدادات
    await _prefsService.saveFocusModeConfig(config);
  }

  // ========== Customization ==========

  /// تخصيص تطبيقات الوضع
  Future<bool> customizeModeApps(
    FocusModeType mode,
    List<String> packages,
  ) async {
    final config = await getConfigForMode(mode);
    if (config == null) return false;

    // 1. إنشاء FocusList جديدة بمعرف جديد
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newList = FocusList(
      id: '${mode.name}_custom_$timestamp',
      name: 'قائمة ${mode.displayName} - مخصصة',
      packageNames: packages,
      isPreset: false, // ليست قائمة مسبقة
      createdAt: DateTime.now(),
    );

    // 2. حفظ القائمة الجديدة
    final created = await _focusRepository.createFocusList(
      newList.name,
      newList.packageNames,
    );

    if (!created) {
      AppLogger.e('Failed to create custom focus list', null);
      return false;
    }

    // 3. تحديث Config للإشارة للقائمة الجديدة
    final updatedConfig = config.copyWith(
      focusListId: newList.id,
      isCustomized: true,
    );

    // 4. حفظ
    final updated = await updateConfig(updatedConfig);

    // ملاحظة: القائمة الأصلية (preset_study) تبقى للرجوع إليها عند Reset
    return updated;
  }

  /// إعادة تعيين وضع للإعدادات الأصلية
  Future<bool> resetModeToDefault(FocusModeType mode) async {
    try {
      // 1. الحصول على معرف القائمة الأصلية
      final presetListId = 'preset_${mode.name}';

      // 2. الحصول على الإعدادات الحالية
      final config = await getConfigForMode(mode);
      if (config == null) return false;

      // 3. حذف القائمة المخصصة (اختياري)
      if (config.isCustomized && config.focusListId != presetListId) {
        await _focusRepository.deleteFocusList(config.focusListId);
      }

      // 4. إعادة تعيين الإعدادات للافتراضية
      final resetConfig = FocusModeConfig(
        id: config.id,
        modeType: mode,
        focusListId: presetListId,
        customDurationMinutes: mode.duration.inMinutes,
        useDefaultDuration: true,
        isCustomized: false,
        addNewlyInstalledApps: false,
        blockUnsupportedBrowsers: false,
        blockAdultSites: false,
        pomodoroEnabled: false,
        createdAt: config.createdAt,
      );

      return await updateConfig(resetConfig);
    } catch (e) {
      AppLogger.e('Error resetting mode to default', e);
      return false;
    }
  }

  // ========== Helper Methods ==========

  /// الحصول على عدد التطبيقات المحظورة في وضع معين
  Future<int> getBlockedAppsCount(FocusModeType mode) async {
    final config = await getConfigForMode(mode);
    if (config == null) return 0;

    final lists = await _focusRepository.getFocusLists();
    try {
      final list = lists.firstWhere((l) => l.id == config.focusListId);
      return list.packageNames.length;
    } catch (e) {
      return 0;
    }
  }

  /// الحصول على FocusList الخاصة بوضع معين
  Future<FocusList?> getFocusListForMode(FocusModeType mode) async {
    final config = await getConfigForMode(mode);
    if (config == null) return null;

    final lists = await _focusRepository.getFocusLists();
    try {
      return lists.firstWhere((l) => l.id == config.focusListId);
    } catch (e) {
      return null;
    }
  }
}
