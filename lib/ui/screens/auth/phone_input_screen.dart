import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  String _completePhone = '';
  bool _valid = false;

  Future<void> _send() async {
    if (!_valid) {
      AppSnackbar.error(context, 'Please enter a valid phone number.');
      return;
    }
    final ok = await ref.read(authProvider.notifier).sendOtp(_completePhone);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.info(context, 'OTP sent to $_completePhone');
      context.push(
        '/auth/otp?phone=${Uri.encodeQueryComponent(_completePhone)}',
      );
    } else {
      final err = ref.read(authProvider).error;
      AppSnackbar.error(context,
          err?.friendlyMessage ?? 'Could not send the OTP. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Gap(AppSpacing.lg),
                Text('Enter your phone number',
                    style: AppTextStyles.headingLarge),
                const Gap(AppSpacing.sm),
                Text(
                  "We'll text you a 6-digit verification code.",
                  style: AppTextStyles.bodySecondary,
                ),
                const Gap(AppSpacing.xxxl),
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.brandAccent,
                          ),
                    ),
                    child: IntlPhoneField(
                      style: AppTextStyles.body,
                      dropdownTextStyle: AppTextStyles.body,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Phone',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        counterText: '',
                      ),
                      initialCountryCode: 'PK',
                      pickerDialogStyle: PickerDialogStyle(
                        backgroundColor: AppColors.brandSurface,
                        countryNameStyle:
                            const TextStyle(color: AppColors.textPrimary),
                        countryCodeStyle:
                            const TextStyle(color: AppColors.textSecondary),
                        searchFieldInputDecoration: const InputDecoration(
                          hintText: 'Search country',
                          hintStyle:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      onChanged: (phone) {
                        _completePhone = phone.completeNumber;
                        _valid = phone.isValidNumber();
                        setState(() {});
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                ),
                const Gap(AppSpacing.lg),
                Text(
                  'Test numbers (always work with OTP 123456): +923001234567 / +923009876543',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Send OTP',
                  icon: Icons.send_rounded,
                  isLoading: auth.isLoading,
                  onPressed:
                      _valid && !auth.isLoading ? _send : null,
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
