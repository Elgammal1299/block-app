import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../view_model/suggestions_cubit/suggestions_cubit.dart';
import '../../../view_model/suggestions_cubit/suggestions_state.dart';

class SmartSuggestionCard extends StatelessWidget {
  const SmartSuggestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartSuggestionsCubit, SuggestionsState>(
      builder: (context, state) {
        if (state is SuggestionsLoading) {
          return const SizedBox.shrink();
        }

        if (state is! SuggestionsLoaded || !state.hasSuggestions) {
          return const SizedBox.shrink();
        }

        final suggestion = state.currentSuggestion!;
        final theme = Theme.of(context);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: suggestion.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: suggestion.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: suggestion.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: suggestion.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    context
                        .read<SmartSuggestionsCubit>()
                        .dismissSuggestion(suggestion.id);
                  },
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
