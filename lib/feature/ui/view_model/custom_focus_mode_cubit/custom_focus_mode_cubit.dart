import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/custom_focus_mode.dart';
import '../../../data/repositories/custom_focus_mode_repository.dart';
import '../../../../core/utils/app_logger.dart';
import 'custom_focus_mode_state.dart';

/// Cubit for managing custom focus modes
class CustomFocusModeCubit extends Cubit<CustomFocusModeState> {
  final CustomFocusModeRepository _repository;

  CustomFocusModeCubit(this._repository) : super(const CustomFocusModeInitial()) {
    // تحميل الأوضاع تلقائياً عند الإنشاء
    loadCustomModes();
  }

  /// Load all custom modes
  Future<void> loadCustomModes() async {
    try {
      emit(const CustomFocusModeLoading());

      final modes = await _repository.getAllCustomModes();

      emit(CustomFocusModeLoaded(modes));
    } catch (e) {
      emit(CustomFocusModeError('فشل تحميل الأوضاع المخصصة: ${e.toString()}'));
    }
  }

  /// Create a new custom mode
  Future<void> createCustomMode(CustomFocusMode mode) async {
    try {
      emit(const CustomFocusModeLoading());

      // Validate the mode
      if (!_repository.validateMode(mode)) {
        emit(const CustomFocusModeError('بيانات الوضع غير صحيحة. تأكد من ملء جميع الحقول المطلوبة.'));
        await loadCustomModes(); // عودة للحالة السابقة
        return;
      }

      // Check if name already exists
      final nameExists = await _repository.isModeNameExists(mode.name);
      if (nameExists) {
        emit(const CustomFocusModeError('اسم الوضع موجود بالفعل. اختر اسماً آخر.'));
        await loadCustomModes();
        return;
      }

      // Save the mode
      final success = await _repository.saveCustomMode(mode);

      if (success) {
        emit(CustomFocusModeCreated(mode));
        // Reload to show the new mode
        await loadCustomModes();
      } else {
        emit(const CustomFocusModeError('فشل حفظ الوضع المخصص'));
        await loadCustomModes();
      }
    } catch (e) {
      emit(CustomFocusModeError('خطأ في إنشاء الوضع: ${e.toString()}'));
      await loadCustomModes();
    }
  }

  /// Update an existing custom mode
  Future<void> updateCustomMode(CustomFocusMode mode) async {
    try {
      emit(const CustomFocusModeLoading());

      // Validate the mode
      if (!_repository.validateMode(mode)) {
        emit(const CustomFocusModeError('بيانات الوضع غير صحيحة'));
        await loadCustomModes();
        return;
      }

      // Check if name already exists (excluding current mode)
      final nameExists = await _repository.isModeNameExists(
        mode.name,
        excludeId: mode.id,
      );
      if (nameExists) {
        emit(const CustomFocusModeError('اسم الوضع موجود بالفعل'));
        await loadCustomModes();
        return;
      }

      // Update the mode
      final success = await _repository.updateCustomMode(mode);

      if (success) {
        emit(CustomFocusModeUpdated(mode));
        await loadCustomModes();
      } else {
        emit(const CustomFocusModeError('فشل تحديث الوضع'));
        await loadCustomModes();
      }
    } catch (e) {
      emit(CustomFocusModeError('خطأ في تحديث الوضع: ${e.toString()}'));
      await loadCustomModes();
    }
  }

  /// Delete a custom mode
  Future<void> deleteCustomMode(String id) async {
    try {
      emit(const CustomFocusModeLoading());

      final success = await _repository.deleteCustomMode(id);

      if (success) {
        emit(CustomFocusModeDeleted(id));
        await loadCustomModes();
      } else {
        emit(const CustomFocusModeError('فشل حذف الوضع'));
        await loadCustomModes();
      }
    } catch (e) {
      emit(CustomFocusModeError('خطأ في حذف الوضع: ${e.toString()}'));
      await loadCustomModes();
    }
  }

  /// Update last used time for a mode
  Future<void> updateLastUsed(String id) async {
    try {
      await _repository.updateLastUsed(id);
      // Reload to reflect the change
      await loadCustomModes();
    } catch (e) {
      // Silent fail - not critical
      AppLogger.w('Error updating last used: $e');
    }
  }

  /// Get a mode by ID
  CustomFocusMode? getModeById(String id) {
    final currentState = state;
    if (currentState is CustomFocusModeLoaded) {
      return currentState.getModeById(id);
    }
    return null;
  }

  /// Get modes sorted by recent usage
  List<CustomFocusMode> getSortedByRecent() {
    final currentState = state;
    if (currentState is CustomFocusModeLoaded) {
      return currentState.sortedByRecent;
    }
    return [];
  }

  /// Get modes by type
  List<CustomFocusMode> getModesByType(CustomModeBlockType type) {
    final currentState = state;
    if (currentState is CustomFocusModeLoaded) {
      return currentState.getModesByType(type);
    }
    return [];
  }

  /// Get total count of custom modes
  int getModesCount() {
    final currentState = state;
    if (currentState is CustomFocusModeLoaded) {
      return currentState.modes.length;
    }
    return 0;
  }

  /// Check if a mode name already exists
  Future<bool> isModeNameExists(String name, {String? excludeId}) async {
    try {
      return await _repository.isModeNameExists(name, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }
}
