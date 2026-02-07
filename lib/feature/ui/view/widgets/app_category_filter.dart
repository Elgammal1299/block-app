import 'package:flutter/material.dart';
import '../../../data/models/app_info.dart';

enum AppCategory {
  all('الكل', Icons.apps, Colors.grey),
  social('وسائل التواصل', Icons.people, Colors.blue),
  games('الألعاب', Icons.sports_esports, Colors.purple),
  entertainment('الترفيه', Icons.movie, Colors.red),
  productivity('الإنتاجية', Icons.work, Colors.green),
  communication('التواصل', Icons.chat, Colors.teal),
  shopping('التسوق', Icons.shopping_cart, Colors.orange),
  news('الأخبار', Icons.newspaper, Colors.indigo),
  others('أخرى', Icons.more_horiz, Colors.blueGrey);

  const AppCategory(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;
}

class AppCategoryFilter extends StatelessWidget {
  final AppCategory selectedCategory;
  final Function(AppCategory) onCategoryChanged;

  const AppCategoryFilter({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppCategory.values.length,
        itemBuilder: (context, index) {
          final category = AppCategory.values[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 18,
                    color: isSelected ? Colors.white : category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(category.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategoryChanged(category);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: category.color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : category.color,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}

class AppCategoryHelper {
  static final Map<AppCategory, List<String>> _categoryKeywords = {
    AppCategory.social: [
      'facebook',
      'instagram',
      'twitter',
      'snapchat',
      'tiktok',
      'whatsapp',
      'telegram',
    ],
    AppCategory.games: [
      'game',
      'play',
      'puzzle',
      'racing',
      'casino',
      'betting',
      'arcade',
    ],
    AppCategory.entertainment: [
      'youtube',
      'netflix',
      'spotify',
      'video',
      'music',
      'stream',
      'tv',
      'movie',
    ],
    AppCategory.productivity: [
      'office',
      'document',
      'calendar',
      'email',
      'note',
      'tool',
      'calculator',
      'clock',
    ],
    AppCategory.communication: [
      'messenger',
      'message',
      'call',
      'phone',
      'contact',
      'mail',
    ],
    AppCategory.shopping: [
      'amazon',
      'shop',
      'store',
      'buy',
      'cart',
      'market',
      'commerce',
    ],
    AppCategory.news: ['news', 'journal', 'article', 'paper', 'daily'],
  };

  static AppCategory getAppCategory(AppInfo app) {
    final text = '${app.appName} ${app.packageName}'.toLowerCase();

    // Ordered check for priority and anti-duplication
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((keyword) => text.contains(keyword))) {
        return entry.key;
      }
    }

    // Default fallback to "others" (NOT "all")
    return AppCategory.others;
  }

  static List<AppInfo> filterAppsByCategory(
    List<AppInfo> apps,
    AppCategory category,
  ) {
    if (category == AppCategory.all) {
      return apps;
    }

    return apps.where((app) => getAppCategory(app) == category).toList();
  }
}
