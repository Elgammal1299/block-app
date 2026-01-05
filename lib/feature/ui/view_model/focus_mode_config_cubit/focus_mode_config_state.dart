import 'package:equatable/equatable.dart';
import '../../../data/models/focus_mode_config.dart';
import '../../view/widgets/focus_mode_card.dart';

abstract class FocusModeConfigState extends Equatable {
  const FocusModeConfigState();

  @override
  List<Object?> get props => [];
}

class FocusModeConfigInitial extends FocusModeConfigState {}

class FocusModeConfigLoading extends FocusModeConfigState {}

class FocusModeConfigLoaded extends FocusModeConfigState {
  final Map<FocusModeType, FocusModeConfig> configs;

  const FocusModeConfigLoaded(this.configs);

  @override
  List<Object?> get props => [configs];

  FocusModeConfig? getConfig(FocusModeType type) => configs[type];
}

class FocusModeConfigError extends FocusModeConfigState {
  final String message;

  const FocusModeConfigError(this.message);

  @override
  List<Object?> get props => [message];
}
