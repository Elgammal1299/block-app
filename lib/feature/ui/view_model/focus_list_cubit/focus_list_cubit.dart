import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/focus_repository.dart';
import '../../../data/models/focus_list.dart';
import 'focus_list_state.dart';

class FocusListCubit extends Cubit<FocusListState> {
  final FocusRepository _focusRepository;

  FocusListCubit(this._focusRepository) : super(FocusListInitial()) {
    loadFocusLists();
  }

  Future<void> loadFocusLists() async {
    emit(FocusListLoading());
    try {
      // Load all focus lists
      final lists = await _focusRepository.getFocusLists();

      // Sort by last used, then by created date
      lists.sort((a, b) {
        // Sort by last used
        if (a.lastUsedAt != null && b.lastUsedAt != null) {
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        }
        if (a.lastUsedAt != null) return -1;
        if (b.lastUsedAt != null) return 1;

        // Finally, sort by created date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

      emit(FocusListLoaded(lists));
    } catch (e) {
      emit(FocusListError(e.toString()));
    }
  }

  Future<bool> createFocusList(String name, List<String> packages) async {
    if (state is! FocusListLoaded) return false;

    try {
      final result =
          await _focusRepository.createFocusList(name, packages);

      if (result) {
        await loadFocusLists();
      }

      return result;
    } catch (e) {
      emit(FocusListError(e.toString()));
      return false;
    }
  }

  Future<bool> updateFocusList(FocusList list) async {
    if (state is! FocusListLoaded) return false;

    try {
      final result = await _focusRepository.updateFocusList(list);

      if (result) {
        await loadFocusLists();
      }

      return result;
    } catch (e) {
      emit(FocusListError(e.toString()));
      return false;
    }
  }

  Future<bool> deleteFocusList(String id) async {
    if (state is! FocusListLoaded) return false;

    try {
      final result = await _focusRepository.deleteFocusList(id);

      if (result) {
        await loadFocusLists();
      }

      return result;
    } catch (e) {
      emit(FocusListError(e.toString()));
      return false;
    }
  }

  Future<void> updateLastUsed(String listId) async {
    try {
      await _focusRepository.updateLastUsed(listId);
      await loadFocusLists();
    } catch (e) {
      // Silent fail - not critical
    }
  }
}
