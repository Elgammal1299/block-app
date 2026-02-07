import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_block/core/DI/setup_get_it.dart';
import 'package:app_block/feature/ui/view_model/theme_cubit/theme_cubit.dart';
import 'package:app_block/feature/ui/view_model/theme_cubit/theme_state.dart';
import 'package:app_block/feature/ui/view_model/locale_cubit/locale_cubit.dart';
import 'package:app_block/feature/ui/view_model/locale_cubit/locale_state.dart';
import 'package:app_block/feature/data/repositories/settings_repository.dart';
import 'package:app_block/core/constants/app_constants.dart';
import 'package:app_block/core/router/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeCubit = getIt<ThemeCubit>();
    final localeCubit = getIt<LocaleCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'المظهر واللغة'),
          const SizedBox(height: 8),

          // Theme Setting
          BlocBuilder<ThemeCubit, ThemeState>(
            bloc: themeCubit,
            builder: (context, state) {
              final isDarkMode = state is ThemeLoaded
                  ? state.isDarkMode
                  : false;
              return _buildSettingCard(
                context,
                title: 'الوضع الليلي',
                subtitle: isDarkMode ? 'مفعّل' : 'معطّل',
                icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) => themeCubit.setDarkMode(value),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Language Setting
          BlocBuilder<LocaleCubit, LocaleState>(
            bloc: localeCubit,
            builder: (context, state) {
              final isArabic = state is LocaleLoaded ? state.isArabic : true;
              return _buildSettingCard(
                context,
                title: 'اللغة',
                subtitle: isArabic ? 'العربية' : 'English',
                icon: Icons.language,
                onTap: () =>
                    _showLanguageDialog(context, localeCubit, isArabic),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'إعدادات الحظر'),
          const SizedBox(height: 8),

          // Block Screen Style
          _buildSettingCard(
            context,
            title: 'شاشة الحظر',
            subtitle: 'تغيير شكل الشاشة التي تظهر عند محاولة فتح تطبيق محظور',
            icon: Icons.app_blocking_outlined,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.blockScreenStyle),
          ),

          const SizedBox(height: 12),

          // Quick Block Settings
          _buildSettingCard(
            context,
            title: 'ضبط الحظر السريع',
            subtitle: 'تخصيص خيارات الحظر السريع والمؤقت',
            icon: Icons.bolt_outlined,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.quickBlockSettings),
          ),

          const SizedBox(height: 12),

          // Unlock Challenge Setting
          FutureBuilder<String>(
            future: getIt<SettingsRepository>().getUnlockChallengeType(),
            builder: (context, snapshot) {
              final challengeType = snapshot.data ?? AppConstants.challengeMath;
              return _buildSettingCard(
                context,
                title: 'تحدي فك الحظر',
                subtitle: _getChallengeSubtitle(challengeType),
                icon: Icons.psychology_outlined,
                onTap: () => _showChallengeTypeDialog(context, challengeType),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'النظام والمساعدة'),
          const SizedBox(height: 8),

          // Permissions
          _buildSettingCard(
            context,
            title: 'الأذونات',
            subtitle: 'التحقق من حالة أذونات النظام المطلوبة',
            icon: Icons.security_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.permissions),
          ),

          const SizedBox(height: 12),

          // About
          _buildSettingCard(
            context,
            title: 'عن التطبيق',
            subtitle: 'الإصدار 1.0.0',
            icon: Icons.info_outline,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'App Blocker',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(),
                children: [
                  const Text(
                    'تطبيق يساعدك على التركيز والتقليل من تشتت انتباهك من خلال حظر التطبيقات والمواقع المستنزفة للوقت.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleCubit localeCubit,
    bool isArabic,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('العربية'),
              value: true,
              groupValue: isArabic,
              onChanged: (value) {
                localeCubit.changeLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: const Text('English'),
              value: false,
              groupValue: isArabic,
              onChanged: (value) {
                localeCubit.changeLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getChallengeSubtitle(String type) {
    switch (type) {
      case AppConstants.challengeNone:
        return 'بدون تحدي (مباشر)';
      case AppConstants.challengeMath:
        return 'مسألة رياضية';
      case AppConstants.challengeQuote:
        return 'كتابة حكمة';
      case AppConstants.challengeTimer:
        return 'عداد تنازلي';
      default:
        return 'مسألة رياضية';
    }
  }

  void _showChallengeTypeDialog(BuildContext context, String currentType) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اختر نوع التحدي'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChallengeOption(
              dialogContext,
              'بدون تحدي',
              AppConstants.challengeNone,
              currentType,
            ),
            _buildChallengeOption(
              dialogContext,
              'مسألة رياضية',
              AppConstants.challengeMath,
              currentType,
            ),
            _buildChallengeOption(
              dialogContext,
              'كتابة حكمة',
              AppConstants.challengeQuote,
              currentType,
            ),
            _buildChallengeOption(
              dialogContext,
              'عداد تنازلي',
              AppConstants.challengeTimer,
              currentType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeOption(
    BuildContext dialogContext,
    String title,
    String value,
    String currentType,
  ) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: currentType,
      onChanged: (newValue) async {
        if (newValue != null) {
          await getIt<SettingsRepository>().setUnlockChallengeType(newValue);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            // Refresh the screen
            setState(() {});
          }
        }
      },
    );
  }
}
