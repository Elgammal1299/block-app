import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/suggestions_repository.dart';
import 'suggestions_state.dart';

class SmartSuggestionsCubit extends Cubit<SuggestionsState> {
  final SuggestionsRepository _repository;

  SmartSuggestionsCubit(this._repository) : super(const SuggestionsInitial());

  Future<void> generateSuggestions() async {
    try {
      emit(const SuggestionsLoading());
      final suggestions = await _repository.generateSuggestions();

      if (suggestions.isEmpty) {
        emit(const SuggestionsEmpty());
      } else {
        emit(SuggestionsLoaded(suggestions));
      }
    } catch (e) {
      emit(SuggestionsError('فشل توليد الاقتراحات: $e'));
    }
  }

  Future<void> dismissSuggestion(String suggestionId) async {
    try {
      await _repository.dismissSuggestion(suggestionId);
      await generateSuggestions();
    } catch (e) {
      emit(SuggestionsError('فشل إخفاء الاقتراح: $e'));
    }
  }

  Future<void> clearDismissedSuggestions() async {
    try {
      await _repository.clearDismissedSuggestions();
      await generateSuggestions();
    } catch (e) {
      emit(SuggestionsError('فشل مسح الاقتراحات المخفية: $e'));
    }
  }
}
