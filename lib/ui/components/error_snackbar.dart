import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final scaffold = ScaffoldMessenger.maybeOf(context);
    if (scaffold == null) return;
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        duration: duration,
        action: action,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const Gap(8),
            Expanded(
              child: Text(
                message,
                style:
                    AppTextStyles.body.copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void info(BuildContext context, String message) =>
      show(context, message, isError: false);

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);
}
