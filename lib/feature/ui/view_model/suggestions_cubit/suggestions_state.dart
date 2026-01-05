import '../../../data/models/smart_suggestion.dart';

abstract class SuggestionsState {
  const SuggestionsState();
}

class SuggestionsInitial extends SuggestionsState {
  const SuggestionsInitial();
}

class SuggestionsLoading extends SuggestionsState {
  const SuggestionsLoading();
}

class SuggestionsLoaded extends SuggestionsState {
  final List<SmartSuggestion> suggestions;

  const SuggestionsLoaded(this.suggestions);

  bool get hasSuggestions => suggestions.isNotEmpty;
  SmartSuggestion? get currentSuggestion =>
      suggestions.isNotEmpty ? suggestions.first : null;
}

class SuggestionsEmpty extends SuggestionsState {
  const SuggestionsEmpty();
}

class SuggestionsError extends SuggestionsState {
  final String message;

  const SuggestionsError(this.message);
}
