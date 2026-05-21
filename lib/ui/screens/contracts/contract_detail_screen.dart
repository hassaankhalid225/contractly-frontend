import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../util/helpers/currency_helper.dart';
import '../../../util/helpers/date_helper.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/loading_overlay.dart';
import '../../components/primary_button.dart';
import '../../components/secondary_button.dart';
import '../../components/status_badge.dart';

class ContractDetailScreen extends ConsumerStatefulWidget {
  final String contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailScreen> createState() =>
      _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(contractProvider.notifier).fetchById(widget.contractId);
      await ref
          .read(paymentProvider.notifier)
          .loadPayments(contractId: widget.contractId, replaceFilters: true);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(ContractModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brandSurface,
        title: Text('Delete contract?', style: AppTextStyles.title),
        content: Text(
          '"${c.title}" will be permanently removed.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success =
        await ref.read(contractProvider.notifier).deleteContract(c.id);
    if (!mounted) return;
    if (success) {
      AppSnackbar.info(context, 'Contract deleted.');
      context.go('/contracts');
    }
  }

  Future<void> _markCompleted(ContractModel c) async {
    setState(() => _busy = true);
    await ref
        .read(contractProvider.notifier)
        .updateContract(c.id, {'status': ContractStatus.completed});
    if (mounted) {
      setState(() => _busy = false);
      AppSnackbar.info(context, 'Contract marked as completed.');
    }
  }

  Future<void> _addPaymentMilestone(ContractModel c) async {
    final amountC = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(days: 7));
    final notesC = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.brandSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Text('Add Payment Milestone',
                      style: AppTextStyles.title),
                  const Gap(AppSpacing.lg),
                  TextField(
                    controller: amountC,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Due: ${DateHelper.formatFull(selected)}',
                          style: AppTextStyles.body,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selected,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setSheet(() => selected = picked);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.md),
                  TextField(
                    controller: notesC,
                    maxLines: 2,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Gap(AppSpacing.xl),
                  PrimaryButton(
                    label: 'Save Milestone',
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      final amount = double.tryParse(amountC.text);
                      if (amount == null || amount < 0) {
                        AppSnackbar.error(ctx, 'Enter a valid amount.');
                        return;
                      }
                      final created =
                          await ref.read(paymentProvider.notifier).create(
                                contractId: c.id,
                                amount: amount,
                                currency: c.currency,
                                dueDate: selected,
                                notes: notesC.text.trim().isEmpty
                                    ? null
                                    : notesC.text.trim(),
                              );
                      if (created != null && ctx.mounted) {
                        Navigator.pop(ctx, true);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      AppSnackbar.info(context, 'Milestone added.');
      await ref
          .read(paymentProvider.notifier)
          .loadPayments(contractId: widget.contractId, replaceFilters: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contractProvider);
    final contract = state.contracts
        .firstWhereOrNull((c) => c.id == widget.contractId);

    if (contract == null) {
      if (state.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.brandPrimary,
          body: AppBackground(child: Center(child: LoadingOverlay())),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.brandPrimary,
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Contract not found.',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _DetailAppBar(
                contract: contract,
                busy: _busy,
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/contracts'),
                onDelete: () => _confirmDelete(contract),
                onMarkCompleted: () => _markCompleted(contract),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _HeaderCard(contract: contract),
              ),
              const Gap(AppSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tab,
                    isScrollable: false,
                    indicator: BoxDecoration(
                      color: AppColors.brandAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle:
                        AppTextStyles.button.copyWith(fontSize: 12),
                    unselectedLabelStyle:
                        AppTextStyles.button.copyWith(fontSize: 12),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Payments'),
                      Tab(text: 'Analysis'),
                      Tab(text: 'Documents'),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OverviewTab(contract: contract),
                    _PaymentsTab(
                      contract: contract,
                      onAdd: () => _addPaymentMilestone(contract),
                    ),
                    _AnalysisTab(contract: contract),
                    _DocumentsTab(contract: contract),
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
                  child: contract.isSigned
                      ? _SignedFooter(contract: contract)
                      : PrimaryButton(
                          label: 'Sign Contract',
                          icon: Icons.draw_rounded,
                          onPressed: () => context
                              .push('/contracts/${contract.id}/sign'),
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

class _DetailAppBar extends StatelessWidget {
  final ContractModel contract;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final VoidCallback onMarkCompleted;

  const _DetailAppBar({
    required this.contract,
    required this.busy,
    required this.onBack,
    required this.onDelete,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (contract.status != ContractStatus.completed)
            IconButton(
              onPressed: busy ? null : onMarkCompleted,
              icon: const Icon(Icons.task_alt, color: AppColors.success),
              tooltip: 'Mark completed',
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ContractModel contract;
  const _HeaderCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final progress = contract.progress;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contract.title, style: AppTextStyles.heading),
          const Gap(AppSpacing.xs),
          Text(
            contract.clientName,
            style: AppTextStyles.bodySecondary,
          ),
          if (contract.clientEmail != null)
            Text(
              contract.clientEmail!,
              style: AppTextStyles.caption,
            ),
          const Gap(AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CurrencyHelper.format(contract.value, contract.currency),
                style: AppTextStyles.money.copyWith(fontSize: 22),
              ),
              const Spacer(),
              StatusBadge.contract(contract.status),
            ],
          ),
          if (contract.startDate != null && contract.endDate != null) ...[
            const Gap(AppSpacing.lg),
            Row(
              children: [
                Text(
                  DateHelper.formatShort(contract.startDate!),
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                Text(
                  DateHelper.formatShort(contract.endDate!),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const Gap(AppSpacing.xs),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 8,
              percent: progress ?? 0,
              backgroundColor:
                  AppColors.textSecondary.withValues(alpha: 0.18),
              progressColor: AppColors.brandAccent,
              barRadius: const Radius.circular(8),
            ),
            const Gap(AppSpacing.xs),
            Text(
              contract.endDate != null
                  ? DateHelper.daysRemainingLabel(contract.endDate!)
                  : '',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ContractModel contract;
  const _OverviewTab({required this.contract});

  @override
  Widget build(BuildContext context) {
    final body = contract.description?.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        if (contract.workType != null) ...[
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.work_outline,
                    color: AppColors.brandAccent),
                const Gap(AppSpacing.sm),
                Text('Type', style: AppTextStyles.label),
                const Spacer(),
                Text(WorkType.label(contract.workType),
                    style: AppTextStyles.subtitle),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
        ],
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contract Body', style: AppTextStyles.label),
              const Gap(AppSpacing.sm),
              if (body == null || body.isEmpty)
                Text(
                  'No contract text provided.',
                  style: AppTextStyles.bodySecondary,
                )
              else
                MarkdownBody(
                  data: body,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTextStyles.body,
                    h1: AppTextStyles.heading,
                    h2: AppTextStyles.title,
                    h3: AppTextStyles.subtitle,
                    listBullet: AppTextStyles.body,
                  ),
                ),
            ],
          ),
        ),
        if (contract.notes != null && contract.notes!.isNotEmpty) ...[
          const Gap(AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes', style: AppTextStyles.label),
                const Gap(AppSpacing.xs),
                Text(contract.notes!, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  final ContractModel contract;
  final VoidCallback onAdd;
  const _PaymentsTab({required this.contract, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentProvider);
    final payments =
        state.payments.where((p) => p.contractId == contract.id).toList();
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SecondaryButton(
            label: 'Add Milestone',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ),
        const Gap(AppSpacing.md),
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No milestones yet. Add your first milestone above.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const Gap(AppSpacing.md),
                  itemBuilder: (_, i) {
                    final p = payments[i];
                    return GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyHelper.format(
                                    p.amount,
                                    p.currency,
                                  ),
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.brandGold,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  'Due ${DateHelper.formatFull(p.dueDate)}',
                                  style: AppTextStyles.caption,
                                ),
                                if (p.notes != null && p.notes!.isNotEmpty) ...[
                                  const Gap(4),
                                  Text(
                                    p.notes!,
                                    style: AppTextStyles.bodySecondary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge.payment(p.status),
                              const Gap(AppSpacing.sm),
                              if (p.status != PaymentStatus.paid)
                                TextButton(
                                  onPressed: () => ref
                                      .read(paymentProvider.notifier)
                                      .markPaid(p.id),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                  ),
                                  child: const Text('Mark paid'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final ContractModel contract;
  const _AnalysisTab({required this.contract});

  @override
  Widget build(BuildContext context) {
    final analysisJson = contract.aiAnalysis;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        if (analysisJson == null) ...[
          Text(
            'No AI analysis available yet.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.lg),
          PrimaryButton(
            label: 'Analyze this contract',
            icon: Icons.auto_awesome,
            onPressed: () =>
                context.push('/contracts/${contract.id}/analysis'),
          ),
        ] else ...[
          Text(
            'Risk: ${(analysisJson['risk_level'] ?? 'low').toString().toUpperCase()}',
            style: AppTextStyles.title,
          ),
          const Gap(AppSpacing.sm),
          Text(
            (analysisJson['summary'] ?? '').toString(),
            style: AppTextStyles.body,
          ),
        ],
      ],
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  final ContractModel contract;
  const _DocumentsTab({required this.contract});

  Future<void> _open(BuildContext context, String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.error(context, 'Could not open the file.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf,
                  color: AppColors.brandAccent),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  contract.pdfUrl == null ? 'No PDF attached' : 'Contract PDF',
                  style: AppTextStyles.subtitle,
                ),
              ),
              if (contract.pdfUrl != null)
                IconButton(
                  onPressed: () => _open(context, contract.pdfUrl!),
                  icon: const Icon(Icons.open_in_new,
                      color: AppColors.brandAccent),
                ),
            ],
          ),
        ),
        if (contract.signatureUrl != null) ...[
          const Gap(AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature', style: AppTextStyles.label),
                const Gap(AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    height: 120,
                    child: CachedNetworkImage(
                      imageUrl: contract.signatureUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          'Could not load signature.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (contract.signedAt != null) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    'Signed ${DateHelper.formatFull(contract.signedAt!)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
        const Gap(AppSpacing.md),
        if (contract.pdfUrl != null)
          PrimaryButton(
            label: 'Analyze with AI',
            icon: Icons.auto_awesome,
            onPressed: () =>
                context.push('/contracts/${contract.id}/analysis'),
          ),
      ],
    );
  }
}

class _SignedFooter extends StatelessWidget {
  final ContractModel contract;
  const _SignedFooter({required this.contract});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      overrideColor: AppColors.success,
      opacity: 0.18,
      borderColor: AppColors.success.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              contract.signedAt == null
                  ? 'Signed ✓'
                  : 'Signed on ${DateHelper.formatFull(contract.signedAt!)}',
              style: AppTextStyles.subtitle.copyWith(color: Colors.white),
            ),
          ),
          if (contract.signatureUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.white,
                width: 56,
                height: 36,
                child: CachedNetworkImage(
                  imageUrl: contract.signatureUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
