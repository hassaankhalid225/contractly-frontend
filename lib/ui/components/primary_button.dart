import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final Color? color;
  final Color? textColor;
  final EdgeInsets? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.color,
    this.textColor,
    this.padding,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final bg = widget.color ?? AppColors.brandAccent;
    final fg = widget.textColor ?? Colors.white;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1,
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => _setPressed(true),
          onTapUp: isDisabled ? null : (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: isDisabled ? null : widget.onPressed,
          child: Container(
            height: widget.height,
            width: double.infinity,
            padding:
                widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
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
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: AppTextStyles.button.copyWith(color: fg),
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
