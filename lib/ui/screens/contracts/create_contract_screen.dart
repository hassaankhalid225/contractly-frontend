import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../util/extensions/string_extensions.dart';
import '../../../util/helpers/validator_helper.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';
import '../../components/secondary_button.dart';

class CreateContractScreen extends ConsumerStatefulWidget {
  const CreateContractScreen({super.key});

  @override
  ConsumerState<CreateContractScreen> createState() =>
      _CreateContractScreenState();
}

class _CreateContractScreenState extends ConsumerState<CreateContractScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Shared fields
  final _titleC = TextEditingController();
  final _clientNameC = TextEditingController();
  final _clientEmailC = TextEditingController();
  final _descriptionC = TextEditingController();
  final _valueC = TextEditingController();
  final _durationC = TextEditingController(text: '30');

  String _currency = 'USD';
  String _workType = WorkType.webDev;
  DateTime? _startDate;
  DateTime? _endDate;

  // AI mode
  String? _generatedMarkdown;

  bool get _isAiMode => _tab.index == 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleC.dispose();
    _clientNameC.dispose();
    _clientEmailC.dispose();
    _descriptionC.dispose();
    _valueC.dispose();
    _durationC.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandAccent,
            onPrimary: Colors.white,
            surface: AppColors.brandSurface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.brandPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String? _validate() {
    final fields = <String, String>{
      'Title': _titleC.text,
      'Client Name': _clientNameC.text,
    };
    for (final entry in fields.entries) {
      final err = ValidatorHelper.required(entry.value, label: entry.key);
      if (err != null) return err;
    }
    if (_clientEmailC.text.trim().isNotEmpty) {
      final err = ValidatorHelper.email(_clientEmailC.text);
      if (err != null) return err;
    }
    final v = ValidatorHelper.positiveNumber(_valueC.text, label: 'Value');
    if (v != null) return v;
    if (_isAiMode) {
      if (_descriptionC.text.trim().length < 10) {
        return 'Add a project description of at least 10 characters.';
      }
      final dur = int.tryParse(_durationC.text);
      if (dur == null || dur <= 0) {
        return 'Enter a valid duration in days.';
      }
    } else {
      if (_startDate == null || _endDate == null) {
        return 'Pick start and end dates.';
      }
      if (!_endDate!.isAfter(_startDate!)) {
        return 'End date must be after start date.';
      }
    }
    return null;
  }

  Future<void> _generateAi() async {
    final err = _validate();
    if (err != null) {
      AppSnackbar.error(context, err);
      return;
    }
    final result = await ref.read(contractProvider.notifier).generateAiContract({
      'title': _titleC.text.trim(),
      'client_name': _clientNameC.text.trim(),
      'client_email': _clientEmailC.text.trim().isEmpty
          ? null
          : _clientEmailC.text.trim(),
      'description': _descriptionC.text.trim(),
      'value': double.tryParse(_valueC.text) ?? 0,
      'currency': _currency,
      'duration_days': int.tryParse(_durationC.text) ?? 30,
      'work_type': _workType,
      'start_date': _startDate?.toUtc().toIso8601String(),
    });
    if (!mounted) return;
    if (result == null) {
      final e = ref.read(contractProvider).error;
      AppSnackbar.error(context,
          e?.friendlyMessage ?? 'Could not generate contract. Please retry.');
      return;
    }
    setState(() => _generatedMarkdown = result);
    AppSnackbar.info(context, 'Contract drafted.');
  }

  Future<void> _save({required String status}) async {
    final err = _validate();
    if (err != null) {
      AppSnackbar.error(context, err);
      return;
    }

    DateTime start;
    DateTime end;
    String description;

    if (_isAiMode) {
      start = _startDate ?? DateTime.now();
      final dur = int.tryParse(_durationC.text) ?? 30;
      end = start.add(Duration(days: dur));
      description = _generatedMarkdown ?? _descriptionC.text;
    } else {
      start = _startDate!;
      end = _endDate!;
      description = _descriptionC.text;
    }

    final created = await ref.read(contractProvider.notifier).createContract({
      'title': _titleC.text.trim(),
      'client_name': _clientNameC.text.trim(),
      'client_email': _clientEmailC.text.trim().isEmpty
          ? null
          : _clientEmailC.text.trim(),
      'description': description,
      'value': double.tryParse(_valueC.text) ?? 0,
      'currency': _currency,
      'start_date': start.toUtc().toIso8601String(),
      'end_date': end.toUtc().toIso8601String(),
      'status': status,
      'work_type': _workType,
    });
    if (!mounted) return;
    if (created == null) {
      final e = ref.read(contractProvider).error;
      AppSnackbar.error(context,
          e?.friendlyMessage ?? 'Could not save the contract.');
      return;
    }
    AppSnackbar.info(context, 'Contract saved.');
    context.go('/contracts/${created.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(contractProvider).isLoading;
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(
                title: 'New Contract',
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/contracts'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: AppColors.brandAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle:
                        AppTextStyles.button.copyWith(fontSize: 14),
                    unselectedLabelStyle:
                        AppTextStyles.button.copyWith(fontSize: 14),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'AI Generate'),
                      Tab(text: 'Manual'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    140,
                  ),
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          _Field(
                            controller: _titleC,
                            label: 'Contract Title',
                            hint: 'e.g. Landing Page Redesign',
                          ),
                          const Gap(AppSpacing.md),
                          _Field(
                            controller: _clientNameC,
                            label: 'Client Name',
                            hint: 'Acme Inc.',
                          ),
                          const Gap(AppSpacing.md),
                          _Field(
                            controller: _clientEmailC,
                            label: 'Client Email (optional)',
                            hint: 'client@company.com',
                            keyboard: TextInputType.emailAddress,
                          ),
                          const Gap(AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _DropdownField<String>(
                                  label: 'Work Type',
                                  value: _workType,
                                  items: WorkType.labels.entries
                                      .map((e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _workType = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _Field(
                                  controller: _valueC,
                                  label: 'Contract Value',
                                  hint: '5000',
                                  keyboard: TextInputType.number,
                                ),
                              ),
                              const Gap(AppSpacing.md),
                              Expanded(
                                child: _DropdownField<String>(
                                  label: 'Currency',
                                  value: _currency,
                                  items: AppConstants.supportedCurrencies
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _currency = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.md),
                          if (_isAiMode) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _DateField(
                                    label: 'Start Date (optional)',
                                    value: _startDate == null
                                        ? null
                                        : dateFmt.format(_startDate!),
                                    onTap: () =>
                                        _pickDate(isStart: true),
                                  ),
                                ),
                                const Gap(AppSpacing.md),
                                Expanded(
                                  child: _Field(
                                    controller: _durationC,
                                    label: 'Duration (days)',
                                    hint: '30',
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.md),
                            _Field(
                              controller: _descriptionC,
                              label: 'Project Description',
                              hint:
                                  'Describe the deliverables, milestones, and any constraints…',
                              maxLines: 6,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _DateField(
                                    label: 'Start Date',
                                    value: _startDate == null
                                        ? null
                                        : dateFmt.format(_startDate!),
                                    onTap: () =>
                                        _pickDate(isStart: true),
                                  ),
                                ),
                                const Gap(AppSpacing.md),
                                Expanded(
                                  child: _DateField(
                                    label: 'End Date',
                                    value: _endDate == null
                                        ? null
                                        : dateFmt.format(_endDate!),
                                    onTap: () =>
                                        _pickDate(isStart: false),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.md),
                            _Field(
                              controller: _descriptionC,
                              label: 'Full Contract Text',
                              hint:
                                  'Paste or type the complete contract content here…',
                              maxLines: 12,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isAiMode) ...[
                      const Gap(AppSpacing.lg),
                      PrimaryButton(
                        label: _generatedMarkdown == null
                            ? 'Generate with AI'
                            : 'Regenerate',
                        icon: Icons.auto_awesome,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _generateAi,
                      ),
                      if (_generatedMarkdown != null) ...[
                        const Gap(AppSpacing.lg),
                        Text('AI Draft', style: AppTextStyles.title),
                        const Gap(AppSpacing.sm),
                        GlassCard(
                          child: TextField(
                            controller: TextEditingController(
                              text: _generatedMarkdown,
                            )..selection = TextSelection.collapsed(
                                offset: _generatedMarkdown!.length,
                              ),
                            onChanged: (v) => _generatedMarkdown = v,
                            maxLines: null,
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const Gap(AppSpacing.huge),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Save Draft',
                          icon: Icons.save_rounded,
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () =>
                                  _save(status: ContractStatus.draft),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save & Sign',
                          icon: Icons.check_rounded,
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () =>
                                  _save(status: ContractStatus.active),
                        ),
                      ),
                    ],
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

class _AppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _AppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary),
          ),
          const Gap(AppSpacing.xs),
          Text(title, style: AppTextStyles.heading),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const Gap(AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          minLines: 1,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySecondary,
            filled: true,
            fillColor: AppColors.brandPrimary.withValues(alpha: 0.45),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.brandAccent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const Gap(AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            isExpanded: true,
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            iconEnabledColor: AppColors.textSecondary,
            dropdownColor: AppColors.brandSurface,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const Gap(AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.textSecondary),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    value.orDefault('Pick a date'),
                    style: AppTextStyles.body.copyWith(
                      color: value == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
