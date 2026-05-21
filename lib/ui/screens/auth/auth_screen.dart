import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../components/app_background.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';
import '../../components/secondary_button.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!context.mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        AppSnackbar.error(context, error.friendlyMessage);
      }
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.error(context, 'Could not open the link.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const Gap(AppSpacing.giant),
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandAccent,
                        AppColors.brandAccentSoft
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.description_rounded,
                      size: 40, color: Colors.white),
                ),
                const Gap(AppSpacing.xl),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  AppConstants.tagline,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        'Welcome',
                        style: AppTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        'Sign in to access your contracts and payments.',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppSpacing.xl),
                      PrimaryButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata_rounded,
                        isLoading: auth.isLoading,
                        color: Colors.white,
                        textColor: AppColors.brandPrimary,
                        onPressed: auth.isLoading
                            ? null
                            : () => _signInWithGoogle(context, ref),
                      ),
                      const Gap(AppSpacing.md),
                      SecondaryButton(
                        label: 'Continue with Phone',
                        icon: Icons.phone_iphone_rounded,
                        onPressed: auth.isLoading
                            ? null
                            : () => context.push('/auth/phone'),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.lg),
                _LegalRow(onLinkTap: (u) => _openLink(context, u)),
                const Gap(AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final ValueChanged<String> onLinkTap;
  const _LegalRow({required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.caption;
    final link = base.copyWith(
      color: AppColors.brandAccent,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('By continuing you agree to our ', style: base),
          GestureDetector(
            onTap: () => onLinkTap(AppConstants.termsUrl),
            child: Text('Terms', style: link),
          ),
          Text(' and ', style: base),
          GestureDetector(
            onTap: () => onLinkTap(AppConstants.privacyPolicyUrl),
            child: Text('Privacy Policy', style: link),
          ),
          Text('.', style: base),
        ],
      ),
    );
  }
}
