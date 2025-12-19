import 'package:flutter/material.dart';
import 'package:block_app/core/DI/setup_get_it.dart';
import 'package:block_app/feature/data/repositories/settings_repository.dart';
import 'package:block_app/core/services/platform_channel_service.dart';

class BlockScreenStyleScreen extends StatefulWidget {
  const BlockScreenStyleScreen({super.key});

  @override
  State<BlockScreenStyleScreen> createState() => _BlockScreenStyleScreenState();
}

class _BlockScreenStyleScreenState extends State<BlockScreenStyleScreen> {
  String _selectedStyle = 'classic';
  bool _isLoading = true;

  final List<_StyleOption> _styles = const [
    _StyleOption(
      id: 'classic',
      title: 'الكلاسيكي',
      description: 'شاشة كاملة مع رسالة تحفيزية وزر محاولة فتح بالتحدي.',
      icon: Icons.view_day_outlined,
    ),
    _StyleOption(
      id: 'minimal',
      title: 'البسيط',
      description: 'رسالة قصيرة وزر الرجوع للرئيسية فقط بدون تشتيت.',
      icon: Icons.crop_square,
    ),
    _StyleOption(
      id: 'hardcore',
      title: 'المتشدد',
      description: 'رسالة قوية بدون زر فتح مؤقت، تركيز كامل أثناء الحظر.',
      icon: Icons.warning_amber_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentStyle();
  }

  Future<void> _loadCurrentStyle() async {
    final settingsRepository = getIt<SettingsRepository>();
    final style = await settingsRepository.getBlockScreenStyle();
    if (mounted) {
      setState(() {
        _selectedStyle = style;
        _isLoading = false;
      });
    }
  }

  Future<void> _onStyleChanged(String styleId) async {
    setState(() {
      _selectedStyle = styleId;
    });

    final settingsRepository = getIt<SettingsRepository>();
    final platformService = getIt<PlatformChannelService>();

    await settingsRepository.setBlockScreenStyle(styleId);
    await platformService.setBlockScreenStyle(styleId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ شكل شاشة الحظر بنجاح'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شكل شاشة الحظر'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _styles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _styles[index];
                final isSelected = option.id == _selectedStyle;

                return InkWell(
                  onTap: () => _onStyleChanged(option.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color:
                          isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Radio<String>(
                          value: option.id,
                          groupValue: _selectedStyle,
                          onChanged: (value) {
                            if (value != null) {
                              _onStyleChanged(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StyleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _StyleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}


