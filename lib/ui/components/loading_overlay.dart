import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class LoadingOverlay extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  const LoadingOverlay({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 96,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: AppColors.brandSurface,
        highlightColor: AppColors.brandCard.withValues(alpha: 0.8),
        period: const Duration(milliseconds: 1300),
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const Gap(AppSpacing.md),
          itemBuilder: (_, __) => Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: AppColors.brandSurface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;
  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator.adaptive(),
          ),
          if (message != null) ...[
            const Gap(AppSpacing.md),
            Text(
              message!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
