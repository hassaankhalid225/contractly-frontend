import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 60;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focus.requestFocus(),
    );
  }

  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  Future<void> _resend() async {
    final ok = await ref.read(authProvider.notifier).sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.info(context, 'New OTP sent.');
      _startTimer();
    } else {
      AppSnackbar.error(
        context,
        ref.read(authProvider).error?.friendlyMessage ?? 'Could not resend.',
      );
    }
  }

  Future<void> _verify(String otp) async {
    setState(() => _inlineError = null);
    final ok = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.phone, otp);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      final err = ref.read(authProvider).error;
      setState(() {
        _inlineError = err?.friendlyMessage ?? 'Invalid OTP. Please try again.';
      });
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final defaultPin = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTextStyles.title.copyWith(fontSize: 22),
      decoration: BoxDecoration(
        color: AppColors.brandCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
    );
    final focusedPin = defaultPin.copyWith(
      decoration: BoxDecoration(
        color: AppColors.brandCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandAccent, width: 1.4),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(AppSpacing.md),
                Row(children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                  ),
                ]),
                const Gap(AppSpacing.lg),
                Text('Enter the 6-digit code',
                    style: AppTextStyles.headingLarge),
                const Gap(AppSpacing.sm),
                Text(
                  'We sent it to ${widget.phone}.',
                  style: AppTextStyles.bodySecondary,
                ),
                const Gap(AppSpacing.xxxl),
                GlassCard(
                  child: Center(
                    child: Pinput(
                      length: 6,
                      controller: _controller,
                      focusNode: _focus,
                      defaultPinTheme: defaultPin,
                      focusedPinTheme: focusedPin,
                      separatorBuilder: (_) => const SizedBox(width: 6),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onCompleted: _verify,
                      onChanged: (_) {
                        if (_inlineError != null) {
                          setState(() => _inlineError = null);
                        }
                      },
                    ),
                  ),
                ),
                if (_inlineError != null) ...[
                  const Gap(AppSpacing.md),
                  Text(
                    _inlineError!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ],
                const Gap(AppSpacing.xl),
                Center(
                  child: _seconds > 0
                      ? Text(
                          'Resend in $_seconds s',
                          style: AppTextStyles.caption,
                        )
                      : TextButton(
                          onPressed: auth.isLoading ? null : _resend,
                          child: Text(
                            'Resend OTP',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.brandAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Verify',
                  icon: Icons.check_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _controller.text.length == 6 && !auth.isLoading
                      ? () => _verify(_controller.text)
                      : null,
                ),
                const Gap(AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
