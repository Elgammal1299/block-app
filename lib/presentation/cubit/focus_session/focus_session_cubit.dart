import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/focus_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/models/focus_session.dart';
import 'focus_session_state.dart';

class FocusSessionCubit extends Cubit<FocusSessionState> {
  final FocusRepository _focusRepository;
  final SettingsRepository _settingsRepository;

  Timer? _timer;
  Timer? _persistTimer;
  FocusSession? _currentSession;

  FocusSessionCubit(this._focusRepository, this._settingsRepository)
      : super(FocusSessionInitial()) {
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    emit(FocusSessionLoading());
    try {
      final session = await _focusRepository.getActiveSession();

      if (session != null && session.isActive) {
        _currentSession = session;
        _startTimer();
        emit(FocusSessionActive(session, session.remainingSeconds));
      } else {
        emit(FocusSessionIdle());
      }
    } catch (e) {
      emit(FocusSessionError(e.toString()));
    }
  }

  Future<bool> startSession(String focusListId, int durationMinutes) async {
    // Validate that no session is active
    if (state is FocusSessionActive) {
      emit(const FocusSessionError('A session is already active'));
      return false;
    }

    // Validate duration
    if (durationMinutes < 1 || durationMinutes > 480) {
      emit(const FocusSessionError('Invalid duration (1-480 minutes)'));
      return false;
    }

    try {
      final success =
          await _focusRepository.startSession(focusListId, durationMinutes);

      if (success) {
        final session = await _focusRepository.getActiveSession();
        if (session != null) {
          _currentSession = session;
          _startTimer();
          emit(FocusSessionActive(session, session.remainingSeconds));
          return true;
        }
      }

      emit(const FocusSessionError('Failed to start session'));
      return false;
    } catch (e) {
      emit(FocusSessionError(e.toString()));
      return false;
    }
  }

  Future<bool> cancelSession() async {
    if (_currentSession == null || state is! FocusSessionActive) {
      return false;
    }

    try {
      _stopTimer();

      await _focusRepository.cancelSession(_currentSession!);

      _currentSession = null;
      emit(FocusSessionIdle());
      return true;
    } catch (e) {
      emit(FocusSessionError(e.toString()));
      return false;
    }
  }

  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    try {
      _stopTimer();

      await _focusRepository.completeSession(_currentSession!);

      // Update focus streak
      await _settingsRepository.updateFocusStreak();

      final completedSession = _currentSession!;
      _currentSession = null;

      emit(FocusSessionCompleted(completedSession));

      // After showing completion, go back to idle
      await Future.delayed(const Duration(seconds: 2));
      if (state is FocusSessionCompleted) {
        emit(FocusSessionIdle());
      }
    } catch (e) {
      emit(FocusSessionError(e.toString()));
    }
  }

  void _startTimer() {
    _stopTimer(); // Stop any existing timer

    // Main timer - ticks every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentSession == null) {
        _stopTimer();
        return;
      }

      final remainingSeconds = _currentSession!.remainingSeconds;

      if (remainingSeconds <= 0) {
        // Session completed
        _completeSession();
      } else {
        // Update UI with remaining time
        emit(FocusSessionActive(_currentSession!, remainingSeconds));
      }
    });

    // Persist timer - saves session every 30 seconds
    _persistTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_currentSession != null) {
        await _focusRepository.saveActiveSession(_currentSession!);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
