import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class LoadingMessage extends StatelessWidget {
  const LoadingMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          localizations.loading,
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
