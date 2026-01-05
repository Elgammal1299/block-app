import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/focus_mode_config_repository.dart';
import '../../../data/models/focus_mode_config.dart';
import '../../view/widgets/focus_mode_card.dart';
import 'focus_mode_config_state.dart';

class FocusModeConfigCubit extends Cubit<FocusModeConfigState> {
  final FocusModeConfigRepository _repository;

  FocusModeConfigCubit(this._repository) : super(FocusModeConfigInitial());

  /// تحميل جميع الإعدادات
  Future<void> loadConfigs() async {
    try {
      emit(FocusModeConfigLoading());

      final configs = await _repository.getAllConfigs();

      // تحويل القائمة إلى Map للوصول السريع
      final configsMap = <FocusModeType, FocusModeConfig>{};
      for (var config in configs) {
        configsMap[config.modeType] = config;
      }

      emit(FocusModeConfigLoaded(configsMap));
    } catch (e) {
      emit(FocusModeConfigError('فشل في تحميل الإعدادات: ${e.toString()}'));
    }
  }

  /// تحديث إعدادات وضع معين
  Future<void> updateConfig(FocusModeConfig config) async {
    try {
      final success = await _repository.updateConfig(config);

      if (success) {
        // إعادة تحميل الإعدادات
        await loadConfigs();
      } else {
        emit(const FocusModeConfigError('فشل في حفظ الإعدادات'));
      }
    } catch (e) {
      emit(FocusModeConfigError('خطأ في حفظ الإعدادات: ${e.toString()}'));
    }
  }

  /// تخصيص تطبيقات وضع معين
  Future<void> customizeModeApps(
    FocusModeType mode,
    List<String> packages,
  ) async {
    try {
      final success = await _repository.customizeModeApps(mode, packages);

      if (success) {
        await loadConfigs();
      } else {
        emit(const FocusModeConfigError('فشل في تخصيص التطبيقات'));
      }
    } catch (e) {
      emit(FocusModeConfigError('خطأ في تخصيص التطبيقات: ${e.toString()}'));
    }
  }

  /// تحديث مدة وضع معين
  Future<void> updateModeDuration(FocusModeType mode, int minutes) async {
    try {
      final config = await _repository.getConfigForMode(mode);
      if (config == null) {
        emit(const FocusModeConfigError('لم يتم العثور على إعدادات الوضع'));
        return;
      }

      final updatedConfig = config.copyWith(
        customDurationMinutes: minutes,
        useDefaultDuration: false,
        isCustomized: true,
      );

      await updateConfig(updatedConfig);
    } catch (e) {
      emit(FocusModeConfigError('خطأ في تحديث المدة: ${e.toString()}'));
    }
  }

  /// إعادة تعيين وضع للإعدادات الأصلية
  Future<void> resetModeToDefault(FocusModeType mode) async {
    try {
      final success = await _repository.resetModeToDefault(mode);

      if (success) {
        await loadConfigs();
      } else {
        emit(const FocusModeConfigError('فشل في إعادة التعيين'));
      }
    } catch (e) {
      emit(FocusModeConfigError('خطأ في إعادة التعيين: ${e.toString()}'));
    }
  }

  /// تحديث آخر استخدام
  Future<void> updateLastUsed(FocusModeType mode) async {
    try {
      await _repository.updateLastUsed(mode);
      // لا داعي لإعادة تحميل كل الإعدادات، فقط نحدث lastUsedAt
    } catch (e) {
      // نتجاهل الخطأ لأنه ليس حرج
    }
  }

  /// الحصول على إعدادات وضع معين من الـ state الحالية
  FocusModeConfig? getConfigForMode(FocusModeType mode) {
    if (state is FocusModeConfigLoaded) {
      return (state as FocusModeConfigLoaded).getConfig(mode);
    }
    return null;
  }

  /// الحصول على عدد التطبيقات المحظورة في وضع معين
  Future<int> getBlockedAppsCount(FocusModeType mode) async {
    try {
      return await _repository.getBlockedAppsCount(mode);
    } catch (e) {
      return 0;
    }
  }
}
