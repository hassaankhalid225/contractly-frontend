import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Frosted-glass card used everywhere for the iPhone-style theme.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double opacity;
  final Color? overrideColor;
  final Color? borderColor;
  final double sigma;
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.opacity = 0.6,
    this.overrideColor,
    this.borderColor,
    this.sigma = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final inner = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: (overrideColor ?? AppColors.glassFill).withValues(alpha: opacity),
            borderRadius: radius,
            border: showBorder
                ? Border.all(color: borderColor ?? AppColors.glassBorder)
                : null,
          ),
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );

    final wrapped = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: inner,
            ),
          )
        : inner;

    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}
