import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../core/services/file_service.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';

class UploadContractScreen extends ConsumerStatefulWidget {
  const UploadContractScreen({super.key});

  @override
  ConsumerState<UploadContractScreen> createState() =>
      _UploadContractScreenState();
}

class _UploadContractScreenState extends ConsumerState<UploadContractScreen> {
  PickedPdf? _picked;
  final _titleC = TextEditingController();
  final _clientC = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleC.dispose();
    _clientC.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await FileService.pickPdf();
    if (picked != null) {
      setState(() {
        _picked = picked;
        if (_titleC.text.isEmpty) {
          _titleC.text = picked.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        }
      });
    }
  }

  Future<void> _analyze() async {
    if (_picked == null) {
      AppSnackbar.error(context, 'Pick a PDF first.');
      return;
    }
    if (_titleC.text.trim().isEmpty || _clientC.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Add a contract title and client name.');
      return;
    }

    setState(() => _busy = true);
    try {
      final notifier = ref.read(contractProvider.notifier);
      final created = await notifier.createContract({
        'title': _titleC.text.trim(),
        'client_name': _clientC.text.trim(),
        'value': 0,
        'currency': 'USD',
        'status': ContractStatus.draft,
      });
      if (created == null) {
        if (!mounted) return;
        AppSnackbar.error(context, 'Could not create contract.');
        return;
      }
      final updated = await notifier.uploadPdf(created.id, _picked!.file);
      if (updated == null) {
        if (!mounted) return;
        AppSnackbar.error(context, 'Could not upload the PDF.');
        return;
      }
      final analysis = await notifier.analyzeContract(pdfUrl: updated.pdfUrl);
      if (!mounted) return;
      if (analysis == null) {
        AppSnackbar.error(context, 'Analysis unavailable. Try again later.');
        context.go('/contracts/${updated.id}');
        return;
      }
      context.go(
        '/contracts/${updated.id}/analysis',
        extra: {
          'risk_level': analysis.riskLevel,
          'summary': analysis.summary,
          'risky_clauses': analysis.riskyClauses
              .map((c) => {
                    'clause': c.clause,
                    'risk': c.risk,
                    'severity': c.severity,
                  })
              .toList(),
          'missing_sections': analysis.missingSections,
          'recommendations': analysis.recommendations,
          'freelancer_protection_score': analysis.freelancerProtectionScore,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          : context.go('/contracts'),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const Gap(AppSpacing.xs),
                    Text('Upload & Analyze', style: AppTextStyles.heading),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Upload a PDF to extract risks, missing clauses and recommendations.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const Gap(AppSpacing.xl),
                    GestureDetector(
                      onTap: _pick,
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.huge),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 56,
                              color: AppColors.brandAccent,
                            ),
                            const Gap(AppSpacing.lg),
                            Text(
                              _picked == null
                                  ? 'Tap to upload a PDF'
                                  : _picked!.name,
                              style: AppTextStyles.subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(AppSpacing.xs),
                            Text(
                              _picked == null
                                  ? 'Max 25 MB · .pdf'
                                  : _picked!.sizeReadable,
                              style: AppTextStyles.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.xl),
                    Text('Contract details', style: AppTextStyles.title),
                    const Gap(AppSpacing.md),
                    GlassCard(
                      child: Column(
                        children: [
                          _MiniField(controller: _titleC, label: 'Title'),
                          const Gap(AppSpacing.md),
                          _MiniField(controller: _clientC, label: 'Client Name'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: PrimaryButton(
                    label: 'Analyze with AI',
                    icon: Icons.auto_awesome,
                    isLoading: _busy,
                    onPressed: _busy ? null : _analyze,
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

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _MiniField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const Gap(AppSpacing.xs),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.brandPrimary.withValues(alpha: 0.45),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.glassBorder),
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
