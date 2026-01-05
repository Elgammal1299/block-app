import 'package:equatable/equatable.dart';
import '../../../data/models/custom_focus_mode.dart';

/// Base state for CustomFocusModeCubit
abstract class CustomFocusModeState extends Equatable {
  const CustomFocusModeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CustomFocusModeInitial extends CustomFocusModeState {
  const CustomFocusModeInitial();
}

/// Loading state
class CustomFocusModeLoading extends CustomFocusModeState {
  const CustomFocusModeLoading();
}

/// Loaded state with custom modes
class CustomFocusModeLoaded extends CustomFocusModeState {
  final List<CustomFocusMode> modes;

  const CustomFocusModeLoaded(this.modes);

  @override
  List<Object?> get props => [modes];

  /// Get a mode by ID
  CustomFocusMode? getModeById(String id) {
    try {
      return modes.firstWhere((mode) => mode.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get modes sorted by most recent
  List<CustomFocusMode> get sortedByRecent {
    final sorted = List<CustomFocusMode>.from(modes);
    sorted.sort((a, b) {
      if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
      if (a.lastUsedAt == null) return 1;
      if (b.lastUsedAt == null) return -1;
      return b.lastUsedAt!.compareTo(a.lastUsedAt!);
    });
    return sorted;
  }

  /// Get modes by type
  List<CustomFocusMode> getModesByType(CustomModeBlockType type) {
    return modes.where((mode) => mode.blockType == type).toList();
  }
}

/// Error state
class CustomFocusModeError extends CustomFocusModeState {
  final String message;

  const CustomFocusModeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Mode created successfully
class CustomFocusModeCreated extends CustomFocusModeState {
  final CustomFocusMode mode;

  const CustomFocusModeCreated(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Mode updated successfully
class CustomFocusModeUpdated extends CustomFocusModeState {
  final CustomFocusMode mode;

  const CustomFocusModeUpdated(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Mode deleted successfully
class CustomFocusModeDeleted extends CustomFocusModeState {
  final String modeId;

  const CustomFocusModeDeleted(this.modeId);

  @override
  List<Object?> get props => [modeId];
}
