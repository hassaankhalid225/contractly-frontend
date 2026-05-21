import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title)),
          if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: AppColors.brandAccent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
