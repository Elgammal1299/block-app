import 'package:flutter/material.dart';
import '../../../data/models/blocked_app.dart';
import '../../../data/models/app_info.dart';
import '../../../../core/localization/app_localizations.dart';

class BlockedAppCard extends StatelessWidget {
  final BlockedApp blockedApp;
  final AppInfo appInfo;
  final ThemeData theme;
  final VoidCallback onRemove;

  const BlockedAppCard({
    super.key,
    required this.blockedApp,
    required this.appInfo,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = blockedApp.scheduleIds.isNotEmpty;
    final localizations = AppLocalizations.of(context);
    final scheduleText = hasSchedules
        ? localizations.translate('schedules_count').replaceAll('{count}', blockedApp.scheduleIds.length.toString())
        : localizations.alwaysBlocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // App Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: appInfo.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(appInfo.icon!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.apps, size: 32, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blockedApp.appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasSchedules ? Icons.schedule : Icons.block,
                          size: 14,
                          color: hasSchedules ? Colors.blue : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scheduleText,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasSchedules ? Colors.blue : Colors.red,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (blockedApp.blockAttempts > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.front_hand,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizations.translate('block_attempts_count').replaceAll('{count}', blockedApp.blockAttempts.toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Remove Button
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                tooltip: localizations.unblock,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
