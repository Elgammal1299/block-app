import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/DI/setup_get_it.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/custom_focus_mode.dart';
import '../../../data/models/blocked_app.dart';
import '../../view_model/custom_focus_mode_cubit/custom_focus_mode_cubit.dart';
import '../../view_model/custom_focus_mode_cubit/custom_focus_mode_state.dart';

class CreateCustomModeScreen extends StatefulWidget {
  final CustomFocusMode? existingMode;

  const CreateCustomModeScreen({super.key, this.existingMode});

  @override
  State<CreateCustomModeScreen> createState() => _CreateCustomModeScreenState();
}

class _CreateCustomModeScreenState extends State<CreateCustomModeScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _durationMinutes = 25;
  Set<int> _selectedDays = {1, 2, 3, 4, 5};
  List<String> _selectedPackages = [];
  bool _isEnabled = true;

  bool get _isEditing => widget.existingMode != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.existingMode!;
      _nameController.text = m.name;
      _durationMinutes = m.durationMinutes ?? 25;
      _selectedDays = m.daysOfWeek?.toSet() ?? {1, 2, 3, 4, 5};
      _selectedPackages = List.from(m.blockedPackages);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---- Save ----
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<CustomFocusModeCubit>();
    final mode = CustomFocusMode(
      id: widget.existingMode?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      icon: Icons.flash_on_rounded,
      blockType: CustomModeBlockType.fullBlock,
      blockedPackages: _selectedPackages,
      durationMinutes: _durationMinutes,
      daysOfWeek: _selectedDays.toList()..sort(),
      createdAt: widget.existingMode?.createdAt ?? DateTime.now(),
      lastUsedAt: widget.existingMode?.lastUsedAt,
    );

    if (_isEditing) {
      await cubit.updateCustomMode(mode);
    } else {
      await cubit.createCustomMode(mode);
    }

    if (mounted) Navigator.of(context).pop();
  }

  // ---- Day helpers ----
  static const _dayShort = {
    1: 'إث',
    2: 'ثل',
    3: 'أر',
    4: 'خم',
    5: 'جم',
    6: 'سب',
    7: 'أح',
  };

  String _durationLabel() {
    if (_durationMinutes < 60) return '$_durationMinutes دقيقة';
    final h = _durationMinutes ~/ 60;
    final m = _durationMinutes % 60;
    if (m == 0) return '$h ساعة';
    return '$h س $m د';
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocListener<CustomFocusModeCubit, CustomFocusModeState>(
      bloc: getIt<CustomFocusModeCubit>(),
      listener: (ctx, state) {
        if (state is CustomFocusModeError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.accentError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header ───
              _buildHeader(theme, primary),

              // ─── Content ───
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Name
                        _buildSection(
                          theme,
                          icon: Icons.badge_outlined,
                          title: 'اسم الوضع',
                          child: _buildNameField(theme, primary),
                        ),
                        const SizedBox(height: 20),

                        // 2. Duration
                        _buildSection(
                          theme,
                          icon: Icons.timer_outlined,
                          title: 'المدة',
                          trailing: _buildDurationBadge(theme, primary),
                          child: _buildDurationSlider(theme, primary),
                        ),
                        const SizedBox(height: 20),

                        // 3. Days
                        _buildSection(
                          theme,
                          icon: Icons.calendar_month_outlined,
                          title: 'الأيام',
                          child: _buildDaysPicker(theme, primary),
                        ),
                        const SizedBox(height: 20),

                        // 4. Apps
                        _buildSection(
                          theme,
                          icon: Icons.apps_rounded,
                          title: 'التطبيقات المحظورة',
                          child: _buildAppsSelector(theme, primary),
                        ),
                        const SizedBox(height: 20),

                        // 5. Enable toggle
                        _buildSection(
                          theme,
                          icon: Icons.toggle_on_outlined,
                          title: 'الحالة',
                          child: _buildEnableToggle(theme, primary),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Save Button ───
              _buildSaveButton(theme, primary),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════ WIDGETS ══════════════════════════════

  Widget _buildHeader(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'تعديل الوضع' : 'وضع تركيز جديد',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditing
                      ? 'عدّل إعدادات وضع التركيز'
                      : 'أنشئ وضع تركيز مخصصاً',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Mode icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildNameField(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: _nameController,
        textAlign: TextAlign.right,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'مثال: دراسة المساء، عمل الصباح ...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.edit_rounded, color: primary, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'من فضلك أدخل اسماً للوضع';
          if (v.trim().length < 2) return 'الاسم قصير جداً';
          return null;
        },
      ),
    );
  }

  Widget _buildDurationBadge(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _durationLabel(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDurationSlider(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primary,
              thumbColor: primary,
              inactiveTrackColor: primary.withValues(alpha: 0.15),
              overlayColor: primary.withValues(alpha: 0.1),
              trackHeight: 5,
            ),
            child: Slider(
              value: _durationMinutes.toDouble(),
              min: 5,
              max: 480,
              divisions: 95,
              onChanged: (v) => setState(() => _durationMinutes = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 د',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '8 س',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          // Preset chips
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                    ('15 د', 15),
                    ('25 د', 25),
                    ('45 د', 45),
                    ('1 س', 60),
                    ('2 س', 120),
                    ('4 س', 240),
                  ].map((p) {
                    final isSelected = _durationMinutes == p.$2;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(p.$1),
                        selected: isSelected,
                        selectedColor: primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? primary : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? primary
                              : Colors.transparent,
                        ),
                        onSelected: (_) =>
                            setState(() => _durationMinutes = p.$2),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysPicker(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            selected ? primary : primary.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? primary
                              : primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayShort[day]!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          const SizedBox(height: 14),
          // Preset buttons
          Wrap(
            spacing: 8,
            children: [
              _presetBtn('أيام العمل', {1, 2, 3, 4, 5}, primary, theme),
              _presetBtn('عطلة', {6, 7}, primary, theme),
              _presetBtn('كل يوم', {1, 2, 3, 4, 5, 6, 7}, primary, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetBtn(
    String label,
    Set<int> days,
    Color primary,
    ThemeData theme,
  ) {
    final isActive = _selectedDays.containsAll(days) &&
        _selectedDays.length == days.length;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedDays = Set.from(days)),
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? primary.withValues(alpha: 0.1) : null,
        side: BorderSide(
          color: isActive ? primary : theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? primary : theme.colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAppsSelector(ThemeData theme, Color primary) {
    return InkWell(
      onTap: () async {
        // Navigate to existing FocusModeAppSelectionScreen passing packages info
        final result = await Navigator.of(context).pushNamed(
          AppRoutes.appSelection,
        );
        // If user selected apps (returned from selection), update list
        // For now just reload from cubit if any blocked apps were selected
        // We handle this with a simple approach – read selected packages
        if (result != null && result is List<BlockedApp>) {
          setState(() {
            _selectedPackages = result.map((a) => a.packageName).toList();
          });
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.apps_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPackages.isEmpty
                        ? 'اختر التطبيقات المحظورة'
                        : '${_selectedPackages.length} تطبيق محدد',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedPackages.isEmpty
                        ? 'اضغط لإضافة التطبيقات التي تريد حظرها'
                        : 'اضغط للتعديل',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _isEnabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
            color: _isEnabled ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفعيل الوضع فور إنشائه',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEnabled
                      ? 'سيكون الوضع نشطاً مباشرة'
                      : 'يمكنك تفعيله لاحقاً',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            activeThumbColor: primary,
            onChanged: (v) => setState(() => _isEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme, Color primary) {
    return BlocBuilder<CustomFocusModeCubit, CustomFocusModeState>(
      bloc: getIt<CustomFocusModeCubit>(),
      builder: (ctx, state) {
        final isLoading = state is CustomFocusModeLoading;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primary.withValues(alpha: 0.4),
                elevation: isLoading ? 0 : 3,
                shadowColor: primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_circle_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isEditing ? 'حفظ التغييرات' : 'إنشاء الوضع',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
