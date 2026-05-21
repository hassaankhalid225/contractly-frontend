import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Shared multi-stop gradient background used as the canvas for every screen.
/// Adds two subtle accent glows to give depth.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showAccentGlow;

  const AppBackground({
    super.key,
    required this.child,
    this.showAccentGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandPrimary,
            Color(0xFF111A2E),
            AppColors.brandPrimary,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          if (showAccentGlow) ...[
            Positioned(
              top: -120,
              right: -80,
              child: _glow(AppColors.brandAccent.withValues(alpha: 0.18), 260),
            ),
            Positioned(
              top: 220,
              left: -100,
              child: _glow(AppColors.brandCard.withValues(alpha: 0.55), 320),
            ),
          ],
          child,
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}
