import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../components/app_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    Future<void>.delayed(const Duration(milliseconds: 1500), _decideRoute);
  }

  Future<void> _decideRoute() async {
    if (!mounted) return;
    await ref.read(authProvider.notifier).initialize();

    if (!mounted) return;
    final auth = ref.read(authProvider);
    final onboardingSeen =
        StorageService.readPref<bool>(AppConstants.prefOnboardingSeen) ?? false;

    if (auth.isAuthenticated) {
      context.go('/home');
    } else if (!onboardingSeen) {
      context.go('/onboarding');
    } else {
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: AppBackground(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LogoMark(),
                  const Gap(AppSpacing.xl),
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 30),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    AppConstants.tagline,
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(AppSpacing.xxxl),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandAccent, AppColors.brandAccentSoft],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.description_rounded, size: 50, color: Colors.white),
          Positioned(
            right: 18,
            bottom: 20,
            child: Icon(
              Icons.check_circle,
              size: 26,
              color: AppColors.brandGold,
            ),
          ),
        ],
      ),
    );
  }
}
