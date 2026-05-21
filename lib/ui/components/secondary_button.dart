import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? borderColor;
  final Color? textColor;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.borderColor,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final fg = textColor ?? AppColors.textPrimary;
    final border = borderColor ?? AppColors.textSecondary.withValues(alpha: 0.4);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: border, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            foregroundColor: fg,
            backgroundColor: Colors.white.withValues(alpha: 0.02),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(label, style: AppTextStyles.button.copyWith(color: fg)),
                  ],
                ),
        ),
      ),
    );
  }
}
