import 'package:flutter/material.dart';
import 'package:app_block/core/DI/setup_get_it.dart';
import 'package:app_block/feature/data/repositories/settings_repository.dart';
import 'package:app_block/feature/data/models/block_screen_theme.dart';
import 'package:uuid/uuid.dart';

class BlockScreenStyleScreen extends StatefulWidget {
  const BlockScreenStyleScreen({super.key});

  @override
  State<BlockScreenStyleScreen> createState() => _BlockScreenStyleScreenState();
}

class _BlockScreenStyleScreenState extends State<BlockScreenStyleScreen> {
  List<BlockScreenTheme> _themes = [];
  String _selectedId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repository = getIt<SettingsRepository>();
    final themes = await repository.getBlockScreenThemes();
    final currentColor = await repository.getBlockScreenColor();
    final currentQuote = await repository.getBlockScreenQuote();

    if (themes.isEmpty) {
      // Add default themes if none exist
      final defaults = [
        BlockScreenTheme(
          id: '1',
          color: '#0F172A',
          quote: 'توقف عن تشتيت نفسك، ركز على هدفك!',
        ),
        BlockScreenTheme(
          id: '2',
          color: '#0F2A1D',
          quote: 'كل ثانية تقضيها هنا هي ثانية تضيع من مستقبلك.',
        ),
        BlockScreenTheme(
          id: '3',
          color: '#020617',
          quote: 'النجاح يتطلب الانضباط، وليس الراحة.',
        ),
        BlockScreenTheme(
          id: '4',
          color: '#111827',
          quote: 'هل هذا التطبيق أهم من أحلامك؟',
        ),
        BlockScreenTheme(
          id: '5',
          color: '#1C1917',
          quote: 'ركز.. أنت أقوى من هذا التشتت.',
        ),
        BlockScreenTheme(
          id: '6',
          color: '#000000',
          quote: 'لا تستسلم للمغريات، استمر في العمل.',
        ),
      ];
      await repository.saveBlockScreenThemes(defaults);
      _themes = defaults;
    } else {
      _themes = themes;
    }

    // Try to find selected theme by current color/quote
    try {
      final selected = _themes.firstWhere(
        (t) => t.color == currentColor && t.quote == currentQuote,
        orElse: () => _themes.first,
      );
      _selectedId = selected.id;
    } catch (e) {
      _selectedId = _themes.isNotEmpty ? _themes.first.id : '';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onThemeSelected(BlockScreenTheme theme) async {
    setState(() {
      _selectedId = theme.id;
    });
    final repository = getIt<SettingsRepository>();
    await repository.setBlockScreenColor(theme.color);
    await repository.setBlockScreenQuote(theme.quote);
  }

  Future<void> _addNewTheme() async {
    String newColor = '#050A1A';
    String newQuote = '';

    final result = await showDialog<BlockScreenTheme>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة طابع جديد'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color selection in dialog
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            '#0F172A',
                            '#0F2A1D',
                            '#020617',
                            '#111827',
                            '#1C1917',
                            '#000000',
                            '#1A0505',
                          ].map((c) {
                            final isSelected = newColor == c;
                            return GestureDetector(
                              onTap: () => setDialogState(() => newColor = c),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(c.replaceFirst('#', '0xFF')),
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'الحكمة أو الرسالة',
                        hintText: 'اكتب رسالتك التحفيزية هنا...',
                      ),
                      onChanged: (v) => newQuote = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (newQuote.trim().isEmpty) return;
                    Navigator.pop(
                      context,
                      BlockScreenTheme(
                        id: const Uuid().v4(),
                        color: newColor,
                        quote: newQuote,
                      ),
                    );
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final repository = getIt<SettingsRepository>();
      final updatedThemes = [..._themes, result];
      await repository.saveBlockScreenThemes(updatedThemes);
      setState(() {
        _themes = updatedThemes;
        _onThemeSelected(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تخصيص شاشة الحظر'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewTheme),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildLivePreview(),
                const Divider(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _themes.length,
                    itemBuilder: (context, index) {
                      final theme = _themes[index];
                      final isSelected = _selectedId == theme.id;
                      final bgColor = Color(
                        int.parse(theme.color.replaceFirst('#', '0xFF')),
                      );

                      return GestureDetector(
                        onTap: () => _onThemeSelected(theme),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    theme.quote,
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          ThemeData.estimateBrightnessForColor(
                                                bgColor,
                                              ) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLivePreview() {
    if (_themes.isEmpty) return const SizedBox.shrink();

    final selectedTheme = _themes.firstWhere(
      (t) => t.id == _selectedId,
      orElse: () => _themes.first,
    );
    final bgColor = Color(
      int.parse(selectedTheme.color.replaceFirst('#', '0xFF')),
    );
    final isDark =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.8)
        : Colors.black.withOpacity(0.8);

    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.app_blocking, color: textColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  'التطبيق محظور',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    selectedTheme.quote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 24,
            right: 24,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'الرجوع للرئيسية',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
