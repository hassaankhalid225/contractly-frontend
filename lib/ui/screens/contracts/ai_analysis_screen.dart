import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/loading_overlay.dart';
import '../../components/primary_button.dart';
import '../../components/status_badge.dart';

class AiAnalysisScreen extends ConsumerStatefulWidget {
  final String contractId;
  final Map<String, dynamic>? existingAnalysisJson;

  const AiAnalysisScreen({
    super.key,
    required this.contractId,
    this.existingAnalysisJson,
  });

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  ContractAnalysis? _analysis;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAnalysisJson != null) {
      _analysis = ContractAnalysis.fromJson(widget.existingAnalysisJson!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
    }
  }

  Future<void> _runAnalysis() async {
    final contract = await ref
        .read(contractProvider.notifier)
        .fetchById(widget.contractId);
    if (!mounted || contract == null) return;
    setState(() => _loading = true);
    final result = await ref.read(contractProvider.notifier).analyzeContract(
          contractText: contract.description,
          pdfUrl: contract.pdfUrl,
        );
    if (!mounted) return;
    setState(() {
      _analysis = result;
      _loading = false;
    });
    if (result == null) {
      AppSnackbar.error(context,
          ref.read(contractProvider).error?.friendlyMessage ?? 'Analysis failed.');
    }
  }

  Future<void> _save() async {
    if (_analysis == null) return;
    setState(() => _saving = true);
    final notifier = ref.read(contractProvider.notifier);
    final analysisJson = {
      'risk_level': _analysis!.riskLevel,
      'summary': _analysis!.summary,
      'risky_clauses': _analysis!.riskyClauses
          .map((c) => {
                'clause': c.clause,
                'risk': c.risk,
                'severity': c.severity,
              })
          .toList(),
      'missing_sections': _analysis!.missingSections,
      'recommendations': _analysis!.recommendations,
      'freelancer_protection_score': _analysis!.freelancerProtectionScore,
      'analyzed_at': DateTime.now().toUtc().toIso8601String(),
    };
    await notifier.updateContract(widget.contractId, {
      'ai_analysis': analysisJson,
      'notes':
          'AI Risk: ${_analysis!.riskLevel.toUpperCase()} • Protection score ${_analysis!.freelancerProtectionScore}/10',
    });
    if (mounted) {
      setState(() => _saving = false);
      AppSnackbar.info(context, 'Analysis saved.');
      context.go('/contracts/${widget.contractId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/contracts/${widget.contractId}'),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const Gap(AppSpacing.xs),
                    Text('AI Analysis', style: AppTextStyles.heading),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const LoadingOverlay()
                    : analysis == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Text(
                                'No analysis available yet.',
                                style: AppTextStyles.bodySecondary,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        StatusBadge.risk(analysis.riskLevel),
                                        const Spacer(),
                                        Text(
                                          'Score ${analysis.freelancerProtectionScore}/10',
                                          style: AppTextStyles.subtitle.copyWith(
                                            color: AppColors.brandGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(AppSpacing.md),
                                    Text('Summary',
                                        style: AppTextStyles.label),
                                    const Gap(AppSpacing.xs),
                                    Text(
                                      analysis.summary,
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                ),
                              ),
                              if (analysis.riskyClauses.isNotEmpty) ...[
                                const Gap(AppSpacing.lg),
                                Text('Risky Clauses', style: AppTextStyles.title),
                                const Gap(AppSpacing.sm),
                                for (final c in analysis.riskyClauses) ...[
                                  GlassCard(
                                    overrideColor: AppColors.danger,
                                    opacity: 0.18,
                                    borderColor:
                                        AppColors.danger.withValues(alpha: 0.5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            const Gap(AppSpacing.sm),
                                            StatusBadge.risk(c.severity),
                                          ],
                                        ),
                                        const Gap(AppSpacing.sm),
                                        Text(
                                          c.clause,
                                          style: AppTextStyles.subtitle.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const Gap(AppSpacing.sm),
                                        Text(c.risk, style: AppTextStyles.body),
                                      ],
                                    ),
                                  ),
                                  const Gap(AppSpacing.md),
                                ],
                              ],
                              if (analysis.missingSections.isNotEmpty) ...[
                                const Gap(AppSpacing.lg),
                                Text('Missing Sections',
                                    style: AppTextStyles.title),
                                const Gap(AppSpacing.sm),
                                GlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final s in analysis.missingSections)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.cancel_outlined,
                                                color: AppColors.warning,
                                                size: 16,
                                              ),
                                              const Gap(AppSpacing.sm),
                                              Expanded(
                                                  child: Text(s,
                                                      style:
                                                          AppTextStyles.body)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              const Gap(AppSpacing.lg),
                              Text('Recommendations', style: AppTextStyles.title),
                              const Gap(AppSpacing.sm),
                              GlassCard(
                                overrideColor: AppColors.success,
                                opacity: 0.16,
                                borderColor:
                                    AppColors.success.withValues(alpha: 0.4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final r in analysis.recommendations)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 5),
                                              child: Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            const Gap(AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                r,
                                                style: AppTextStyles.body,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Gap(AppSpacing.huge),
                            ],
                          ),
              ),
              if (analysis != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: PrimaryButton(
                      label: 'Save Analysis',
                      icon: Icons.save_rounded,
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
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
