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
  news('الأخبار', Icons.newspaper, Colors.indigo);

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
                    color: isSelected 
                        ? Colors.white
                        : category.color,
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
                color: isSelected 
                    ? Colors.white
                    : category.color,
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
  static AppCategory getAppCategory(AppInfo app) {
    final packageName = app.packageName.toLowerCase();
    final appName = app.appName.toLowerCase();
    
    // Social media
    if (packageName.contains('facebook') || 
        packageName.contains('instagram') ||
        packageName.contains('twitter') ||
        packageName.contains('snapchat') ||
        packageName.contains('tiktok') ||
        packageName.contains('whatsapp') ||
        packageName.contains('telegram') ||
        appName.contains('facebook') ||
        appName.contains('instagram') ||
        appName.contains('twitter') ||
        appName.contains('snapchat') ||
        appName.contains('tiktok') ||
        appName.contains('whatsapp') ||
        appName.contains('telegram')) {
      return AppCategory.social;
    }
    
    // Games
    if (packageName.contains('game') || 
        appName.contains('game') ||
        packageName.contains('play') ||
        appName.contains('play') ||
        packageName.contains('puzzle') ||
        appName.contains('puzzle') ||
        packageName.contains('racing') ||
        appName.contains('racing')) {
      return AppCategory.games;
    }
    
    // Entertainment
    if (packageName.contains('youtube') || 
        packageName.contains('netflix') ||
        packageName.contains('spotify') ||
        packageName.contains('video') ||
        packageName.contains('music') ||
        appName.contains('youtube') ||
        appName.contains('netflix') ||
        appName.contains('spotify') ||
        appName.contains('video') ||
        appName.contains('music')) {
      return AppCategory.entertainment;
    }
    
    // Productivity
    if (packageName.contains('office') || 
        packageName.contains('document') ||
        packageName.contains('calendar') ||
        packageName.contains('email') ||
        appName.contains('office') ||
        appName.contains('document') ||
        appName.contains('calendar') ||
        appName.contains('email')) {
      return AppCategory.productivity;
    }
    
    // Communication
    if (packageName.contains('messenger') || 
        packageName.contains('message') ||
        packageName.contains('call') ||
        packageName.contains('phone') ||
        appName.contains('messenger') ||
        appName.contains('message') ||
        appName.contains('call') ||
        appName.contains('phone')) {
      return AppCategory.communication;
    }
    
    // Shopping
    if (packageName.contains('amazon') || 
        packageName.contains('shop') ||
        packageName.contains('store') ||
        packageName.contains('buy') ||
        appName.contains('amazon') ||
        appName.contains('shop') ||
        appName.contains('store') ||
        appName.contains('buy')) {
      return AppCategory.shopping;
    }
    
    // News
    if (packageName.contains('news') || 
        packageName.contains('journal') ||
        packageName.contains('article') ||
        appName.contains('news') ||
        appName.contains('journal') ||
        appName.contains('article')) {
      return AppCategory.news;
    }
    
    return AppCategory.all;
  }
  
  static List<AppInfo> filterAppsByCategory(List<AppInfo> apps, AppCategory category) {
    if (category == AppCategory.all) {
      return apps;
    }
    
    return apps.where((app) => getAppCategory(app) == category).toList();
  }
}
