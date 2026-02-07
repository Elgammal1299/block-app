import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class EmptyBlockedAppsMessage extends StatelessWidget {
  final bool isSearch;
  final VoidCallback? onAddApps;
  const EmptyBlockedAppsMessage({super.key, required this.isSearch, this.onAddApps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSearch ? Icons.search_off : Icons.check_circle_outline,
          size: 80,
          color: theme.primaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          isSearch ? localizations.noAppsFound : localizations.noBlockedApps,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSearch ? localizations.searchNoResultHint : localizations.noBlockedAppsHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        if (!isSearch && onAddApps != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddApps,
            icon: const Icon(Icons.add),
            label: Text(localizations.blockApps),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}
