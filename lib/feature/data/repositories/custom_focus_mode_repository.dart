import 'package:uuid/uuid.dart';
import '../models/custom_focus_mode.dart';
import '../local/shared_prefs_service.dart';

/// Repository for managing custom focus modes
class CustomFocusModeRepository {
  final SharedPrefsService _prefsService;
  final Uuid _uuid = const Uuid();

  CustomFocusModeRepository(this._prefsService);

  /// Get all custom focus modes
  Future<List<CustomFocusMode>> getAllCustomModes() async {
    try {
      return await _prefsService.getCustomFocusModes();
    } catch (e) {
      print('Error loading custom modes: $e');
      return [];
    }
  }

  /// Get a custom mode by ID
  Future<CustomFocusMode?> getCustomModeById(String id) async {
    try {
      return await _prefsService.getCustomFocusModeById(id);
    } catch (e) {
      print('Error loading custom mode $id: $e');
      return null;
    }
  }

  /// Save a new custom focus mode
  Future<bool> saveCustomMode(CustomFocusMode mode) async {
    try {
      // إذا لم يكن هناك ID، أنشئ واحد جديد
      if (mode.id.isEmpty) {
        final modeWithId = mode.copyWith(id: _uuid.v4());
        return await _prefsService.addCustomFocusMode(modeWithId);
      }

      return await _prefsService.addCustomFocusMode(mode);
    } catch (e) {
      print('Error saving custom mode: $e');
      return false;
    }
  }

  /// Update an existing custom focus mode
  Future<bool> updateCustomMode(CustomFocusMode mode) async {
    try {
      // تحديث lastUsedAt عند التعديل
      final updatedMode = mode.copyWith(
        lastUsedAt: DateTime.now(),
      );

      return await _prefsService.updateCustomFocusMode(updatedMode);
    } catch (e) {
      print('Error updating custom mode: $e');
      return false;
    }
  }

  /// Delete a custom focus mode
  Future<bool> deleteCustomMode(String id) async {
    try {
      return await _prefsService.deleteCustomFocusMode(id);
    } catch (e) {
      print('Error deleting custom mode: $e');
      return false;
    }
  }

  /// Update the last used time for a custom mode
  Future<bool> updateLastUsed(String id) async {
    try {
      final mode = await getCustomModeById(id);
      if (mode == null) return false;

      final updatedMode = mode.copyWith(
        lastUsedAt: DateTime.now(),
      );

      return await _prefsService.updateCustomFocusMode(updatedMode);
    } catch (e) {
      print('Error updating last used: $e');
      return false;
    }
  }

  /// Get custom modes sorted by most recently used
  Future<List<CustomFocusMode>> getModesSortedByRecent() async {
    try {
      final modes = await getAllCustomModes();

      // فرز حسب آخر استخدام (الأحدث أولاً)
      modes.sort((a, b) {
        if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
        if (a.lastUsedAt == null) return 1; // b أولاً
        if (b.lastUsedAt == null) return -1; // a أولاً
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      });

      return modes;
    } catch (e) {
      print('Error sorting modes: $e');
      return [];
    }
  }

  /// Get custom modes sorted by creation date (newest first)
  Future<List<CustomFocusMode>> getModesSortedByCreation() async {
    try {
      final modes = await getAllCustomModes();

      modes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return modes;
    } catch (e) {
      print('Error sorting modes by creation: $e');
      return [];
    }
  }

  /// Get custom modes by block type
  Future<List<CustomFocusMode>> getModesByType(CustomModeBlockType type) async {
    try {
      final modes = await getAllCustomModes();
      return modes.where((mode) => mode.blockType == type).toList();
    } catch (e) {
      print('Error filtering modes by type: $e');
      return [];
    }
  }

  /// Get count of custom modes
  Future<int> getModesCount() async {
    try {
      final modes = await getAllCustomModes();
      return modes.length;
    } catch (e) {
      print('Error getting modes count: $e');
      return 0;
    }
  }

  /// Check if a mode name already exists
  Future<bool> isModeNameExists(String name, {String? excludeId}) async {
    try {
      final modes = await getAllCustomModes();

      return modes.any((mode) =>
        mode.name.toLowerCase() == name.toLowerCase() &&
        mode.id != excludeId
      );
    } catch (e) {
      print('Error checking mode name: $e');
      return false;
    }
  }

  /// Validate mode data before saving
  bool validateMode(CustomFocusMode mode) {
    // الاسم يجب أن لا يكون فارغاً
    if (mode.name.trim().isEmpty) {
      return false;
    }

    // يجب أن يكون هناك تطبيقات محظورة على الأقل
    if (mode.blockedPackages.isEmpty) {
      return false;
    }

    // التحقق من البيانات حسب نوع الحظر
    switch (mode.blockType) {
      case CustomModeBlockType.fullBlock:
        // يجب أن تكون المدة أكبر من 0
        if (mode.durationMinutes == null || mode.durationMinutes! <= 0) {
          return false;
        }
        break;

      case CustomModeBlockType.timeBased:
        // يجب أن يكون هناك أوقات وأيام
        if (mode.startTime == null ||
            mode.endTime == null ||
            mode.daysOfWeek == null ||
            mode.daysOfWeek!.isEmpty) {
          return false;
        }
        break;

      case CustomModeBlockType.usageLimit:
        // يجب أن تكون هناك حدود للاستخدام
        if (mode.usageLimitsMinutes == null ||
            mode.usageLimitsMinutes!.isEmpty) {
          return false;
        }
        break;
    }

    return true;
  }
}
