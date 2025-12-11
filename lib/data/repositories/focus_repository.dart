import 'package:uuid/uuid.dart';
import '../local/shared_prefs_service.dart';
import '../models/focus_list.dart';
import '../models/focus_session.dart';
import '../models/focus_session_history.dart';
import '../models/focus_session_status.dart';
import '../../services/platform_channel_service.dart';

class FocusRepository {
  final SharedPrefsService _prefsService;
  final PlatformChannelService _platformService;
  final Uuid _uuid = const Uuid();

  FocusRepository(this._prefsService, this._platformService);

  // ========== Focus Lists Management ==========

  Future<List<FocusList>> getFocusLists() async {
    return await _prefsService.getFocusLists();
  }

  Future<bool> createFocusList(String name, List<String> packageNames) async {
    final list = FocusList(
      id: _uuid.v4(),
      name: name,
      packageNames: packageNames,
      isPreset: false,
      createdAt: DateTime.now(),
    );
    return await _prefsService.addFocusList(list);
  }

  Future<bool> updateFocusList(FocusList list) async {
    return await _prefsService.updateFocusList(list);
  }

  Future<bool> deleteFocusList(String id) async {
    return await _prefsService.deleteFocusList(id);
  }

  Future<bool> updateLastUsed(String listId) async {
    final lists = await _prefsService.getFocusLists();
    final index = lists.indexWhere((l) => l.id == listId);

    if (index != -1) {
      final updatedList = lists[index].copyWith(lastUsedAt: DateTime.now());
      return await _prefsService.updateFocusList(updatedList);
    }

    return false;
  }


  // ========== Focus Session Management ==========

  Future<FocusSession?> getActiveSession() async {
    final session = await _prefsService.getActiveSession();

    // Check if session is expired
    if (session != null && session.isExpired) {
      // Auto-complete expired session
      await completeSession(session);
      return null;
    }

    return session;
  }

  Future<bool> startSession(String focusListId, int durationMinutes) async {
    // Check if there's already an active session
    final activeSession = await getActiveSession();
    if (activeSession != null) {
      return false; // Can't start a new session while one is active
    }

    // Get the focus list
    final lists = await _prefsService.getFocusLists();
    final focusList = lists.firstWhere(
      (list) => list.id == focusListId,
      orElse: () => throw Exception('Focus list not found'),
    );

    // Create new session
    final session = FocusSession(
      id: _uuid.v4(),
      focusListId: focusListId,
      focusListName: focusList.name,
      durationMinutes: durationMinutes,
      startTime: DateTime.now(),
      status: FocusSessionStatus.active,
      blockedPackages: List.from(focusList.packageNames),
    );

    // Save session locally
    final saved = await _prefsService.saveActiveSession(session);

    if (saved) {
      // Update last used time for the list
      await updateLastUsed(focusListId);

      // Sync to native Android
      await _syncActiveSessionToNative(session);
    }

    return saved;
  }

  Future<bool> completeSession(FocusSession session) async {
    // Update session status
    final completedSession = session.copyWith(
      status: FocusSessionStatus.completed,
      endTime: DateTime.now(),
    );

    // Add to history
    final history = FocusSessionHistory(
      id: session.id,
      focusListName: session.focusListName,
      durationMinutes: session.durationMinutes,
      completedAt: DateTime.now(),
      wasCompleted: true,
    );

    await _prefsService.addSessionToHistory(history);

    // Clear active session
    await _prefsService.clearActiveSession();

    // Clear native session
    await _platformService.endFocusSession();

    return true;
  }

  Future<bool> cancelSession(FocusSession session) async {
    // Update session status
    final cancelledSession = session.copyWith(
      status: FocusSessionStatus.cancelled,
      endTime: DateTime.now(),
    );

    // Add to history (marked as not completed)
    final history = FocusSessionHistory(
      id: session.id,
      focusListName: session.focusListName,
      durationMinutes: session.durationMinutes,
      completedAt: DateTime.now(),
      wasCompleted: false,
    );

    await _prefsService.addSessionToHistory(history);

    // Clear active session
    await _prefsService.clearActiveSession();

    // Clear native session
    await _platformService.endFocusSession();

    return true;
  }

  Future<bool> saveActiveSession(FocusSession session) async {
    return await _prefsService.saveActiveSession(session);
  }

  // ========== Session History ==========

  Future<List<FocusSessionHistory>> getHistory({int limit = 50}) async {
    return await _prefsService.getSessionHistory(limit: limit);
  }

  Future<bool> clearHistory() async {
    return await _prefsService.clearAllHistory();
  }

  // ========== Native Sync ==========

  Future<void> _syncActiveSessionToNative(FocusSession? session) async {
    if (session == null) {
      await _platformService.endFocusSession();
      return;
    }

    try {
      await _platformService.startFocusSession(
        packageNames: session.blockedPackages,
        durationMinutes: session.durationMinutes,
      );
    } catch (e) {
      // Log error but don't fail the operation
      print('Error syncing focus session to native: $e');
    }
  }
}
