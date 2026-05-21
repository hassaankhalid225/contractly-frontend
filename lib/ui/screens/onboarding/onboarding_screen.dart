import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../components/app_background.dart';
import '../../components/glass_card.dart';
import '../../components/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.auto_awesome,
      title: 'Create Contracts in Seconds',
      message:
          'AI generates professional, fair contracts for any freelance work — no legal headaches required.',
    ),
    _Slide(
      icon: Icons.notifications_active_rounded,
      title: 'Never Miss a Deadline',
      message:
          'Smart reminders for expiry, payments and milestones keep you ahead, automatically.',
    ),
    _Slide(
      icon: Icons.draw_rounded,
      title: 'Sign & Share Instantly',
      message:
          'Built-in e-signature, PDF analysis and cloud storage. No extra apps, ever.',
    ),
  ];

  Future<void> _finish() async {
    await StorageService.writePref(AppConstants.prefOnboardingSeen, true);
    if (!mounted) return;
    context.go('/auth');
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
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
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.brandAccent
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: PrimaryButton(
                  label:
                      _index == _slides.length - 1 ? 'Get Started' : 'Continue',
                  onPressed: _next,
                  icon: _index == _slides.length - 1
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String message;
  const _Slide({
    required this.icon,
    required this.title,
    required this.message,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.huge),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandAccent, AppColors.brandAccentSoft],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(slide.icon, size: 60, color: Colors.white),
            ),
          ),
          const Gap(AppSpacing.huge),
          Text(slide.title,
              style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
          const Gap(AppSpacing.md),
          Text(
            slide.message,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
