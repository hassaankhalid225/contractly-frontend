import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/contract_provider.dart';
import '../../components/error_snackbar.dart';
import '../../components/primary_button.dart';
import '../../components/secondary_button.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  final String contractId;
  const SignatureScreen({super.key, required this.contractId});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  late final SignatureController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_controller.isEmpty) {
      AppSnackbar.error(context, 'Please draw your signature first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await _controller.toPngBytes(
        height: 400,
        width: 800,
      );
      if (bytes == null) {
        if (mounted) {
          AppSnackbar.error(context, 'Could not capture signature.');
        }
        return;
      }
      final updated = await ref
          .read(contractProvider.notifier)
          .signContract(widget.contractId, bytes);
      if (!mounted) return;
      if (updated == null) {
        AppSnackbar.error(
          context,
          ref.read(contractProvider).error?.friendlyMessage ??
              'Could not save signature.',
        );
        return;
      }
      await _showSuccess();
      if (!mounted) return;
      context.go('/contracts/${widget.contractId}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSuccess() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Dialog(
          backgroundColor: AppColors.brandSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 60),
                const Gap(AppSpacing.lg),
                Text('Signed!', style: AppTextStyles.title),
                const Gap(AppSpacing.xs),
                Text(
                  'Your signature is attached to the contract.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Sign Contract',
            style: TextStyle(color: Colors.black)),
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/contracts/${widget.contractId}'),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.clear(),
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Draw your signature below.',
                style: AppTextStyles.bodySecondary
                    .copyWith(color: Colors.black54),
              ),
            ),
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  children: [
                    Signature(
                      controller: _controller,
                      backgroundColor: Colors.white,
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Text(
                        'X',
                        style: AppTextStyles.subtitle
                            .copyWith(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Clear',
                      icon: Icons.delete_outline,
                      borderColor: Colors.black26,
                      textColor: Colors.black87,
                      onPressed: () => _controller.clear(),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Confirm',
                      icon: Icons.check_rounded,
                      isLoading: _busy,
                      onPressed: _busy ? null : _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
