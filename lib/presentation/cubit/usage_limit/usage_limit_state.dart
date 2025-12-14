import '../../../data/models/app_usage_limit.dart';

abstract class UsageLimitState {}

class UsageLimitInitial extends UsageLimitState {}

class UsageLimitLoading extends UsageLimitState {}

class UsageLimitLoaded extends UsageLimitState {
  final List<AppUsageLimit> limits;

  UsageLimitLoaded(this.limits);
}

class UsageLimitError extends UsageLimitState {
  final String message;

  UsageLimitError(this.message);
}
